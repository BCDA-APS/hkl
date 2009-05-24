#include <string.h>
#include <math.h>

#include <hkl.h>

#include "hkl-test.h"

#ifdef HKL_TEST_SUITE_NAME
# undef HKL_TEST_SUITE_NAME
#endif
#define HKL_TEST_SUITE_NAME holder

HKL_TEST_SUITE_FUNC(new_copy)
{
	HklGeometry *g1, *g2;
	HklHolder *holder, *copy, *tmp;
	unsigned int i;

	g1 = hkl_geometry_new();
	g2 = hkl_geometry_new();
	holder = hkl_holder_new(g1);

	// add two different axis
	hkl_holder_add_rotation_axis(holder, "a", 1, 0, 0);
	hkl_holder_add_rotation_axis(holder, "b", 1, 0, 0);

	// can not copy as axes1 and axes2 are not compatible
	// for now the vala constructor do not support requires
	//copy = hkl_holder_new_copy(holder, axes2);
	//HKL_ASSERT_POINTER_EQUAL(NULL, copy);
	
	// so set a compatible axes2 and copy the holder
	tmp = hkl_holder_new(g2);
	hkl_holder_add_rotation_axis(tmp, "a", 1, 0, 0);
	hkl_holder_add_rotation_axis(tmp, "b", 1, 0, 0);

	copy = hkl_holder_new_copy(holder, g2);

	// check that private_axes are the same
	for(i=0; i<holder->axes_length1; ++i) {
		HklAxis *axis_src = holder->axes[i];
		HklAxis *axis_copy = copy->axes[i];

		HKL_ASSERT_EQUAL(0, strcmp(axis_src->name, axis_copy->name));
	}

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(add_rotation_axis)
{
	HklGeometry *geom = NULL;
	HklHolder *holder = NULL;

	geom = hkl_geometry_new();
	holder = hkl_holder_new(geom);

	// add two different axis
	hkl_holder_add_rotation_axis(holder, "a", 1, 0, 0);
	HKL_ASSERT_EQUAL(1, holder->axes_length1);
	hkl_holder_add_rotation_axis(holder, "b", 1, 0, 0);
	HKL_ASSERT_EQUAL(2, holder->axes_length1);

	// can not add two times the same axes, must return the same axis
	hkl_holder_add_rotation_axis(holder, "a", 1, 0, 0);
	HKL_ASSERT_EQUAL(2, holder->axes_length1);

	return HKL_TEST_PASS;
}

HKL_TEST_SUITE_FUNC(update)
{
	HklAxis *axis = NULL;
	HklAxisConfig config;
	HklGeometry *geom;
	HklHolder *holder = NULL;

	geom = hkl_geometry_new();
	holder = hkl_holder_new(geom);

	hkl_holder_add_rotation_axis(holder, "a", 1, 0, 0);

	hkl_holder_update(holder);
	HKL_ASSERT_DOUBLES_EQUAL(1., holder->q.a, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., holder->q.b, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., holder->q.c, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., holder->q.d, HKL_EPSILON);

	axis = holder->axes[0];
	hkl_axis_get_config(axis, &config);
	config.value = G_PI_2;
	hkl_axis_set_config(axis, &config);
	hkl_holder_update(holder);
	HKL_ASSERT_DOUBLES_EQUAL(1./sqrt(2), holder->q.a, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(1./sqrt(2), holder->q.b, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., holder->q.c, HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(0., holder->q.d, HKL_EPSILON);

	return HKL_TEST_PASS;
}


/*
HKL_TEST_SUITE_FUNC(get_distance)
{
	HklAxes *axes1 = NULL;
	HklAxes *axes2 = NULL;
	unsigned int i;

	HklAxis *A, *B;

	HklVector axis_v = {{0, 0, 1}};

	axes1 = hkl_axes_new();
	A = hkl_axes_add_rotation(axes1, "omega", &axis_v);

	axes2 = hkl_axes_new();
	B = hkl_axes_add_rotation(axes2, "omega", &axis_v);

	A->config.current = 10 * HKL_DEGTORAD;
	A->config.consign = 10 * HKL_DEGTORAD;
	B->config.current =-10 * HKL_DEGTORAD;
	B->config.consign =-10 * HKL_DEGTORAD;

	// get_distance
	HKL_ASSERT_DOUBLES_EQUAL(20 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);

	A->config.current = 90 * HKL_DEGTORAD;
	B->config.current =-90 * HKL_DEGTORAD;
	HKL_ASSERT_DOUBLES_EQUAL(180 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(20 * HKL_DEGTORAD, hkl_axes_get_distance_consign(&axes1, &axes2), HKL_EPSILON);

	A->config.current = 120 * HKL_DEGTORAD;
	B->config.current =-150 * HKL_DEGTORAD;
	HKL_ASSERT_DOUBLES_EQUAL(90 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(20 * HKL_DEGTORAD, hkl_axes_get_distance_consign(&axes1, &axes2), HKL_EPSILON);

	A->config.current =-240 * HKL_DEGTORAD;
	B->config.current = 200 * HKL_DEGTORAD;
	HKL_ASSERT_DOUBLES_EQUAL(80 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(20 * HKL_DEGTORAD, hkl_axes_get_distance_consign(&axes1, &axes2), HKL_EPSILON);

	A->config.current = 200 * HKL_DEGTORAD;
	B->config.current = 240 * HKL_DEGTORAD;
	HKL_ASSERT_DOUBLES_EQUAL(40 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(20 * HKL_DEGTORAD, hkl_axes_get_distance_consign(&axes1, &axes2), HKL_EPSILON);

	A->config.current = -90 * HKL_DEGTORAD;
	B->config.current =-100 * HKL_DEGTORAD;
	HKL_ASSERT_DOUBLES_EQUAL(10 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(20 * HKL_DEGTORAD, hkl_axes_get_distance_consign(&axes1, &axes2), HKL_EPSILON);

	A->config.consign = 90 * HKL_DEGTORAD;
	B->config.consign =-90 * HKL_DEGTORAD;
	HKL_ASSERT_DOUBLES_EQUAL(10 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(180 * HKL_DEGTORAD, hkl_axes_get_distance_consign(&axes1, &axes2), HKL_EPSILON);

	A->config.consign = 120 * HKL_DEGTORAD;
	B->config.consign =-150 * HKL_DEGTORAD;
	HKL_ASSERT_DOUBLES_EQUAL(10 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(90 * HKL_DEGTORAD, hkl_axes_get_distance_consign(&axes1, &axes2), HKL_EPSILON);

	A->config.consign =-240 * HKL_DEGTORAD;
	B->config.consign = 200 * HKL_DEGTORAD;
	HKL_ASSERT_DOUBLES_EQUAL(10 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(80 * HKL_DEGTORAD, hkl_axes_get_distance_consign(&axes1, &axes2), HKL_EPSILON);

	A->config.consign = 200 * HKL_DEGTORAD;
	B->config.consign = 240 * HKL_DEGTORAD;
	HKL_ASSERT_DOUBLES_EQUAL(10 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(40 * HKL_DEGTORAD, hkl_axes_get_distance_consign(&axes1, &axes2), HKL_EPSILON);

	A->config.consign = -90 * HKL_DEGTORAD;
	B->config.consign =-100 * HKL_DEGTORAD;
	HKL_ASSERT_DOUBLES_EQUAL(10 * HKL_DEGTORAD, hkl_axes_get_distance(&axes1, &axes2), HKL_EPSILON);
	HKL_ASSERT_DOUBLES_EQUAL(10 * HKL_DEGTORAD, hkl_axes_get_distance_consign(&axes1, &axes2), HKL_EPSILON);

	for(i=0; i<axes1->axes->len; ++i)
		hkl_axis_free(axes1->axes->list[i]);
	for(i=0; i<axes2->axes->len; ++i)
		hkl_axis_free(axes2->axes->list[i]);

	hkl_axes_free(axes1);
	hkl_axes_free(axes2);

	return HKL_TEST_PASS;
}
*/

HKL_TEST_SUITE_BEGIN

HKL_TEST( new_copy );
HKL_TEST( add_rotation_axis );
HKL_TEST( update );

HKL_TEST_SUITE_END
