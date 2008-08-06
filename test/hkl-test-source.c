#include <math.h>

#include <hkl-source.h>
#include <hkl-constants.h>

#include "hkl-test.h"

#ifdef HKL_TEST_SUITE_NAME
# undef HKL_TEST_SUITE_NAME
#endif
#define HKL_TEST_SUITE_NAME source

HKL_TEST_SUITE_FUNC(set)
{
	HklSource s;

	hkl_source_set(&s, 1, 1, 0, 0);
	
	HKL_ASSERT_DOUBLES_EQUAL(1., s.wave_length, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1., s.direction.x, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., s.direction.y, hkl_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., s.direction.z, hkl_EPSILON);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(cmp)
{
	HklSource ref, s1, s2;

	hkl_source_set(&ref, 1.54, 1, 0, 0);
	hkl_source_set(&s1, 1.54, 1, 0, 0);
	hkl_source_set(&s2, 1, 1, 0, 0);

	HKL_ASSERT_EQUAL(0, hkl_source_cmp(&ref, &s1));
	HKL_ASSERT_EQUAL(0, !hkl_source_cmp(&ref, &s2));

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(copy)
{
	HklSource s1, s2;

	hkl_source_set(&s1, 1.54, 1, 0, 0);
	s2 = s1;
	
	HKL_ASSERT_DOUBLES_EQUAL(s1.wave_length, s2.wave_length, hkl_EPSILON);
	HKL_ASSERT_EQUAL(0, hkl_vector_cmp(&s1.direction, &s2.direction));

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(get_ki)
{
	HklSource s;
	HklVector ki_ref = {hkl_TAU / 1.54, 0, 0};
	HklVector ki;

	hkl_source_set(&s, 1.54, 1, 0, 0);

	hkl_source_get_ki(&s, &ki);
	HKL_ASSERT_EQUAL(0, hkl_vector_cmp(&ki_ref, &ki));

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_BEGIN

HKL_TEST( set );
HKL_TEST( cmp );
HKL_TEST( copy );
HKL_TEST( get_ki );

HKL_TEST_SUITE_END
