/* This file is part of the hkl library.
 *
 * The hkl library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The hkl library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the hkl library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright (C) 2003-2017 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 *          Maria-Teresa Nunez-Pardo-de-Verra <tnunez@mail.desy.de>
 */
#include <gsl/gsl_errno.h>              // for ::GSL_SUCCESS, etc
#include <gsl/gsl_multiroots.h>
#include <gsl/gsl_sf_trig.h>            // for gsl_sf_angle_restrict_pos
#include <gsl/gsl_vector_double.h>      // for gsl_vector, etc
#include <math.h>                       // for fabs, M_PI
#include <stddef.h>                     // for size_t
#include <stdlib.h>                     // for free, malloc, rand, etc
#include <string.h>                     // for NULL
#include <sys/types.h>                  // for uint
#include "hkl-axis-private.h"           // for HklAxis
#include "hkl-detector-private.h"       // for hkl_detector_compute_kf
#include "hkl-geometry-private.h"       // for HklHolder, _HklGeometry, etc
#include "hkl-macros-private.h"         // for hkl_assert, HKL_MALLOC, etc
#include "hkl-matrix-private.h"         // for hkl_matrix_times_vector, etc
#include "hkl-parameter-private.h"      // for _HklParameter, etc
#include "hkl-pseudoaxis-auto-private.h"  // for CHECK_NAN, etc
#include "hkl-pseudoaxis-common-hkl-private.h"  // for HklEngineHkl
#include "hkl-pseudoaxis-common-q-private.h"  // for HklEngineHkl
#include "hkl-pseudoaxis-private.h"     // for _HklEngine, _HklMode, etc
#include "hkl-quaternion-private.h"     // for hkl_quaternion_init, etc
#include "hkl-sample-private.h"         // for _HklSample
#include "hkl-vector-private.h"         // for HklVector, etc
#include "hkl.h"                        // for HklEngine, HklGeometry, etc
#include "hkl/ccan/array_size/array_size.h"  // for ARRAY_SIZE
#include "hkl/ccan/container_of/container_of.h"  // for container_of
#include "hkl/ccan/darray/darray.h"     // for darray_item, darray_size

/* #define DEBUG */

/*******************************************/
/* common methode use by hkl getter/setter */
/*******************************************/

typedef struct _HklDetectorFit HklDetectorFit;

struct _HklDetectorFit
{
	HklGeometry *geometry;
	HklDetector *detector;
	HklVector *kf0;
	HklParameter **axes;
	size_t len;
};

/* this method is used to fit only the detector position */
/* usable with only 1 or 2 axes */
static int fit_detector_function(const gsl_vector *x, void *params, gsl_vector *f)
{
	size_t i;
	HklDetectorFit *fitp = params;
	HklVector kf;

	/* update the workspace from x; */
	for(i=0; i<fitp->len; ++i)
		hkl_parameter_value_set(fitp->axes[i],
					x->data[i],
					HKL_UNIT_DEFAULT, NULL);

	hkl_geometry_update(fitp->geometry);

	kf = hkl_geometry_kf_get(fitp->geometry, fitp->detector);

	f->data[0] = fabs(fitp->kf0->data[0] - kf.data[0])
		+ fabs(fitp->kf0->data[1] - kf.data[1])
		+ fabs(fitp->kf0->data[2] - kf.data[2]);
	if (fitp->len > 1)
		f->data[1] = fabs(fitp->kf0->data[1] - kf.data[1]);

#if 0
	fprintf(stdout, "\nkf0 [%f, %f, %f], kf [%f, %f, %f]",
		fitp->kf0->data[0], fitp->kf0->data[1], fitp->kf0->data[2],
		kf.data[0], kf.data[1], kf.data[2]);
	fprintf(stdout, " x : [");
	for(i=0; i<fitp->len; ++i)
		fprintf(stdout, " %.7f", x_data[i]);
	fprintf(stdout, "] |  f : [");
	for(i=0; i<fitp->len; ++i)
		fprintf(stdout, " %.7f", f_data[i]);
	fprintf(stdout, "]\n");
#endif
	return GSL_SUCCESS;
}


