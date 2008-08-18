#include <hkl-lattice.h>
#include <hkl-parameter.h>
#include <hkl-constants.h>

#include "hkl-test.h"

#ifdef HKL_TEST_SUITE_NAME
# undef HKL_TEST_SUITE_NAME
#endif
#define HKL_TEST_SUITE_NAME lattice

HKL_TEST_SUITE_FUNC( init )
{
	HklLattice lattice;

	// but can create this one
	hkl_lattice_init(&lattice, 1.54, 1.54, 1.54,
			90*HKL_DEGTORAD, 90*HKL_DEGTORAD, 90*HKL_DEGTORAD);

	HKL_ASSERT_DOUBLES_EQUAL(1.54, lattice.a.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.54, lattice.b.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.54, lattice.c.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90*HKL_DEGTORAD, lattice.alpha.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90*HKL_DEGTORAD, lattice.beta.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90*HKL_DEGTORAD, lattice.gamma.value, HKL_EPSILON);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC( copy )
{
	HklLattice lattice;
	HklLattice copy;

	hkl_lattice_init(&lattice, 1.54, 1.54, 1.54,
			90*HKL_DEGTORAD, 90*HKL_DEGTORAD, 90*HKL_DEGTORAD);

	// copy constructor
	copy = lattice;

	HKL_ASSERT_DOUBLES_EQUAL(1.54, copy.a.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.54, copy.b.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.54, copy.c.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, copy.alpha.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, copy.beta.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, copy.gamma.value, HKL_EPSILON);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(set)
{
	HklLattice lattice;

	// but can create this one
	hkl_lattice_init(&lattice, 1.54, 1.54, 1.54,
			90*HKL_DEGTORAD, 91*HKL_DEGTORAD, 92*HKL_DEGTORAD);

	HKL_ASSERT_DOUBLES_EQUAL(1.54, lattice.a.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.54, lattice.b.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.54, lattice.c.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90*HKL_DEGTORAD, lattice.alpha.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(91*HKL_DEGTORAD, lattice.beta.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(92*HKL_DEGTORAD, lattice.gamma.value, HKL_EPSILON);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC( compute_reciprocal )
{
	HklLattice lattice;
	HklLattice reciprocal;

	hkl_lattice_init_default(&lattice);
	hkl_lattice_init_default(&reciprocal);

	// cubic
	hkl_lattice_set(&lattice, 1.54, 1.54, 1.54,
			90*HKL_DEGTORAD, 90*HKL_DEGTORAD, 90*HKL_DEGTORAD);

	HKL_ASSERT_EQUAL(TRUE, hkl_lattice_compute_reciprocal(&lattice, &reciprocal));

	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU / 1.54, reciprocal.a.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU / 1.54, reciprocal.b.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU / 1.54, reciprocal.c.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, reciprocal.alpha.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, reciprocal.beta.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, reciprocal.gamma.value, HKL_EPSILON);

	//orthorombic
	hkl_lattice_set(&lattice, 1., 3., 4., 90 * HKL_DEGTORAD, 90 * HKL_DEGTORAD, 90 * HKL_DEGTORAD);
	HKL_ASSERT_EQUAL(TRUE, hkl_lattice_compute_reciprocal(&lattice, &reciprocal));

	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU / 1., reciprocal.a.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU / 3., reciprocal.b.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU / 4., reciprocal.c.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, reciprocal.alpha.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, reciprocal.beta.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, reciprocal.gamma.value, HKL_EPSILON);

	// hexagonal1
	hkl_lattice_set(&lattice, 1., 2., 1., 90 * HKL_DEGTORAD, 120 * HKL_DEGTORAD, 90 * HKL_DEGTORAD);
	HKL_ASSERT_EQUAL(TRUE, hkl_lattice_compute_reciprocal(&lattice, &reciprocal));

	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU * 2. / sqrt(3.), reciprocal.a.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU / 2., reciprocal.b.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU * 2. / sqrt(3.), reciprocal.c.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, reciprocal.alpha.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(60. * HKL_DEGTORAD, reciprocal.beta.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, reciprocal.gamma.value, HKL_EPSILON);

	// hexagonal2
	hkl_lattice_set(&lattice, 2., 1., 1., 120 * HKL_DEGTORAD, 90 * HKL_DEGTORAD, 90 * HKL_DEGTORAD);
	HKL_ASSERT_EQUAL(TRUE, hkl_lattice_compute_reciprocal(&lattice, &reciprocal));

	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU / 2., reciprocal.a.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU * 2. / sqrt(3.), reciprocal.b.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU * 2. / sqrt(3.), reciprocal.c.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(60. * HKL_DEGTORAD, reciprocal.alpha.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, reciprocal.beta.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90. * HKL_DEGTORAD, reciprocal.gamma.value, HKL_EPSILON);

	// triclinic1
	hkl_lattice_set(&lattice, 9.32, 8.24, 13.78, 91.23 * HKL_DEGTORAD, 93.64 * HKL_DEGTORAD, 122.21 * HKL_DEGTORAD);
	HKL_ASSERT_EQUAL(TRUE, hkl_lattice_compute_reciprocal(&lattice, &reciprocal));

	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU * 0.1273130168, reciprocal.a.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU * 0.1437422974, reciprocal.b.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU * 0.0728721120, reciprocal.c.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.5052513337, reciprocal.alpha.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.482101482, reciprocal.beta.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.0055896011, reciprocal.gamma.value, HKL_EPSILON);

	// triclinic2
	hkl_lattice_set(&lattice, 18.423, 18.417, 18.457, 89.99 * HKL_DEGTORAD, 89.963 * HKL_DEGTORAD, 119.99 * HKL_DEGTORAD);
	HKL_ASSERT_EQUAL(TRUE, hkl_lattice_compute_reciprocal(&lattice, &reciprocal));

	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU * 0.0626708259, reciprocal.a.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU * 0.0626912310, reciprocal.b.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(HKL_TAU * 0.0541800061, reciprocal.c.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.5713705262, reciprocal.alpha.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.5716426508, reciprocal.beta.value, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1.0473718249, reciprocal.gamma.value, HKL_EPSILON);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC( compute_B )
{
	HklMatrix B_ref = {
		HKL_TAU / 1.54,	0,		0,
		0, 		HKL_TAU / 1.54,	0,
		0,              0, 		HKL_TAU / 1.54};
	HklLattice lattice;
	HklMatrix B;

	// cubic
	hkl_lattice_init_default(&lattice);

	HKL_ASSERT_EQUAL(TRUE, hkl_lattice_compute_B(&lattice, &B));
	HKL_ASSERT_EQUAL(FALSE, hkl_matrix_cmp(&B_ref, &B));

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_BEGIN

HKL_TEST( init );
HKL_TEST( copy );
HKL_TEST( set );
HKL_TEST( compute_reciprocal );
HKL_TEST( compute_B );

HKL_TEST_SUITE_END
