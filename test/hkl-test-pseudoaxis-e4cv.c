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
 * Copyright (C) 2003-2009 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#include <math.h>
#include <hkl.h>

#include "hkl-test.h"

#ifdef HKL_TEST_SUITE_NAME
# undef HKL_TEST_SUITE_NAME
#endif
#define HKL_TEST_SUITE_NAME pseudoaxis_E4CV

#define SET_AXES(geom, omega, chi, phi, tth) do{\
	hkl_geometry_set_values_v(geom, 4,\
				  omega * HKL_DEGTORAD,\
				  chi * HKL_DEGTORAD,\
				  phi * HKL_DEGTORAD,\
				  tth * HKL_DEGTORAD);\
} while(0)

#define CHECK_PSEUDOAXES(engine, a, b, c) do{				\
		HklParameter *H = (HklParameter *)(engine->pseudoAxes[0]); \
		HklParameter *K = (HklParameter *)(engine->pseudoAxes[1]); \
		HklParameter *L = (HklParameter *)(engine->pseudoAxes[2]); \
									\
		HKL_ASSERT_DOUBLES_EQUAL(a, H->value, HKL_EPSILON); \
		HKL_ASSERT_DOUBLES_EQUAL(b, K->value, HKL_EPSILON); \
		HKL_ASSERT_DOUBLES_EQUAL(c, L->value, HKL_EPSILON); \
	} while(0)