static int fit_detector_position(HklMode *mode,
				 HklGeometry *geometry,
				 HklDetector *detector,
				 const HklSample *sample,
				 HklVector *kf)
{
	const char **axis_name;
	HklDetectorFit params;
	gsl_multiroot_fsolver_type const *T;
	gsl_multiroot_fsolver *s;
	gsl_multiroot_function f;
	gsl_vector *x;
	int status;
	int res = FALSE;
	int iter;
	const HklHolder *sample_holder = hkl_geometry_sample_holder_get(geometry, sample);
	const HklHolder *detector_holder = hkl_geometry_detector_holder_get(geometry, detector);

	/* fit the detector part to find the position of the detector for a given kf */
	/* FIXME for now the sample and detector holder are respectively the first and the second one */
	/* we need to find the right axes to use for the fit */
	/* BECARFULL the sample part must not move during this fit. So exclude an axis */
	/* if it is also part of the sample holder. */
	/* For now compare the holder axes with the axes of the mode to generate the right gsl multiroot solver */
	params.geometry = geometry;
	params.detector = detector;
	params.kf0 = kf;
	params.axes = malloc(sizeof(*params.axes) * detector_holder->config->len);
	params.len = 0;
	/* for each axis of the mode */
	darray_foreach(axis_name, mode->info->axes_w){
		size_t k;
		size_t tmp;

		tmp = hkl_geometry_get_axis_idx_by_name(params.geometry, *axis_name);
		/* check that this axis is in the detector's holder */
		for(k=0; k<detector_holder->config->len; ++k)
			if(tmp == detector_holder->config->idx[k]){
				size_t j;
				int ko = 0;

				/* and not in the sample's holder */
				for(j=0; j<sample_holder->config->len; ++j){
					if (tmp == sample_holder->config->idx[j]){
						ko = 1;
						break;
					}
				}
				if(!ko)
					params.axes[params.len++] = darray_item(params.geometry->axes, tmp);
			}
	}

	/* if no detector axis found ???? abort */
	/* maybe put this at the begining of the method */
	if (params.len > 0){
		size_t i;

		/* now solve the system */
		/* Initialize method  */
		T = gsl_multiroot_fsolver_hybrid;
		s = gsl_multiroot_fsolver_alloc (T, params.len);
		x = gsl_vector_alloc(params.len);

		/* initialize x with the right values */
		for(i=0; i<params.len; ++i)
			x->data[i] = hkl_parameter_value_get(params.axes[i], HKL_UNIT_DEFAULT);

		f.f = fit_detector_function;
		f.n = params.len;
		f.params = &params;
		gsl_multiroot_fsolver_set (s, &f, x);

		/* iterate to find the solution */
		iter = 0;
		do {
			++iter;
			status = gsl_multiroot_fsolver_iterate(s);
			if (status || iter % 100 == 0) {
				/* Restart from another point. */
				for(i=0; i<params.len; ++i)
					x->data[i] = (double)rand() / RAND_MAX * 180. / M_PI;
				gsl_multiroot_fsolver_set(s, &f, x);
				gsl_multiroot_fsolver_iterate(s);
			}
			status = gsl_multiroot_test_residual (s->f, HKL_EPSILON);
		} while (status == GSL_CONTINUE && iter < 1000);

#ifdef DEBUG
		fprintf(stdout, "\n  fitting the detector position using thoses axes :");
		for(i=0; i<params.len; ++i)
			fprintf(stdout, " \"%s\"", ((HklParameter *)params.axes[i])->name);
		fprintf(stdout, " status : %d iter : %d", status, iter);
		fprintf(stdout, " x: [");
		for(i=0; i<params.len; ++i)
			fprintf(stdout, " %.7f", s->x->data[i]);
		fprintf(stdout, "] f: [");
		for(i=0; i<params.len; ++i)
			fprintf(stdout, " %.7f", s->f->data[i]);
		fprintf(stdout, "]\n");
		hkl_geometry_fprintf(stdout, params.geometry);
#endif
		if(status != GSL_CONTINUE){
			res = TRUE;
			/* put the axes in the -pi, pi range. */
			for(i=0; i<params.len; ++i){
				double value;

				value = hkl_parameter_value_get(params.axes[i], HKL_UNIT_DEFAULT);
				/* TODO one day deal with the error for real */
				hkl_parameter_value_set(params.axes[i],
							gsl_sf_angle_restrict_pos(value),
							HKL_UNIT_DEFAULT, NULL);
			}
		}
		/* release memory */
		gsl_vector_free(x);
		gsl_multiroot_fsolver_free(s);
	}
	free(params.axes);

	return res;
}

