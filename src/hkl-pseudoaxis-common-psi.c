#include <gsl/gsl_math.h>
#include <gsl/gsl_vector.h>
#include <gsl/gsl_sf_trig.h>

#include <hkl/hkl-pseudoaxis.h>
#include <hkl/hkl-pseudoaxis-auto.h>
#include <hkl/hkl-pseudoaxis-common-psi.h>

static int psi(const gsl_vector *x, void *params, gsl_vector *f)
{

	HklVector dhkl0, hkl1;
	HklVector ki, kf, Q, n;
	HklMatrix RUB;
	HklPseudoAxisEngine *engine;
	HklPseudoAxisEngineGetSetPsi *getsetpsi;
	HklPseudoAxis *psi;
	HklHolder *holder;
	size_t i;
	double const *x_data = gsl_vector_const_ptr(x, 0);
	double *f_data = gsl_vector_ptr(f, 0);

	engine = params;
	getsetpsi = (HklPseudoAxisEngineGetSetPsi *)engine->getset;
	psi = engine->pseudoAxes[0];

	// update the workspace from x;
	for(i=0; i<engine->axes_len; ++i)
		hkl_parameter_set_value((HklParameter *)(engine->axes[i]), x_data[i]);
	hkl_geometry_update(engine->geometry);

	// kf - ki = Q
	hkl_source_compute_ki(&engine->geometry->source, &ki);
	hkl_detector_compute_kf(engine->detector, engine->geometry, &kf);
	Q = kf;
	hkl_vector_minus_vector(&Q, &ki);
	if (hkl_vector_is_null(&Q)){
		f_data[0] = 1;
		f_data[1] = 1;
		f_data[2] = 1;
		f_data[3] = 1;
	}else{
		// R * UB
		// for now the 0 holder is the sample holder.
		holder = &engine->geometry->holders[0];
		hkl_quaternion_to_smatrix(&holder->q, &RUB);
		hkl_matrix_times_smatrix(&RUB, &engine->sample->UB);

		// compute dhkl0
		hkl_matrix_solve(&RUB, &dhkl0, &Q);
		hkl_vector_minus_vector(&dhkl0, &getsetpsi->hkl0);

		// compute the intersection of the plan P(kf, ki) and PQ (normal Q)
		/* 
		 * now that dhkl0 have been computed we can use a
		 * normalized Q to compute n and psi
		 */ 
		hkl_vector_normalize(&Q);
		n = kf;
		hkl_vector_vectorial_product(&n, &ki);
		hkl_vector_vectorial_product(&n, &Q);

		// compute hkl1 in the laboratory referentiel
		// for now the 0 holder is the sample holder.
		hkl1.data[0] = engine->getset->parameters[0].value;
		hkl1.data[1] = engine->getset->parameters[1].value;
		hkl1.data[2] = engine->getset->parameters[2].value;
		hkl_vector_times_smatrix(&hkl1, &engine->sample->UB);
		hkl_vector_rotated_quaternion(&hkl1, &engine->geometry->holders[0].q);
	
		// project hkl1 on the plan of normal Q
		hkl_vector_project_on_plan(&hkl1, &Q);
		if (hkl_vector_is_null(&hkl1)){ // hkl1 colinear with Q
			f_data[0] = dhkl0.data[0];
			f_data[1] = dhkl0.data[1];
			f_data[2] = dhkl0.data[2];
			f_data[3] = 1;
		}else{
			f_data[0] = dhkl0.data[0];
			f_data[1] = dhkl0.data[1];
			f_data[2] = dhkl0.data[2];
			f_data[3] = psi->parent.value - hkl_vector_oriented_angle(&n, &hkl1, &Q);
		}
	}
	return GSL_SUCCESS;
}

static int hkl_pseudo_axis_engine_get_set_init_psi_real(HklPseudoAxisEngine *engine,
							HklGeometry *geometry,
							HklDetector const *detector,
							HklSample const *sample)
{
	int status = HKL_SUCCESS;
	HklVector ki;
	HklMatrix RUB;
	HklPseudoAxisEngineGetSetPsi *self;
	HklHolder *holder;
	
	status = hkl_pseudo_axis_engine_init_func(engine, geometry, detector, sample);
	if (status == HKL_FAIL)
		return status;

	self = (HklPseudoAxisEngineGetSetPsi *)engine->getset;

	// update the geometry internals
	hkl_geometry_update(geometry);

	// R * UB
	// for now the 0 holder is the sample holder.
	holder = &geometry->holders[0];
	hkl_quaternion_to_smatrix(&holder->q, &RUB);
	hkl_matrix_times_smatrix(&RUB, &sample->UB);

	// kf - ki = Q0
	hkl_source_compute_ki(&geometry->source, &ki);
	hkl_detector_compute_kf(detector, geometry, &self->Q0);
	hkl_vector_minus_vector(&self->Q0, &ki);
	if (hkl_vector_is_null(&self->Q0))
		status = HKL_FAIL;
	else
		// compute hkl0
		hkl_matrix_solve(&RUB, &self->hkl0, &self->Q0);

	return status;
}