HKL_TEST_SUITE_FUNC(new)
{
	HklPseudoAxisEngine *engine = hkl_pseudo_axis_engine_e4cv_hkl_new();
	hkl_pseudo_axis_engine_free(engine);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(getter)
{
	HklPseudoAxisEngineList *engines;
	HklPseudoAxisEngine *engine;
	HklGeometry *geom;
	HklDetector det = {1};
	HklSample *sample;

	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	sample = hkl_sample_new("test", HKL_SAMPLE_MONOCRYSTAL);

	engines = hkl_pseudo_axis_engine_list_factory(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	engine = hkl_pseudo_axis_engine_list_get_by_name(engines, "hkl");

	// geometry -> pseudo
	SET_AXES(geom, 30., 0., 0., 60.);
	hkl_pseudo_axis_engine_getter(engine, geom, &det, sample);
	CHECK_PSEUDOAXES(engine, 0., 0., 1.);

	SET_AXES(geom, 30., 0., 90., 60.);
	hkl_pseudo_axis_engine_getter(engine, geom, &det, sample);
	CHECK_PSEUDOAXES(engine, 1., 0., 0.);

	SET_AXES(geom, 30, 0., -90., 60.);
	hkl_pseudo_axis_engine_getter(engine, geom, &det, sample);
	CHECK_PSEUDOAXES(engine, -1., 0., 0.);

	SET_AXES(geom, 30., 0., 180., 60.);
	hkl_pseudo_axis_engine_getter(engine, geom, &det, sample);
	CHECK_PSEUDOAXES(engine, 0., 0., -1.);

	SET_AXES(geom, 45., 0., 135., 90.);
	hkl_pseudo_axis_engine_getter(engine, geom, &det, sample);
	CHECK_PSEUDOAXES(engine, 1., 0., -1.);

	hkl_pseudo_axis_engine_list_free(engines);
	hkl_sample_free(sample);
	hkl_geometry_free(geom);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(degenerated)
{
	HklPseudoAxisEngineList *engines;
	HklPseudoAxisEngine *engine;
	HklGeometry *geom;
	HklDetector det = {1};
	HklSample *sample;
	size_t i, f_idx;
	double *H, *K, *L;

	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	sample = hkl_sample_new("test", HKL_SAMPLE_MONOCRYSTAL);

	engines = hkl_pseudo_axis_engine_list_factory(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	engine = hkl_pseudo_axis_engine_list_get_by_name(engines, "hkl");

	H = &(((HklParameter *)engine->pseudoAxes[0])->value);
	K = &(((HklParameter *)engine->pseudoAxes[1])->value);
	L = &(((HklParameter *)engine->pseudoAxes[2])->value);

	for(f_idx=0; f_idx<HKL_LIST_LEN(engine->modes); ++f_idx){

		hkl_pseudo_axis_engine_select_mode(engine, f_idx);
		if (HKL_LIST_LEN(engine->mode->parameters))
			engine->mode->parameters[0].value = 0.;

		double h, k, l;
		int res;

		/* studdy this degenerated case */
		*H = h = 0;
		*K = k = 0;
		*L = l = 1;

		// pseudo -> geometry
		res = hkl_pseudo_axis_engine_setter(engine, geom, &det, sample);
		//hkl_pseudo_axis_engine_fprintf(stdout, engine);

		// geometry -> pseudo
		if(res == HKL_SUCCESS){
			//hkl_pseudo_axis_engine_fprintf(stdout, engine);
			for(i=0; i<HKL_LIST_LEN(engines->geometries->geometries); ++i){
				*H = *K = *L = 0;

				hkl_geometry_init_geometry(engine->geometry, engines->geometries->geometries[i]);
				hkl_pseudo_axis_engine_getter(engine, engine->geometry, &det, sample);

				HKL_ASSERT_DOUBLES_EQUAL(h, *H, HKL_EPSILON);
				HKL_ASSERT_DOUBLES_EQUAL(k, *K, HKL_EPSILON);
				HKL_ASSERT_DOUBLES_EQUAL(l, *L, HKL_EPSILON);
			}
		}
	}

	hkl_pseudo_axis_engine_list_free(engines);
	hkl_sample_free(sample);
	hkl_geometry_free(geom);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(psi_getter)
{
	HklPseudoAxisEngineList *engines;
	HklPseudoAxisEngine *engine;
	HklGeometry *geom;
	HklDetector detector = {1};
	HklSample *sample;
	size_t i, f_idx;
	double *psi;
	double *h_ref;
	double *k_ref;
	double *l_ref;
	int status;

	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	sample = hkl_sample_new("test", HKL_SAMPLE_MONOCRYSTAL);

	engines = hkl_pseudo_axis_engine_list_factory(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	engine = hkl_pseudo_axis_engine_list_get_by_name(engines, "psi");

	psi = &(((HklParameter *)engine->pseudoAxes[0])->value);
	h_ref = &engine->mode->parameters[0].value;
	k_ref = &engine->mode->parameters[1].value;
	l_ref = &engine->mode->parameters[2].value;

	// the getter part
	SET_AXES(geom, 30., 0., 0., 60.);
	hkl_pseudo_axis_engine_init(engine, geom, &detector, sample);

	*h_ref = 1;
	*k_ref = 0;
	*l_ref = 0;
	status = hkl_pseudo_axis_engine_getter(engine, geom, &detector, sample);
	HKL_ASSERT_EQUAL(HKL_SUCCESS, status);
	HKL_ASSERT_DOUBLES_EQUAL(0 * HKL_DEGTORAD, *psi, HKL_EPSILON);

	*h_ref = 0;
	*k_ref = 1;
	*l_ref = 0;
	status = hkl_pseudo_axis_engine_getter(engine, geom, &detector, sample);
	HKL_ASSERT_EQUAL(HKL_SUCCESS, status);
	HKL_ASSERT_DOUBLES_EQUAL(90 * HKL_DEGTORAD, *psi, HKL_EPSILON);

	// here Q and <h, k, l>_ref are colinear
	*h_ref = 0;
	*k_ref = 0;
	*l_ref = 1;
	status = hkl_pseudo_axis_engine_getter(engine, geom, &detector, sample);
	HKL_ASSERT_EQUAL(HKL_FAIL, status);

	*h_ref = -1;
	*k_ref = 0;
	*l_ref = 0;
	status = hkl_pseudo_axis_engine_getter(engine, geom, &detector, sample);
	HKL_ASSERT_EQUAL(HKL_SUCCESS, status);
	HKL_ASSERT_DOUBLES_EQUAL(180 * HKL_DEGTORAD, *psi, HKL_EPSILON);

	*h_ref = 0;
	*k_ref = -1;
	*l_ref = 0;
	status = hkl_pseudo_axis_engine_getter(engine, geom, &detector, sample);
	HKL_ASSERT_EQUAL(HKL_SUCCESS, status);
	HKL_ASSERT_DOUBLES_EQUAL(-90 * HKL_DEGTORAD, *psi, HKL_EPSILON);
	
	*h_ref = 0;
	*k_ref = 0;
	*l_ref = -1;
	status = hkl_pseudo_axis_engine_getter(engine, geom, &detector, sample);
	HKL_ASSERT_EQUAL(HKL_FAIL, status);

	hkl_pseudo_axis_engine_list_free(engines);
	hkl_sample_free(sample);
	hkl_geometry_free(geom);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(psi_setter)
{
	HklPseudoAxisEngineList *engines;
	HklPseudoAxisEngine *engine;
	HklGeometry *geom;
	HklDetector detector = {1};
	HklSample *sample;
	size_t i, f_idx;
	double *Psi;
	double *h_ref, *k_ref, *l_ref;

	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	sample = hkl_sample_new("test", HKL_SAMPLE_MONOCRYSTAL);

	engines = hkl_pseudo_axis_engine_list_factory(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	engine = hkl_pseudo_axis_engine_list_get_by_name(engines, "psi");

	Psi = &(((HklParameter *)engine->pseudoAxes[0])->value);
	h_ref = &engine->mode->parameters[0].value;
	k_ref = &engine->mode->parameters[1].value;
	l_ref = &engine->mode->parameters[2].value;

	// the init part
	SET_AXES(geom, 30., 0., 0., 60.);
	*h_ref = 1;
	*k_ref = 0;
	*l_ref = 0;
	hkl_pseudo_axis_engine_init(engine, geom, &detector, sample);


	for(f_idx=0; f_idx<HKL_LIST_LEN(engine->modes); ++f_idx){
		double psi;
		int res;

		hkl_pseudo_axis_engine_select_mode(engine, f_idx);
		for(psi=-180;psi<180;psi++){
			*Psi = psi * HKL_DEGTORAD;
			
			// pseudo -> geometry
			res = hkl_pseudo_axis_engine_setter(engine, geom, &detector, sample);
			//hkl_pseudo_axis_engine_fprintf(stdout, engine);
			
			// geometry -> pseudo
			if(res == HKL_SUCCESS){
				//hkl_pseudo_axis_engine_fprintf(stdout, engine);
				for(i=0; i<HKL_LIST_LEN(engines->geometries->geometries); ++i){
					*Psi = 0;
					
					hkl_geometry_init_geometry(engine->geometry, engines->geometries->geometries[i]);
					hkl_pseudo_axis_engine_getter(engine, engine->geometry, &detector, sample);
					HKL_ASSERT_DOUBLES_EQUAL(psi * HKL_DEGTORAD, *Psi, HKL_EPSILON);
				}
			}
		}
	}

	hkl_pseudo_axis_engine_list_free(engines);
	hkl_sample_free(sample);
	hkl_geometry_free(geom);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_BEGIN

HKL_TEST( new );
HKL_TEST( getter );
HKL_TEST( degenerated );
HKL_TEST( psi_getter );
HKL_TEST( psi_setter );

HKL_TEST_SUITE_END