/* get the highest index of the axis in a holder */
/* BEWARE, NOT the axis index in the geometry->axes */
/* which is part of the axis_names of the mode */
/* return -1 if there is no axes of the mode in the sample part of the geometry */
static int get_last_sample_axis_idx(HklGeometry *geometry, const HklSample *sample,
				    const darray_string *axes)
{
	int last = -1;
	const char **axis_name;
	HklHolder *sample_holder = hkl_geometry_sample_holder_get(geometry, sample);

	darray_foreach(axis_name, *axes){
		size_t i;
		size_t idx;

		/* FIXME for now the sample holder is the first one */
		idx = hkl_geometry_get_axis_idx_by_name(geometry, *axis_name);
		for(i=0; i<sample_holder->config->len; ++i)
			if(idx == sample_holder->config->idx[i]){
				last = last > (int)i ? last : (int)i;
				break;
			}
	}
	return last;
}


int hkl_is_reachable(HklEngine *engine, double wavelength, GError **error)
{
	HklEngineHkl *engine_hkl = container_of(engine, HklEngineHkl, engine);
	HklVector Hkl = {
		.data = {
			engine_hkl->h->_value,
			engine_hkl->k->_value,
			engine_hkl->l->_value,
		},
	};

	hkl_matrix_times_vector(&engine->sample->UB, &Hkl);
	if (hkl_vector_norm2(&Hkl) > qmax(wavelength)){
		g_set_error(error,
			    HKL_ENGINE_ERROR,
			    HKL_ENGINE_ERROR_SET,
			    "unreachable hkl, try to change the wavelength");
		return FALSE;
	}

	return TRUE;
}

/**
 * _RUBh_minus_Q_func: (skip)
 * @x:
 * @params:
 * @f:
 *
 * Only usefull if you need to create a new hkl mode.
 *
 * Returns:
 **/
int _RUBh_minus_Q_func(const gsl_vector *x, void *params, gsl_vector *f)
{
	CHECK_NAN(x->data, x->size);

	return RUBh_minus_Q(x->data, params, f->data);
}

/**
 * RUBh_minus_Q: (skip)
 * @x:
 * @params:
 * @f:
 *
 *
 *
 * Returns:
 **/
int RUBh_minus_Q(double const x[], void *params, double f[])
{
	HklEngine *engine = params;
	HklEngineHkl *engine_hkl = container_of(engine, HklEngineHkl, engine);
	HklVector Hkl = {
		.data = {
			engine_hkl->h->_value,
			engine_hkl->k->_value,
			engine_hkl->l->_value,
		},
	};
	HklVector ki, dQ;
	HklHolder *sample_holder = hkl_geometry_sample_holder_get(engine->geometry,
								  engine->sample);

	/* update the workspace from x; */
	set_geometry_axes(engine, x);

	/* R * UB * h = Q */
	/* for now the 0 holder is the sample holder. */
	hkl_matrix_times_vector(&engine->sample->UB, &Hkl);
	/* Hkl = hkl_holder_transformation_apply(sample_holder, &Hkl); */
	hkl_vector_rotated_quaternion(&Hkl, &sample_holder->q);

	/* kf - ki = Q */
	ki = hkl_geometry_ki_get(engine->geometry);
	dQ = hkl_geometry_kf_get(engine->geometry, engine->detector);
	hkl_vector_minus_vector(&dQ, &ki);

	hkl_vector_minus_vector(&dQ, &Hkl);

	f[0] = dQ.data[0];
	f[1] = dQ.data[1];
	f[2] = dQ.data[2];

	return GSL_SUCCESS;
}

int hkl_mode_get_hkl_real(HklMode *self,
			  HklEngine *engine,
			  HklGeometry *geometry,
			  HklDetector *detector,
			  HklSample *sample,
			  GError **error)
{
	HklMatrix RUB;
	HklVector hkl, ki, Q;
	HklEngineHkl *engine_hkl = container_of(engine, HklEngineHkl, engine);
	HklHolder *sample_holder = hkl_geometry_sample_holder_get(geometry, sample);

	/* update the geometry internals */
	hkl_geometry_update(geometry);

	/* R * UB */
	hkl_quaternion_to_matrix(&sample_holder->q, &RUB);
	hkl_matrix_times_matrix(&RUB, &sample->UB);

	/* kf - ki = Q */
	ki = hkl_geometry_ki_get(geometry);

	Q  = hkl_geometry_kf_get(geometry, detector);
	hkl_vector_minus_vector(&Q, &ki);

	hkl_matrix_solve(&RUB, &hkl, &Q);

	engine_hkl->h->_value = hkl.data[0];
	engine_hkl->k->_value = hkl.data[1];
	engine_hkl->l->_value = hkl.data[2];

	return TRUE;
}