static int hkl_pseudo_axis_engine_get_set_get_psi_real(HklPseudoAxisEngine *engine,
						       HklGeometry *geometry,
						       HklDetector const *detector,
						       HklSample const *sample)
{
	int status = HKL_SUCCESS;

	if (!engine || !engine->getset || !geometry || !detector || !sample){
		status = HKL_FAIL;
		return status;
	}

	HklVector ki;
	HklVector kf;
	HklVector Q;
	HklVector hkl1;
	HklVector n;
	HklPseudoAxisEngineGetSetPsi *self;
	HklPseudoAxisEngineGetSet *base;

	self = (HklPseudoAxisEngineGetSetPsi *)engine->getset;
	base = engine->getset;

	// get kf, ki and Q
	hkl_source_compute_ki(&geometry->source, &ki);
	hkl_detector_compute_kf(detector, geometry, &kf);
	Q = kf;
	hkl_vector_minus_vector(&Q, &ki);
	if (hkl_vector_is_null(&Q))
		status = HKL_FAIL;
	else{
		hkl_vector_normalize(&Q); // needed for a problem of precision

		// compute the intersection of the plan P(kf, ki) and PQ (normal Q)
		n = kf;
		hkl_vector_vectorial_product(&n, &ki);
		hkl_vector_vectorial_product(&n, &Q);

		// compute hkl1 in the laboratory referentiel
		// the geometry was already updated in the detector compute kf
		// for now the 0 holder is the sample holder.
		hkl1.data[0] = base->parameters[0].value;
		hkl1.data[1] = base->parameters[1].value;
		hkl1.data[2] = base->parameters[2].value;
		hkl_vector_times_smatrix(&hkl1, &sample->UB);
		hkl_vector_rotated_quaternion(&hkl1, &geometry->holders[0].q);
	
		// project hkl1 on the plan of normal Q
		hkl_vector_project_on_plan(&hkl1, &Q);
	
		if (hkl_vector_is_null(&hkl1))
			status = HKL_FAIL;
		else
			// compute the angle beetween hkl1 and n
			((HklParameter *)engine->pseudoAxes[0])->value = hkl_vector_oriented_angle(&n, &hkl1, &Q);
	}

	return status;
}

static int hkl_pseudo_axis_engine_get_set_set_psi_real(HklPseudoAxisEngine *engine,
						       HklGeometry *geometry,
						       HklDetector *detector,
						       HklSample *sample)
{
	hkl_pseudo_axis_engine_prepare_internal(engine, geometry, detector,
						sample);

	return hkl_pseudo_axis_engine_solve_function(engine, psi);
}

HklPseudoAxisEngineGetSetPsi *hkl_pseudo_axis_engine_get_set_psi_new(char const *name,
								     size_t axes_names_len,
								     char const *axes_names[])
{
	HklPseudoAxisEngineGetSetPsi *self;
	char const *parameters_names[] = {"h1", "k1", "l1"};

	if (axes_names_len != 4)
		die("This generic HklPseudoAxisEngineGetSetPsi need exactly 4 axes");

	self = calloc(1, sizeof(*self));
	if (!self)
		die("Can not allocate memory for an HklPseudoAxisEngineGetSetPsi");

	// the base constructor;
	hkl_pseudo_axis_engine_get_set_init(&self->parent,
					    name,
					    hkl_pseudo_axis_engine_get_set_init_psi_real,
					    hkl_pseudo_axis_engine_get_set_get_psi_real,
					    hkl_pseudo_axis_engine_get_set_set_psi_real,
					    3, parameters_names,
					    axes_names_len, axes_names);

	self->parent.parameters[0].value = 1;
	self->parent.parameters[0].range.min = -1;
	self->parent.parameters[0].range.max = 1;
	self->parent.parameters[0].not_to_fit = HKL_FALSE;

	self->parent.parameters[1].value = 0;
	self->parent.parameters[1].range.min = -1;
	self->parent.parameters[1].range.max = 1;
	self->parent.parameters[1].not_to_fit = HKL_FALSE;

	self->parent.parameters[2].value = 0;
	self->parent.parameters[2].range.min = -1;
	self->parent.parameters[2].range.max = 1;
	self->parent.parameters[2].not_to_fit = HKL_FALSE;

	return self;
}

HklPseudoAxisEngine *hkl_pseudo_axis_engine_psi_new(void)
{
	HklPseudoAxisEngine *self;

	self = hkl_pseudo_axis_engine_new("psi", 1, "psi");

	// psi
	hkl_parameter_init((HklParameter *)self->pseudoAxes[0],
			   "psi",
			   -M_PI, 0., M_PI,
			   HKL_FALSE, HKL_TRUE,
			   &hkl_unit_angle_rad, &hkl_unit_angle_deg);

	return self;
}
