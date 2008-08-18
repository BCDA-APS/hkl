#include <math.h>

#include <hkl-constants.h>
#include <hkl-detector.h>
#include <hkl-geometry.h>
#include <hkl-holder.h>
#include <hkl-axis.h>

#include "hkl-test.h"

#ifdef HKL_TEST_SUITE_NAME
# undef HKL_TEST_SUITE_NAME
#endif
#define HKL_TEST_SUITE_NAME detector

HKL_TEST_SUITE_FUNC(init)
{
	HklDetector det;
	HklGeometry *geom = NULL;
	HklAxis *axis1 = NULL;
	HklAxis *axis2 = NULL;
	HklHolder *holder = NULL;

	geom = hkl_geometry_new();
	holder = hkl_geometry_add_holder(geom);
	axis1 = hkl_holder_add_rotation_axis(holder, "a", 1, 0, 0);
	axis2 = hkl_holder_add_rotation_axis(holder, "b", 0, 1, 0);

	hkl_detector_init(&det, 0);

	HKL_ASSERT_EQUAL(0, det.idx);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(compute_kf)
{
	HklDetector det;
	HklGeometry *geom = NULL;
	HklAxis *axis1 = NULL;
	HklAxis *axis2 = NULL;
	HklHolder *holder = NULL;
	HklVector kf;
	HklVector kf_ref = {0, HKL_TAU / HKL_DEFAULT_WAVE_LENGTH, 0};
	HklAxisConfig config;

	geom = hkl_geometry_new();
	holder = hkl_geometry_add_holder(geom);
	axis1 = hkl_holder_add_rotation_axis(holder, "a", 1, 0, 0);
	axis2 = hkl_holder_add_rotation_axis(holder, "b", 0, 1, 0);

	hkl_detector_init(&det, 0);

	hkl_axis_get_config(axis1, &config);
	config.value = G_PI_2;
	hkl_axis_set_config(axis1, &config);
	hkl_axis_set_config(axis2, &config);

	hkl_detector_compute_kf(&det, geom, &kf);
	HKL_ASSERT_EQUAL(0, hkl_vector_cmp(&kf_ref, &kf));

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_BEGIN

HKL_TEST( init );
HKL_TEST( compute_kf );

HKL_TEST_SUITE_END