int hkl_mode_set_hkl_real(HklMode *self,
			  HklEngine *engine,
			  HklGeometry *geometry,
			  HklDetector *detector,
			  HklSample *sample,
			  GError **error)
{
	int last_axis;

	hkl_error (error == NULL || *error == NULL);

	/* check the input parameters */
	if(!hkl_is_reachable(engine, geometry->source.wave_length,
			     error)){
		hkl_assert(error == NULL || *error != NULL);
		return FALSE;
	}
	hkl_assert(error == NULL || *error == NULL);

	/* compute the mode */
	if(!hkl_mode_auto_set_real(self, engine,
				   geometry, detector, sample,
				   error)){
		hkl_assert(error == NULL || *error != NULL);
		//fprintf(stdout, "message :%s\n", (*error)->message);
		return FALSE;
	}
	hkl_assert(error == NULL || *error == NULL);

	/* check that the mode allow to move a sample axis */
	/* FIXME for now the sample holder is the first one */
	last_axis = get_last_sample_axis_idx(geometry, sample, &self->info->axes_w);
	if(last_axis >= 0){
		uint i;
		const HklGeometryListItem *item;
		uint len = engine->engines->geometries->n_items;

		/* For each solution already found we will generate another one */
		/* using the Ewalds construction by rotating Q around the last sample */
		/* axis of the mode until it intersect again the Ewald sphere. */
		/* FIXME do not work if ki is colinear with the axis. */

		/* for this we needs : */
		/* - the coordinates of the end of the Q vector (q) */
		/* - the last sample axis orientation of the mode (axis_v) */
		/* - the coordinates of the center of the ewalds sphere (c) */
		/* - the coordinates of the center of rotation of the sample (o = 0, 0, 0) */

		/* then we can : */
		/* - project the origin in plane of normal axis_v containing q (o') */
		/* - project the center of the ewalds sphere into the same plan (c') */
		/* - rotate q around this (o', c') line of 180° to find the (q2) solution */
		/* - compute the (kf2) corresponding to this q2 solution */
		/* at the end we just need to solve numerically the position of the detector */

		/* we will add solution to the geometries so save its length before */
		for(i=0, item=list_top(&engine->engines->geometries->items, HklGeometryListItem, list);
		    i<len;
		    ++i, item=list_next(&engine->engines->geometries->items, item, list)){
			int j;
			HklVector ki;
			HklVector kf2;
			HklVector q;
			HklVector axis_v;
			HklQuaternion qr;
			HklAxis *axis;
			HklVector cp = {{0}};
			HklVector op = {{0}};
			double angle;
			HklGeometry *geom = hkl_geometry_new_copy(item->geometry);
			HklHolder *sample_holder = hkl_geometry_sample_holder_get(geom, sample);

			geom = hkl_geometry_new_copy(item->geometry);

			/* get the Q vector kf - ki */
			ki = hkl_geometry_ki_get(geom);
			q = hkl_geometry_kf_get(geom, detector);
			hkl_vector_minus_vector(&q, &ki);

			/* compute the current orientation of the last axis */
			axis = container_of(darray_item(geom->axes,
							sample_holder->config->idx[last_axis]),
					    HklAxis, parameter);
			axis_v = axis->axis_v;
			hkl_quaternion_init(&qr, 1, 0, 0, 0);
			for(j=0; j<last_axis; ++j)
				hkl_quaternion_times_quaternion(
					&qr,
					&container_of(darray_item(geom->axes,
								  sample_holder->config->idx[j]),
						      HklAxis, parameter)->q);
			hkl_vector_rotated_quaternion(&axis_v, &qr);

			/* - project the center of the ewalds sphere into the same plan (c') */
			hkl_vector_minus_vector(&cp, &ki);
			hkl_vector_project_on_plan_with_point(&cp, &axis_v, &q);
			hkl_vector_project_on_plan_with_point(&op, &axis_v, &q);

			/* - rotate q around this (o', c') line of 180° to find the (q2) solution */
			kf2 = q;
			hkl_vector_rotated_around_line(&kf2, M_PI, &cp, &op);
			angle = hkl_vector_oriented_angle_points(&q, &op, &kf2, &axis_v);
			/* TODO parameter list for geometry */
			if(!hkl_parameter_value_set(&axis->parameter,
						    hkl_parameter_value_get(&axis->parameter, HKL_UNIT_DEFAULT) + angle,
						    HKL_UNIT_DEFAULT, error))
				return FALSE;
			hkl_geometry_update(geom);
#ifdef DEBUG
			fprintf(stdout, "\n- try to add a solution by rotating Q <%f, %f, %f> around the \"%s\" axis <%f, %f, %f> of %f radian",
				q.data[0], q.data[1], q.data[2],
				((HklParameter *)axis)->name,
				axis_v.data[0], axis_v.data[1], axis_v.data[2],
				angle);
			fprintf(stdout, "\n   op: <%f, %f, %f>", op.data[0], op.data[1], op.data[2]);
			fprintf(stdout, "\n   q2: <%f, %f, %f>", kf2.data[0], kf2.data[1], kf2.data[2]);
#endif
			hkl_vector_add_vector(&kf2, &ki);

			/* at the end we just need to solve numerically the position of the detector */
			if(fit_detector_position(self, geom, detector, sample, &kf2))
				hkl_geometry_list_add(engine->engines->geometries,
						      geom);

			hkl_geometry_free(geom);
		}
	}
	return TRUE;
}

