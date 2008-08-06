#include <string.h>
#include <math.h>

#include <hkl-axis.h>
#include <hkl-constants.h>

#include "hkl-test.h"

#ifdef HKL_TEST_SUITE_NAME
# undef HKL_TEST_SUITE_NAME
#endif
#define HKL_TEST_SUITE_NAME axis

HKL_TEST_SUITE_FUNC( new_copy )
{
	HklAxis *axis;
	HklAxis *copy;
	HklVector v = {1, 0, 0};

	axis = hkl_axis_new("omega", &v);

	HKL_ASSERT_EQUAL(0, strcmp("omega", axis->name));
	HKL_ASSERT_DOUBLES_EQUAL(-G_PI, axis->config.range.min, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(G_PI, axis->config.range.max, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., axis->config.value, hkl_EPSILON);
	HKL_ASSERT_EQUAL(1, axis->config.dirty);

	/*
	copy = hkl_axis_new_copy(axis);

	HKL_ASSERT_EQUAL(0, strcmp("omega", copy->name));
	HKL_ASSERT_DOUBLES_EQUAL(-G_PI, copy->config.range.min, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(G_PI, copy->config.range.max, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., copy->config.value, hkl_EPSILON);
	HKL_ASSERT_EQUAL(1, copy->config.dirty);

	hkl_axis_unref(copy);
	*/
	hkl_axis_unref(axis);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC( clear_dirty )
{
	HklAxis *axis;
	HklVector v = {1, 0, 0};

	axis = hkl_axis_new("omega", &v);

	hkl_axis_clear_dirty(axis);

	HKL_ASSERT_EQUAL(FALSE, axis->config.dirty);

	hkl_axis_unref(axis);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC( get_set_config )
{
	HklAxis *axis;
	HklAxisConfig config;
	HklVector v = {1, 0, 0};

	axis = hkl_axis_new("omega", &v);

	hkl_axis_get_config(axis, &config);

	HKL_ASSERT_DOUBLES_EQUAL(-G_PI, config.range.min, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(G_PI, config.range.max, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., config.value, hkl_EPSILON);
	HKL_ASSERT_EQUAL(1, config.dirty);

	config.range.min = -1.;
	config.range.max = 1.;
	config.value = 0.5;
	hkl_axis_clear_dirty(axis);
	hkl_axis_set_config(axis, &config);

	HKL_ASSERT_DOUBLES_EQUAL(-1., axis->config.range.min, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1., axis->config.range.max, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0.5, axis->config.value, hkl_EPSILON);
	HKL_ASSERT_EQUAL(1, axis->config.dirty);

	hkl_axis_unref(axis);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC( get_quaternions )
{
	HklAxis *axis;
	HklVector v = {1, 0, 0};
	HklAxisConfig config;
	HklQuaternion q;

	axis = hkl_axis_new("omega", &v);

	hkl_axis_get_quaternion(axis, &q);
	HKL_ASSERT_DOUBLES_EQUAL(1., q.a, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., q.b, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., q.c, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., q.d, hkl_EPSILON);

	hkl_axis_get_config(axis, &config);
	config.value = -G_PI_2;
	hkl_axis_set_config(axis, &config);
	hkl_axis_get_quaternion(axis, &q);
	HKL_ASSERT_DOUBLES_EQUAL(1./sqrt(2.), q.a, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(-1./sqrt(2.), q.b, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., q.c, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., q.d, hkl_EPSILON);

	hkl_axis_unref(axis);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_BEGIN

HKL_TEST( new_copy );
HKL_TEST( clear_dirty );
HKL_TEST( get_set_config );
HKL_TEST( get_quaternions );

HKL_TEST_SUITE_END
