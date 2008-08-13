#include <math.h>

#include <hkl-sample.h>
#include <hkl-geometry-factory.h>
#include <hkl-constants.h>

#include "hkl-test.h"

#ifdef HKL_TEST_SUITE_NAME
# undef HKL_TEST_SUITE_NAME
#endif
#define HKL_TEST_SUITE_NAME sample

HKL_TEST_SUITE_FUNC(new)
{
	HklDetector det;
	HklGeometry *geom;
	HklSample *sample;

	hkl_detector_init(&det, 1);
	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	sample = hkl_sample_new("test");

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(add_reflection)
{
	HklDetector det;
	HklGeometry *geom;
	HklSample *sample;
	HklSampleReflection *ref;

	hkl_detector_init(&det, 1);
	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	sample = hkl_sample_new("test");

	ref = hkl_sample_add_reflection(sample, geom, &det, 1, 0, 0);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(get_reflection)
{
	HklDetector det;
	HklGeometry *geom;
	HklSample *sample;
	HklSampleReflection *ref;
	HklSampleReflection *ref2;

	hkl_detector_init(&det, 1);
	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	sample = hkl_sample_new("test");

	ref = hkl_sample_add_reflection(sample, geom, &det, 1, 0, 0);
	ref2 = hkl_sample_get_reflection(sample, 0);
	HKL_ASSERT_POINTER_EQUAL(ref, ref2);

	ref = hkl_sample_add_reflection(sample, geom, &det, -1, 0, 0);
	ref = hkl_sample_add_reflection(sample, geom, &det, 0, 1, 0);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(del_reflection)
{
	HklDetector det;
	HklGeometry *geom;
	HklSample *sample;
	HklSampleReflection *ref;

	hkl_detector_init(&det, 1);
	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	sample = hkl_sample_new("test");

	ref = hkl_sample_add_reflection(sample, geom, &det, 1, 0, 0);
	hkl_sample_del_reflection(sample, 0);
	HKL_ASSERT_EQUAL(0, sample->reflections->length);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(compute_UB_busing_levy)
{
	HklDetector det;
	HklGeometry *geom;
	HklSample *sample;
	HklSampleReflection *ref;
	HklMatrix m_I = {1,0,0, 0,1,0, 0,0,1};
	HklMatrix m_ref = {1.,0.,0., 0.,0.,1., 0.,-1.,0.};

	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);

#define SET_ANGLES(a, b, c, d)\
do {\
	HklAxis *Omega, *Chi, *Phi, *Tth;\
	HklAxisConfig omega, chi, phi, tth;\
\
	Omega = hkl_geometry_get_axis(geom, 0);\
	Chi = hkl_geometry_get_axis(geom, 1);\
	Phi = hkl_geometry_get_axis(geom, 2);\
	Tth = hkl_geometry_get_axis(geom, 3);\
	hkl_axis_get_config(Omega, &omega);\
	hkl_axis_get_config(Chi, &chi);\
	hkl_axis_get_config(Phi, &phi);\
	hkl_axis_get_config(Tth, &tth);\
\
	omega.value = a * hkl_DEGTORAD;\
	chi.value = b * hkl_DEGTORAD;\
	phi.value = c * hkl_DEGTORAD;\
	tth.value = d * hkl_DEGTORAD;\
\
	hkl_axis_set_config(Omega, &omega);\
	hkl_axis_set_config(Chi, &chi);\
	hkl_axis_set_config(Phi, &phi);\
	hkl_axis_set_config(Tth, &tth);\
}while(0)
	hkl_detector_init(&det, 1);
	sample = hkl_sample_new("test");

	SET_ANGLES(30, 0, 0, 60);
	ref = hkl_sample_add_reflection(sample, geom, &det, 0, 0, 1);

	SET_ANGLES(30, 0, -90, 60);
	ref = hkl_sample_add_reflection(sample, geom, &det, -1, 0, 0);

	hkl_sample_compute_UB_busing_levy(sample, 0, 1);
	HKL_ASSERT_EQUAL(FALSE, hkl_matrix_cmp(&m_I, &sample->U));

	SET_ANGLES(30, 0, 90, 60);
	ref = hkl_sample_add_reflection(sample, geom, &det, 1, 0, 0);

	SET_ANGLES(30, 0, 180, 60);
	ref = hkl_sample_add_reflection(sample, geom, &det, 0, 1, 0);

	hkl_sample_compute_UB_busing_levy(sample, 2, 3);
	HKL_ASSERT_EQUAL(FALSE, hkl_matrix_cmp(&m_ref, &sample->U));

#undef SET_ANGLES
	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(affine)
{
	double a, b, c, alpha, beta, gamma;
	HklDetector det;
	HklGeometry *geom;
	HklSample *sample;
	HklSampleReflection *ref;
	HklMatrix m_ref = {1., 0., 0., 0., 1., 0., 0., 0., 1.};

	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);

#define SET_ANGLES(a, b, c, d)\
do {\
	HklAxis *Omega, *Chi, *Phi, *Tth;\
	HklAxisConfig omega, chi, phi, tth;\
\
	Omega = hkl_geometry_get_axis(geom, 0);\
	Chi = hkl_geometry_get_axis(geom, 1);\
	Phi = hkl_geometry_get_axis(geom, 2);\
	Tth = hkl_geometry_get_axis(geom, 3);\
	hkl_axis_get_config(Omega, &omega);\
	hkl_axis_get_config(Chi, &chi);\
	hkl_axis_get_config(Phi, &phi);\
	hkl_axis_get_config(Tth, &tth);\
\
	omega.value = a * hkl_DEGTORAD;\
	chi.value = b * hkl_DEGTORAD;\
	phi.value = c * hkl_DEGTORAD;\
	tth.value = d * hkl_DEGTORAD;\
\
	hkl_axis_set_config(Omega, &omega);\
	hkl_axis_set_config(Chi, &chi);\
	hkl_axis_set_config(Phi, &phi);\
	hkl_axis_set_config(Tth, &tth);\
}while(0)
	hkl_detector_init(&det, 1);
	sample = hkl_sample_new("test");
	sample->lattice.a.value = 1;
	sample->lattice.a.to_fit = 1;
	sample->lattice.b.value = 5;
	sample->lattice.b.to_fit = 1;
	sample->lattice.c.value = 4;
	sample->lattice.c.to_fit = 1;
	sample->lattice.alpha.value = 92 * hkl_DEGTORAD;
	sample->lattice.alpha.to_fit = 1;
	sample->lattice.beta.value = 81 * hkl_DEGTORAD;
	sample->lattice.beta.to_fit = 1;
	sample->lattice.gamma.value = 90 * hkl_DEGTORAD;
	sample->lattice.gamma.to_fit = 1;

	SET_ANGLES(30, 0, 90, 60);
	ref = hkl_sample_add_reflection(sample, geom, &det, 1, 0, 0);

	SET_ANGLES(30, 90, 0, 60);
	ref = hkl_sample_add_reflection(sample, geom, &det, 0, 1, 0);

	SET_ANGLES(30, 0, 0, 60);
	ref = hkl_sample_add_reflection(sample, geom, &det, 0, 0, 1);

	SET_ANGLES(60, 60, 60, 60);
	ref = hkl_sample_add_reflection(sample, geom, &det, .625, .75, -.216506350946);

	SET_ANGLES(45, 45, 45, 60);
	ref = hkl_sample_add_reflection(sample, geom, &det, .665975615037, .683012701892, .299950211252);

	hkl_sample_affine(sample);

	a = sample->lattice.a.value;
	b = sample->lattice.b.value;
	c = sample->lattice.c.value;
	alpha = sample->lattice.alpha.value;
	beta = sample->lattice.beta.value;
	gamma = sample->lattice.gamma.value;
	HKL_ASSERT_EQUAL(FALSE, hkl_matrix_cmp(&m_ref, &sample->U));
	HKL_ASSERT_DOUBLES_EQUAL(1.54, a, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.54, b, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.54, c, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90 * hkl_DEGTORAD, alpha, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90 * hkl_DEGTORAD, beta, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90 * hkl_DEGTORAD, gamma, hkl_EPSILON);

#undef SET_ANGLES
	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_BEGIN

HKL_TEST( new );
HKL_TEST( add_reflection );
HKL_TEST( get_reflection );
HKL_TEST( del_reflection );
HKL_TEST( compute_UB_busing_levy );
HKL_TEST( affine );

HKL_TEST_SUITE_END