/***************************************/
/* the double diffraction get set part */
/***************************************/

/**
 * double_diffraction: (skip)
 * @x:
 * @params:
 * @f:
 *
 *
 *
 * Returns:
 **/
int _double_diffraction(double const x[], void *params, double f[])
{
	HklEngine *engine = params;
	HklEngineHkl *engine_hkl = container_of(engine, HklEngineHkl, engine);
	HklVector hkl = {
		.data = {
			engine_hkl->h->_value,
			engine_hkl->k->_value,
			engine_hkl->l->_value,
		},
	};
	HklVector kf2;
	HklVector ki;
	HklVector dQ;
	HklHolder *sample_holder = hkl_geometry_sample_holder_get(engine->geometry,
								  engine->sample);

	/* update the workspace from x; */
	set_geometry_axes(engine, x);

	/* get the second hkl from the mode parameters */
	hkl_vector_init(&kf2,
			darray_item(engine->mode->parameters, 0)->_value,
			darray_item(engine->mode->parameters, 1)->_value,
			darray_item(engine->mode->parameters, 2)->_value);

	/* R * UB * hkl = Q */
	/* for now the 0 holder is the sample holder. */
	hkl_matrix_times_vector(&engine->sample->UB, &hkl);
	hkl_vector_rotated_quaternion(&hkl, &sample_holder->q);

	/* kf - ki = Q */
	ki = hkl_geometry_ki_get(engine->geometry);
	dQ = hkl_geometry_kf_get(engine->geometry, engine->detector);
	hkl_vector_minus_vector(&dQ, &ki);
	hkl_vector_minus_vector(&dQ, &hkl);

	/* R * UB * hlk2 = Q2 */
	hkl_matrix_times_vector(&engine->sample->UB, &kf2);
	hkl_vector_rotated_quaternion(&kf2, &sample_holder->q);
	hkl_vector_add_vector(&kf2, &ki);

	f[0] = dQ.data[0];
	f[1] = dQ.data[1];
	f[2] = dQ.data[2];
	f[3] = hkl_vector_norm2(&kf2) - hkl_vector_norm2(&ki);

	return GSL_SUCCESS;
}

/**
 * double_diffraction_func: (skip)
 * @x:
 * @params:
 * @f:
 *
 *
 *
 * Returns:
 **/
int _double_diffraction_func(gsl_vector const *x, void *params, gsl_vector *f)
{
	CHECK_NAN(x->data, x->size);

	_double_diffraction(x->data, params, f->data);

	return  GSL_SUCCESS;
}


/******************************************/
/* the psi_constant_vertical get set part */
/******************************************/

/**
 * psi_constant_vertical_func: (skip)
 * @x:
 * @params:
 * @f:
 *
 *
 *
 * Returns:
 **/
