#include <math.h>

#include <hkl-geometry-factory.h>
#include <hkl-pseudoaxis-E4CV.h>
#include <hkl-pseudoaxis-auto.h>

#include "hkl-test.h"

#ifdef HKL_TEST_SUITE_NAME
# undef HKL_TEST_SUITE_NAME
#endif
#define HKL_TEST_SUITE_NAME pseudoaxis

#define SET_AXES(geometry, a, b, c, d) do{\
	HklAxis *Omega, *Chi, *Phi, *Tth;\
	HklAxisConfig config;\
	\
	Omega = hkl_geometry_get_axis(geometry, 0);\
	Chi = hkl_geometry_get_axis(geometry, 1);\
	Phi = hkl_geometry_get_axis(geometry, 2);\
	Tth = hkl_geometry_get_axis(geometry, 3);\
	\
	hkl_axis_get_config(Omega, &config);\
	config.value = a * HKL_DEGTORAD;\
	hkl_axis_set_config(Omega, &config);\
	\
	hkl_axis_get_config(Chi, &config);\
	config.value = b * HKL_DEGTORAD;\
	hkl_axis_set_config(Chi, &config);\
	\
	hkl_axis_get_config(Phi, &config);\
	config.value = c * HKL_DEGTORAD;\
	hkl_axis_set_config(Phi, &config);\
	\
	hkl_axis_get_config(Tth, &config);\
	config.value = d * HKL_DEGTORAD;\
	hkl_axis_set_config(Tth, &config);\
} while(0)

#define CHECK_PSEUDOAXES(engine, a, b, c) do{\
	HklPseudoAxis *H, *K, *L;\
	\
	H = (HklPseudoAxis *)hkl_list_get(engine->pseudoAxes, 0);\
	K = (HklPseudoAxis *)hkl_list_get(engine->pseudoAxes, 1);\
	L = (HklPseudoAxis *)hkl_list_get(engine->pseudoAxes, 2);\
	\
	HKL_ASSERT_DOUBLES_EQUAL(a, H->config.value, HKL_EPSILON);\
	HKL_ASSERT_DOUBLES_EQUAL(b, K->config.value, HKL_EPSILON);\
	HKL_ASSERT_DOUBLES_EQUAL(c, L->config.value, HKL_EPSILON);\
	\
} while(0)

HKL_TEST_SUITE_FUNC(new)
{
	HklPseudoAxisEngine *engine;
	HklGeometry *geom;
	char *pseudoaxes[] = {"h", "k", "l"};

	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	engine = (HklPseudoAxisEngine *)hkl_pseudo_axis_engine_auto_new("hkl", pseudoaxes, 3, geom);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(compute_pseudoAxes)
{
	HklPseudoAxisEngine *engine;
	HklGeometry *geom;
	HklDetector det;
	HklSample *sample;
	char *pseudoaxes[] = {"h", "k", "l"};
	char *axes[] = {"omega", "chi", "phi", "tth"};

	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	hkl_detector_init(&det, 1);
	sample = hkl_sample_new("test");
	engine = (HklPseudoAxisEngine *)hkl_pseudo_axis_engine_auto_new("hkl", pseudoaxes, 3, geom);
	gsl_multiroot_function fm[] = {{E4CV_bissector, 4, engine}};
	HklPseudoAxisEngineFunc f = {fm, 1, axes, 4};
	hkl_pseudo_axis_engine_set(engine, &f, &det, sample);

	// geometry -> pseudo
	SET_AXES(geom, 30., 0., 0., 60.);
	hkl_pseudo_axis_engine_compute_pseudoAxes(engine, geom);
	CHECK_PSEUDOAXES(engine, 0., 0., 1.);

	SET_AXES(geom, 30., 0., 90., 60.);
	hkl_pseudo_axis_engine_compute_pseudoAxes(engine, geom);
	CHECK_PSEUDOAXES(engine, 1., 0., 0.);

	SET_AXES(geom, 30, 0., -90., 60.);
	hkl_pseudo_axis_engine_compute_pseudoAxes(engine, geom);
	CHECK_PSEUDOAXES(engine, -1., 0., 0.);

	SET_AXES(geom, 30., 0., 180., 60.);
	hkl_pseudo_axis_engine_compute_pseudoAxes(engine, geom);
	CHECK_PSEUDOAXES(engine, 0., 0., -1.);

	SET_AXES(geom, 45., 0., 135., 90.);
	hkl_pseudo_axis_engine_compute_pseudoAxes(engine, geom);
	CHECK_PSEUDOAXES(engine, 1., 0., -1.);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(compute_geometries)
{
	HklPseudoAxisEngine *engine;
	HklPseudoAxis *H, *K, *L;
	HklGeometry *geom;
	HklDetector det;
	HklSample *sample;
	unsigned int i, j;
	char *pseudoaxes[] = {"h", "k", "l"};
	char *axes[] = {"omega", "chi", "phi", "tth"};

	geom = hkl_geometry_factory_new(HKL_GEOMETRY_EULERIAN4C_VERTICAL);
	hkl_detector_init(&det, 1);
	sample = hkl_sample_new("test");
	engine = (HklPseudoAxisEngine *)hkl_pseudo_axis_engine_auto_new("hkl", pseudoaxes, 3, geom);
	gsl_multiroot_function fm[] = {{E4CV_bissector, 4, engine}};
	HklPseudoAxisEngineFunc f = {fm, 1, axes, 4};
	hkl_pseudo_axis_engine_set(engine, &f, &det, sample);

	H = (HklPseudoAxis *)hkl_list_get(engine->pseudoAxes, 0);
	K = (HklPseudoAxis *)hkl_list_get(engine->pseudoAxes, 1);
	L = (HklPseudoAxis *)hkl_list_get(engine->pseudoAxes, 2);

	for(i=0;i<1000;++i) {
		double h, k, l;
		double hh, kk, ll;
		int res;

		H->config.value = h = (double)rand() / RAND_MAX * 2 - 1.;
		K->config.value = k = (double)rand() / RAND_MAX * 2 - 1.;
		L->config.value = l = (double)rand() / RAND_MAX * 2 - 1.;

		// pseudo -> geometry
		res = hkl_pseudo_axis_engine_compute_geometries(engine);

		// geometry -> pseudo
		if (res) {
			// check all solutions
			for(j=0; j<engine->geometries->length; ++j) {
				HklGeometry *g = hkl_list_get(engine->geometries, j);
				hkl_pseudo_axis_engine_compute_pseudoAxes(engine, g);

				hh = H->config.value;
				kk = K->config.value;
				ll = L->config.value;

				HKL_ASSERT_DOUBLES_EQUAL(h, hh, HKL_EPSILON);
				HKL_ASSERT_DOUBLES_EQUAL(k, kk, HKL_EPSILON);
				HKL_ASSERT_DOUBLES_EQUAL(l, ll, HKL_EPSILON);
			}
		}
	}

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_BEGIN

HKL_TEST( new );
HKL_TEST( compute_pseudoAxes );
HKL_TEST( compute_geometries );

HKL_TEST_SUITE_END
