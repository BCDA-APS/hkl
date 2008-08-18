#include <math.h>

#include <hkl-parameter.h>
#include <hkl-constants.h>

#include "hkl-test.h"

#ifdef HKL_TEST_SUITE_NAME
# undef HKL_TEST_SUITE_NAME
#endif
#define HKL_TEST_SUITE_NAME parameter

HKL_TEST_SUITE_FUNC(init)
{
	HklParameter p;

	hkl_parameter_init(&p, "toto", 1., 2., 3., TRUE);
	HKL_ASSERT_DOUBLES_EQUAL(1., p.range.min, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(2., p.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(3., p.range.max, HKL_EPSILON);
	HKL_ASSERT_EQUAL(TRUE, p.to_fit);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(copy)
{
	HklParameter copy, p;

	hkl_parameter_init(&p, "toto", 1, 2, 3, TRUE);
	copy = p;

	HKL_ASSERT_POINTER_EQUAL(copy.name, p.name);
	HKL_ASSERT_DOUBLES_EQUAL(copy.range.min, p.range.min, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(copy.value, p.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(copy.range.max, p.range.max, HKL_EPSILON);
	HKL_ASSERT_EQUAL(copy.to_fit, p.to_fit);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_BEGIN

HKL_TEST( init );
HKL_TEST( copy );

HKL_TEST_SUITE_END