int _psi_constant_vertical_func(gsl_vector const *x, void *params, gsl_vector *f)
{
	HklVector ki, kf, Q;
	HklEngine *engine = params;

	CHECK_NAN(x->data, x->size);

	RUBh_minus_Q(x->data, params, f->data);

	/* update the workspace from x; */
	set_geometry_axes(engine, x->data);

	/* kf - ki = Q */
	ki = hkl_geometry_ki_get(engine->geometry);
	kf = hkl_geometry_kf_get(engine->geometry, engine->detector);
	Q = kf;
	hkl_vector_minus_vector(&Q, &ki);

	f->data[3] = darray_item(engine->mode->parameters, 3)->_value;

	/* if |Q| > epsilon ok */
	if(hkl_vector_normalize(&Q)){
		HklVector hkl;
		HklVector n;
		HklHolder *sample_holder = hkl_geometry_sample_holder_get(engine->geometry,
									  engine->sample);

		/* compute n the intersection of the plan P(kf, ki) and PQ (normal Q) */
		n = kf;
		hkl_vector_vectorial_product(&n, &ki);
		hkl_vector_vectorial_product(&n, &Q);

		/* compute the hkl ref position in the laboratory */
		/* referentiel. The geometry was already updated. */
		hkl.data[0] = darray_item(engine->mode->parameters, 0)->_value;
		hkl.data[1] = darray_item(engine->mode->parameters, 1)->_value;
		hkl.data[2] = darray_item(engine->mode->parameters, 2)->_value;
		hkl_matrix_times_vector(&engine->sample->UB, &hkl);
		hkl_vector_rotated_quaternion(&hkl, &sample_holder->q);

		/* project hkl on the plan of normal Q */
		hkl_vector_project_on_plan(&hkl, &Q);
#ifdef DEBUG
		fprintf(stdout, "\n");
		hkl_geometry_fprintf(stdout, engine->geometry);
		fprintf(stdout, "\n");
		fprintf(stdout, "%s n : <%f, %f, %f> hkl : <%f, %f, %f> Q : <%f, %f, %f> angle : %f\n",
			__func__,
			n.data[0], n.data[1], n.data[2],
			hkl.data[0], hkl.data[1], hkl.data[2],
			Q.data[0], Q.data[1], Q.data[2],
			hkl_vector_oriented_angle(&n, &hkl, &Q) * HKL_RADTODEG);
#endif
		if(hkl_vector_norm2(&hkl) > HKL_EPSILON)
			f->data[3] -=  hkl_vector_oriented_angle(&n, &hkl, &Q);
	}

	return  GSL_SUCCESS;
}

#define HKL_MODE_PSI_CONSTANT_VERTICAL_ERROR hkl_mode_psi_constant_vertical_error_quark ()

static GQuark hkl_mode_psi_constant_vertical_error_quark (void)
{
	return g_quark_from_static_string ("hkl-mode-psi-constant-vertical-error-quark");
}

typedef enum {
	HKL_MODE_PSI_CONSTANT_VERTICAL_ERROR_INITIALIZED_SET, /* can not init the engine */
} HklModePsiConstantVerticalError;

int hkl_mode_initialized_set_psi_constant_vertical_real(HklMode *self,
							HklEngine *engine,
							HklGeometry *geometry,
							HklDetector *detector,
							HklSample *sample,
							int initialized,
							GError **error)
{
	HklVector hkl;
	HklVector ki, kf, Q, n;

	if(initialized){
		/* kf - ki = Q */
		ki = hkl_geometry_ki_get(geometry);
		kf = hkl_geometry_kf_get(geometry, detector);
		Q = kf;
		hkl_vector_minus_vector(&Q, &ki);

		if (hkl_vector_is_null(&Q)){
			g_set_error(error,
				    HKL_MODE_PSI_CONSTANT_VERTICAL_ERROR,
				    HKL_MODE_PSI_CONSTANT_VERTICAL_ERROR_INITIALIZED_SET,
				    "can not initialize the \"%s\" mode with a null hkl (kf == ki)"
				    "\nplease select a non-null hkl", self->info->name);
			return FALSE;
		}else{
			const HklHolder *sample_holder = hkl_geometry_sample_holder_get(geometry, sample);

			/* needed for a problem of precision */
			hkl_vector_normalize(&Q);

			/* compute the intersection of the plan P(kf, ki) and PQ (normal Q) */
			n = kf;
			hkl_vector_vectorial_product(&n, &ki);
			hkl_vector_vectorial_product(&n, &Q);

			/* compute hkl in the laboratory referentiel */
			/* the geometry was already updated in the detector compute kf */
			hkl.data[0] = darray_item(self->parameters, 0)->_value;
			hkl.data[1] = darray_item(self->parameters, 1)->_value;
			hkl.data[2] = darray_item(self->parameters, 2)->_value;
			hkl_matrix_times_vector(&sample->UB, &hkl);
			hkl_vector_rotated_quaternion(&hkl, &sample_holder->q);

			/* project hkl on the plan of normal Q */
			hkl_vector_project_on_plan(&hkl, &Q);

			if (hkl_vector_is_null(&hkl)){
				g_set_error(error,
					    HKL_MODE_PSI_CONSTANT_VERTICAL_ERROR,
					    HKL_MODE_PSI_CONSTANT_VERTICAL_ERROR_INITIALIZED_SET,
					    "can not initialize the \"%s\" mode"
					    "\nwhen Q and the <h2, k2, l2> ref vector are colinear."
					    "\nplease change one or both of them", engine->mode->info->name);
				return FALSE;
			}else{
				/* compute the angle beetween hkl and n and
				 * store in in the fourth parameter */
				if (!hkl_parameter_value_set(darray_item(self->parameters, 3),
							     hkl_vector_oriented_angle(&n, &hkl, &Q),
							     HKL_UNIT_DEFAULT, error))
					return FALSE;
			}
		}
	}

	self->initialized = initialized;

	return TRUE;
}

/*******************/
/* emergence fixed */
/*******************/

typedef struct _HklModeAutoHklEmergenceFixed HklModeAutoHklEmergenceFixed;

struct _HklModeAutoHklEmergenceFixed
{
	HklMode parent;
	HklParameter *n_x; /* not owned */
	HklParameter *n_y; /* not owned */
	HklParameter *n_z; /* not owned */
	HklParameter *emergence; /* not owned */
};

#define HKL_MODE_HKL_EMERGENCE_FIXED_ERROR hkl_mode_hkl_emergence_fixed_error_quark ()

static GQuark hkl_mode_hkl_emergence_fixed_error_quark (void)
{
	return g_quark_from_static_string ("hkl-mode-hkl-emergence-fixed-error-quark");
}

typedef enum {
	HKL_MODE_HKL_EMERGENCE_FIXED_ERROR_INITIALIZED_SET, /* can not init the engine */
	HKL_MODE_HKL_EMERGENCE_FIXED_ERROR_SET, /* can not set the engine */
} HklModeAutoHklEmergenceFixedError;


static HklVector surface(const HklModeAutoHklEmergenceFixed *mode){
	HklVector n = {
		.data = {
			mode->n_x->_value,
			mode->n_y->_value,
			mode->n_z->_value,
		}
	};
	return n;
}

static double expected_emergence(const HklModeAutoHklEmergenceFixed *mode){
	return mode->emergence->_value;
}

static int hkl_mode_hkl_emergence_fixed_initialized_set_real(HklMode *self,
							     HklEngine *engine,
							     HklGeometry *geometry,
							     HklDetector *detector,
							     HklSample *sample,
							     int initialized,
							     GError **error)
{
	const HklModeAutoHklEmergenceFixed *mode = container_of(self, HklModeAutoHklEmergenceFixed, parent);
	HklVector kf;
	HklVector n = surface(mode);
	const HklHolder *sample_holder = hkl_geometry_sample_holder_get(geometry, sample);

	/* first check the parameters */
	if (hkl_vector_is_null(&n)){
		g_set_error(error,
			    HKL_MODE_HKL_EMERGENCE_FIXED_ERROR,
			    HKL_MODE_HKL_EMERGENCE_FIXED_ERROR_INITIALIZED_SET,
			    "Can not compute emergence fixed when the surface vector is null.");
		return FALSE;
	}

	/* compute the orientation of the surface */
	hkl_vector_rotated_quaternion(&n, &sample_holder->q);

	kf = hkl_geometry_kf_get(geometry, detector);

	/* compute emergence and keep it */
	mode->emergence->_value = _emergence(&n, &kf);

	self->initialized = initialized;

	return TRUE;
}


int _emergence_fixed_func(const gsl_vector *x, void *params, gsl_vector *f)
{
	HklEngine *engine = params;
	HklModeAutoHklEmergenceFixed *mode = container_of(engine->mode,
							  HklModeAutoHklEmergenceFixed,
							  parent);
	HklGeometry *geometry = engine->geometry;
	const HklDetector *detector = engine->detector;
	const HklSample *sample = engine->sample;
	HklVector n = surface(mode);
	HklVector kf;
	const HklHolder *sample_holder = hkl_geometry_sample_holder_get(geometry, sample);

	CHECK_NAN(x->data, x->size);

	RUBh_minus_Q(x->data, params, f->data);

	/* compute the orientation of the surface */
	hkl_vector_rotated_quaternion(&n, &sample_holder->q);
	kf = hkl_geometry_kf_get(geometry, detector);

	f->data[3] = expected_emergence(mode) - _emergence(&n, &kf);

	return  GSL_SUCCESS;
}

int hkl_mode_hkl_emergence_fixed_set_real(HklMode *self,
					  HklEngine *engine,
					  HklGeometry *geometry,
					  HklDetector *detector,
					  HklSample *sample,
					  GError **error)
{
	const HklModeAutoHklEmergenceFixed *mode = container_of(self, HklModeAutoHklEmergenceFixed, parent);
	HklVector n = surface(mode);

	/* first check the parameters */
	if (hkl_vector_is_null(&n)){
		g_set_error(error,
			    HKL_MODE_HKL_EMERGENCE_FIXED_ERROR,
			    HKL_MODE_HKL_EMERGENCE_FIXED_ERROR_SET,
			    "Can not compute hkl with emergence fixed when the surface vector is null.");
		return FALSE;
	}

	return hkl_mode_set_hkl_real(self, engine, geometry, detector, sample, error);
}

HklMode *hkl_mode_hkl_emergence_fixed_new(const HklModeAutoInfo *auto_info)
{
	static const HklModeOperations operations = {
		HKL_MODE_OPERATIONS_HKL_FULL_DEFAULTS,
		.capabilities = HKL_ENGINE_CAPABILITIES_READABLE | HKL_ENGINE_CAPABILITIES_WRITABLE | HKL_ENGINE_CAPABILITIES_INITIALIZABLE,
		.initialized_set = hkl_mode_hkl_emergence_fixed_initialized_set_real,
		.set = hkl_mode_hkl_emergence_fixed_set_real,
	};
	HklModeAutoHklEmergenceFixed *self;

	if (darray_size(auto_info->info.axes_w) != 4){
		fprintf(stderr, "This generic HklModeAutoHklEmergenceFixed need exactly 4 axes");
		exit(128);
	}

	self = HKL_MALLOC(HklModeAutoHklEmergenceFixed);

	/* the base constructor; */
	hkl_mode_auto_init(&self->parent,
			   auto_info,
			   &operations, FALSE);

	self->n_x = register_mode_parameter(&self->parent, 0);
	self->n_y = register_mode_parameter(&self->parent, 1);
	self->n_z = register_mode_parameter(&self->parent, 2);
	self->emergence = register_mode_parameter(&self->parent, 3);

	return &self->parent;
}

/*************/
/* HklEngine */
/*************/

static void hkl_engine_hkl_free_real(HklEngine *base)
{
	HklEngineHkl *self = container_of(base, HklEngineHkl, engine);
	hkl_engine_release(&self->engine);
	free(self);
}

HklEngine *hkl_engine_hkl_new(HklEngineList *engines)
{
	HklEngineHkl *self;
	static const HklParameter h = {
		HKL_PARAMETER_DEFAULTS, .name = "h",
		.description = "h coordinate of the diffracting plan",
		.range = { .min=-1, .max=1 },
	};
	static const HklParameter k = {
		HKL_PARAMETER_DEFAULTS, .name = "k",
		.description = "k coordinate of the diffracting plan",
		.range = { .min=-1, .max=1 },
	};
	static const HklParameter l = {
		HKL_PARAMETER_DEFAULTS, .name = "l",
		.description = "l coordinate of the diffracting plan",
		.range={ .min=-1, .max=1 },
	};
	static const HklParameter *pseudo_axes[] = {&h, &k, &l};
	static HklEngineInfo info = {
		HKL_ENGINE_INFO("hkl",
				pseudo_axes,
				HKL_ENGINE_DEPENDENCIES_AXES | HKL_ENGINE_DEPENDENCIES_ENERGY | HKL_ENGINE_DEPENDENCIES_SAMPLE),
	};
	static HklEngineOperations operations = {
		HKL_ENGINE_OPERATIONS_DEFAULTS,
		.free=hkl_engine_hkl_free_real,
	};

	self = HKL_MALLOC(HklEngineHkl);

	hkl_engine_init(&self->engine, &info, &operations, engines);

	self->h = register_pseudo_axis(&self->engine, engines, &h);
	self->k = register_pseudo_axis(&self->engine, engines, &k);
	self->l = register_pseudo_axis(&self->engine, engines, &l);

	return &self->engine;
}
