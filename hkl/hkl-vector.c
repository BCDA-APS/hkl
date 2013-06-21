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
 * Copyright (C) 2003-2013 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#include <stdlib.h>
#include <string.h>

#include <gsl/gsl_math.h>

#include "hkl-vector.h"
#include "hkl-matrix-private.h"
#include "hkl-quaternion-private.h"

/**
 * hkl_vector_dup: (skip)
 * @self: the HklVector to copy
 *
 * Copy an HklVector
 *
 * Returns: A copy of self which need to be free using hkl_vector_free
 **/
HklVector* hkl_vector_dup (const HklVector* self) {
        HklVector* dup;

	dup = HKL_MALLOC(HklVector);
        memcpy(dup, self, sizeof (HklVector));
        return dup;
}

/**
 * hkl_vector_free: (skip)
 * @self:
 *
 * delete an HklVector struct
 **/
void hkl_vector_free (HklVector* self) {
	free(self);
}

/**
 * hkl_vector_init:
 * @self: the #HklVector to initialize.
 * @x: the first coordinate value
 * @y: the second coordinate value
 * @z: the third coordinate value
 *
 * initialize an #HklVector
 **/
void hkl_vector_init(HklVector *self, double x, double y, double z)
{
	self->data[0] = x;
	self->data[1] = y;
	self->data[2] = z;
}

/**
 * hkl_vector_fprintf: (skip)
 * @file: the stream to print into
 * @self: the #HklVector to print.
 *
 * print an #HklVector into a stream
 **/
void hkl_vector_fprintf(FILE *file, const HklVector *self)
{
	fprintf(file, "|%f, %f, %f|", self->data[0], self->data[1], self->data[2]);
}

/**
 * hkl_vector_cmp: (skip)
 * @self: the first vector
 * @vector: th vector to compare with
 *
 * compare two #HklVector. this comparison use HKL_EPSILON
 * to do the comparison.
 *
 * Returns: HKL_FALSE if both are equals, HKL_TRUE otherwise.
 **/
int hkl_vector_cmp(const HklVector *self, const HklVector *vector)
{
	unsigned int i;

	for (i=0; i<3; i++)
		if ( fabs(self->data[i] - vector->data[i]) > HKL_EPSILON )
			return HKL_TRUE;
	return HKL_FALSE;
}

/**
 * hkl_vector_is_opposite: (skip)
 * @self:
 * @vector:
 *
 * Check if two vectors are oposite.
 *
 * Returns: HKL_TRUE is vector are oposite vectors.
 **/
int hkl_vector_is_opposite(const HklVector *self, const HklVector *vector)
{
	unsigned int i;

	for (i=0; i<3; i++)
		if ( fabs(self->data[i] + vector->data[i]) > HKL_EPSILON )
			return HKL_FALSE;
	return HKL_TRUE;
}

/**
 * hkl_vector_add_vector: (skip)
 * @self: the modified #HklVector
 * @vector: the #hklvector to add
 *
 * add an #HklVector to another one.
 **/
void hkl_vector_add_vector(HklVector *self, const HklVector *vector)
{
	unsigned int i;
	for (i=0;i<3;i++)
		self->data[i] += vector->data[i];
}

/**
 * hkl_vector_minus_vector: (skip)
 * @self: the modified #HklVector
 * @vector: the #hklvector to substract
 *
 * substract an #HklVector to another one.
 **/
void hkl_vector_minus_vector(HklVector *self, const HklVector *vector)
{
	unsigned int i;
	for (i=0;i<3;i++)
		self->data[i] -= vector->data[i];
}

/**
 * hkl_vector_div_double: (skip)
 * @self: the #HklVector to divide.
 * @d: constant use to divide the #HklVector
 *
 * divide an #HklVector by constant.
 **/
void hkl_vector_div_double(HklVector *self, const double d)
{
	unsigned int i;
	for (i=0;i<3;i++)
		self->data[i] /= d;
}

/**
 * hkl_vector_times_double: (skip)
 * @self: the #HklVector to modify
 * @d: the multiply factor
 *
 * multiply an #HklVector by a constant value.
 **/
void hkl_vector_times_double(HklVector *self, const double d)
{
	unsigned int i;
	for (i=0;i<3;i++)
		self->data[i] *= d;
}

/**
 * hkl_vector_times_vector: (skip)
 * @self: the #HklVector to modify
 * @vector: the #HklVector use to modify the first one
 *
 * multiply an #HklVector by another one. This method multiply
 * coordinate by coordinate.
 **/
void hkl_vector_times_vector(HklVector *self, const HklVector *vector)
{
	unsigned int i;
	for (i=0;i<3;i++)
		self->data[i] *= vector->data[i];
}

/**
 * hkl_vector_times_matrix: (skip)
 * @self: the #HklVector to multiply
 * @m: the #HklMatrix use to multiply the #HklVector
 *
 * multiply an #HklVector by an #HklMatrix.
 * compute v'= M . v
 **/
void hkl_vector_times_matrix(HklVector *self, const HklMatrix *m)
{
	HklVector tmp;
	tmp = *self;

	self->data[0] = tmp.data[0] *m->data[0][0] + tmp.data[1] *m->data[1][0] + tmp.data[2] *m->data[2][0];
	self->data[1] = tmp.data[0] *m->data[0][1] + tmp.data[1] *m->data[1][1] + tmp.data[2] *m->data[2][1];
	self->data[2] = tmp.data[0] *m->data[0][2] + tmp.data[1] *m->data[1][2] + tmp.data[2] *m->data[2][2];
}

/**
 * hkl_vector_sum: (skip)
 * @self: the #HklVector to sum.
 *
 * compute the #HklVector sum of all its elements.
 *
 * Returns: the sum of all elements.
 **/
double hkl_vector_sum(const HklVector *self)
{
	return self->data[0] + self->data[1] + self->data[2];
}

/**
 * hkl_vector_scalar_product: (skip)
 * @self: the first #HklVector
 * @vector: the second #HklVector
 *
 * compute the scalar product of two #HklVector
 *
 * Returns: the scalar product.
 **/
double hkl_vector_scalar_product(const HklVector *self, const HklVector *vector)
{
	unsigned int i;
	double scalar = 0;

	for (i=0;i<3;i++)
		scalar += self->data[i] *vector->data[i];
	return scalar;
}

/**
 * hkl_vector_vectorial_product: (skip)
 * @self: the first #HklVector (modify)
 * @vector: the second #HklVector
 *
 * compute the vectorial product of two vectors
 **/
void hkl_vector_vectorial_product(HklVector *self, const HklVector *vector)
{
	HklVector tmp;

	tmp = *self;
	self->data[0] = tmp.data[1] * vector->data[2] - tmp.data[2] * vector->data[1];
	self->data[1] = tmp.data[2] * vector->data[0] - tmp.data[0] * vector->data[2];
	self->data[2] = tmp.data[0] * vector->data[1] - tmp.data[1] * vector->data[0];
}


/**
 * hkl_vector_angle: (skip)
 * @self: the fist #HklVector
 * @vector: the second #HklVector
 *
 * compute the angles beetween two #HklVector
 *
 * Returns: the return value is in beetween [0, pi]
 **/
double hkl_vector_angle(const HklVector *self, const HklVector *vector)
{
	double angle;
	double cos_angle;
	double norm;
	double norm_self;
	double norm_vector;

	norm_self = hkl_vector_norm2(self);
	norm_vector = hkl_vector_norm2(vector);

	if (norm_self < HKL_EPSILON || norm_vector < HKL_EPSILON)
		return 0.0;

	norm = norm_self * norm_vector;

	cos_angle = hkl_vector_scalar_product(self, vector) / norm;

	/* problem with round */
	if (cos_angle >= 1 )
		angle = 0;
	else
		if (cos_angle <= -1 )
			angle = M_PI;
		else
			angle = acos(cos_angle);
	return angle;
}

/**
 * hkl_vector_oriented_angle: (skip)
 * @self: the first #HklVector
 * @vector: the second #HklVector
 * @ref: the reference #HklVector
 *
 * compute the angles beetween two #HklVector and use
 * a reference #HklVector to orientate the space. That's
 * way the return value can be in beetween [-pi, pi].
 * the (self, vector, ref) is a right oriented base.
 *
 * Returns: the angles [-pi, pi]
 **/
double hkl_vector_oriented_angle(const HklVector *self,
				 const HklVector *vector,
				 const HklVector *ref)
{
	double angle;
	HklVector tmp;
	HklVector ref_u;

	angle = hkl_vector_angle(self, vector);
	tmp = *self;
	hkl_vector_vectorial_product(&tmp, vector);
	hkl_vector_normalize(&tmp);
	ref_u = *ref;
	hkl_vector_normalize(&ref_u);
	if (hkl_vector_is_opposite(&tmp, &ref_u))
		angle = -angle;
	return angle;
}
/**
 * hkl_vector_oriented_angle_points: (skip)
 * @self: the first point
 * @p2: the second point
 * @p3: the third point
 * @ref: the reference #HklVector
 *
 * compute the angles beetween three points (p1, p2, p3) and use
 * a reference #HklVector to orientate the space. That's
 * way the return value can be in beetween [-pi, pi].
 * the (self, vector, ref) is a right oriented base.
 *
 * Returns: the angles [-pi, pi]
 **/
double hkl_vector_oriented_angle_points(const HklVector *self,
					const HklVector *p2,
					const HklVector *p3,
					const HklVector *ref)
{
	HklVector v1;
	HklVector v2;

	v1 = *self;
	v2 = *p3;
	hkl_vector_minus_vector(&v1, p2);
	hkl_vector_minus_vector(&v2, p2);
	return hkl_vector_oriented_angle(&v1, &v2, ref);
}

/**
 * hkl_vector_normalize: (skip)
 * @self: the #HklVector to normalize
 *
 * normalize a hkl_vector
 *
 * Returns: HKL_TRUE if the #HklVector can be normalized, HKL_FALSE otherwise
 **/
int hkl_vector_normalize(HklVector *self)
{
	double norm = hkl_vector_norm2(self);
	if ( norm <= HKL_EPSILON )
		return HKL_FALSE;

	hkl_vector_div_double(self, norm);

	return HKL_TRUE;
}

/**
 * hkl_vector_is_colinear: (skip)
 * @self: the first #HklVector
 * @vector: the second #HklVector
 *
 * check if two #HklVector are colinears
 *
 * Returns: HKL_TRUE if both are colinear.
 **/
int hkl_vector_is_colinear(const HklVector *self, const HklVector *vector)
{
	int is_colinear = 0;
	HklVector tmp = *self;

	hkl_vector_vectorial_product(&tmp, vector);
	if (hkl_vector_norm2(&tmp) < HKL_EPSILON)
		is_colinear = 1;

	return is_colinear;
}


/**
 * hkl_vector_randomize: (skip)
 * @self: the #HklVector to randomize
 *
 * initialize a vector with random values.
 * coordinates range [-1, 1]
 */
void hkl_vector_randomize(HklVector *self)
{
	self->data[0] = -1 + 2 *rand()/(RAND_MAX+1.0);
	self->data[1] = -1 + 2 *rand()/(RAND_MAX+1.0);
	self->data[2] = -1 + 2 *rand()/(RAND_MAX+1.0);
}

/**
 * hkl_vector_randomize_vector: (skip)
 * @self: the #HklVector to randomize
 * @vector: the #HklVector result to avoid
 *
 * randomize an #HklVector an be sure that it is not equal
 * to the #HklVector vector.
 **/
void hkl_vector_randomize_vector(HklVector *self, const HklVector *vector)
{
	do
		hkl_vector_randomize(self);
	while (!hkl_vector_cmp(self, vector));
}

/**
 * hkl_vector_randomize_vector_vector: (skip)
 * @self: the #HklVector to randomize
 * @vector1: the first #HklVector solution to avoid
 * @vector2: the second #HklVector solution to avoid
 *
 * randomize an #HklVector an be sure that it is not equal
 * to the #HklVector vector1 and vector2.
 *
 **/
void hkl_vector_randomize_vector_vector(HklVector *self,
					const HklVector *vector1,
					const HklVector *vector2)
{
	do
		hkl_vector_randomize(self);
	while (!hkl_vector_cmp(self, vector1) || !hkl_vector_cmp(self, vector2));
}

/**
 * hkl_vector_rotated_around_vector: (skip)
 * @self: the #HklVector to rotate
 * @axe: the axe of rotation
 * @angle: the angle of the rotation
 *
 * rotate a vector around another one with a given angle.
 **/
void hkl_vector_rotated_around_vector(HklVector *self,
				      const HklVector *axe, double angle)
{
	double c = cos(angle);
	double s = sin(angle);
	HklVector axe_n;
	HklVector tmp;

	axe_n = *axe;
	hkl_vector_normalize(&axe_n);

	tmp = *self;

	self->data[0]  = (c + (1 - c) * axe_n.data[0] * axe_n.data[0])                     * tmp.data[0];
	self->data[0] += ((1 - c)     * axe_n.data[0] * axe_n.data[1] - axe_n.data[2] * s) * tmp.data[1];
	self->data[0] += ((1 - c)     * axe_n.data[0] * axe_n.data[2] + axe_n.data[1] * s) * tmp.data[2];

	self->data[1]  = ((1 - c)     * axe_n.data[0] * axe_n.data[1] + axe_n.data[2] * s) * tmp.data[0];
	self->data[1] += (c + (1 - c) * axe_n.data[1] * axe_n.data[1])                     * tmp.data[1];
	self->data[1] += ((1 - c)     * axe_n.data[1] * axe_n.data[2] - axe_n.data[0] * s) * tmp.data[2];

	self->data[2]  = ((1 - c)     * axe_n.data[0] * axe_n.data[2] - axe_n.data[1] * s) * tmp.data[0];
	self->data[2] += ((1 - c)     * axe_n.data[1] * axe_n.data[2] + axe_n.data[0] * s) * tmp.data[1];
	self->data[2] += (c + (1 - c) * axe_n.data[2] * axe_n.data[2])                     * tmp.data[2];
}

/**
 * hkl_vector_norm2: (skip)
 * @self: the #hklvector use to compute the norm2
 *
 * compute the norm2 of an #HklVector
 *
 * Returns: the sqrt(|v|)
 **/
double hkl_vector_norm2(const HklVector *self)
{
	return sqrt(self->data[0] * self->data[0]
		    + self->data[1] * self->data[1]
		    + self->data[2] * self->data[2]);
}

/**
 * hkl_vector_rotated_quaternion: (skip)
 * @self: the #HklVector to rotate
 * @qr: the #HklQuaternion use to rotate the vector
 *
 * rotate an #HklVector using an #HklQuaternion.
 **/
void hkl_vector_rotated_quaternion(HklVector *self, const HklQuaternion *qr)
{
	double v1 = self->data[0];
	double v2 = self->data[1];
	double v3 = self->data[2];
	double a = qr->data[0];
	double b = qr->data[1];
	double c = qr->data[2];
	double d = qr->data[3];

	double t2 =   a*b;
	double t3 =   a*c;
	double t4 =   a*d;
	double t5 =  -b*b;
	double t6 =   b*c;
	double t7 =   b*d;
	double t8 =  -c*c;
	double t9 =   c*d;
	double t10 = -d*d;

	self->data[0] = 2*( (t8 + t10)*v1 + (t6 -  t4)*v2 + (t3 + t7)*v3 ) + v1;
	self->data[1] = 2*( (t4 +  t6)*v1 + (t5 + t10)*v2 + (t9 - t2)*v3 ) + v2;
	self->data[2] = 2*( (t7 -  t3)*v1 + (t2 +  t9)*v2 + (t5 + t8)*v3 ) + v3;
}

/**
 * hkl_vector_rotated_around_line: (skip)
 * @self: the point to rotate around a line
 * @angle: the angle of the rotation
 * @c1: the fist point of the line
 * @c2: the second point of the line
 *
 * This method rotate a point around a line defined by two points
 * of a certain amount of angle. The rotation is right handed.
 * this mean that c2 - c1 gives the direction of the rotation.
 **/
void hkl_vector_rotated_around_line(HklVector *self, double angle,
				    const HklVector *c1, const HklVector *c2)
{
	HklVector axis;

	if (!self || !c1 || !c2 || fabs(angle) < HKL_EPSILON)
		return;

	axis = *c2;
	hkl_vector_minus_vector(&axis, c1);
	/* the c2 - c1 vector must be non null */

	hkl_vector_minus_vector(self, c1);
	hkl_vector_rotated_around_vector(self, &axis, angle);
	hkl_vector_add_vector(self, c1);
}

/**
 * hkl_vector_is_null: (skip)
 * @self: the #hklvector to check
 *
 * check if all the coordinates of an #HklVector are null.
 *
 * Returns: HKl_TRUE if all |elements| are below HKL_EPSILON, HKl_FALSE otherwise
 *
 * Todo: test
 */
int hkl_vector_is_null(const HklVector *self)
{
	unsigned int i;
	for (i=0; i<3; i++)
		if ( fabs(self->data[i]) > HKL_EPSILON )
			return HKL_FALSE;
	return HKL_TRUE;
}

/**
 * hkl_vector_project_on_plan: (skip)
 * @self: the vector to project
 * @normal: the normal of the plane.
 *
 * project an #HklVector on a plan of normal which contain
 * the origin [0, 0, 0]
 *
 **/
void hkl_vector_project_on_plan(HklVector *self,
				const HklVector *normal)
{
	HklVector tmp;

	if(!self || !normal)
		return;

	tmp = *normal;
	hkl_vector_normalize(&tmp);
	hkl_vector_times_double(&tmp, hkl_vector_scalar_product(self, &tmp));
	hkl_vector_minus_vector(self, &tmp);
}

/**
 * hkl_vector_project_on_plan_with_point: (skip)
 * @self: the vector to project (modify)
 * @normal: the normal of the plane.
 * @point: a point of the plan.
 *
 * project an #HklVector on a plan of normal #normal which contain #point.
 **/
void hkl_vector_project_on_plan_with_point(HklVector *self,
					   const HklVector *normal,
					   const HklVector *point)
{
	HklVector tmp;
	double d1, d2;

	if(!self || !normal || !point)
		return;

	tmp = *normal;
	hkl_vector_normalize(&tmp);
	d1 = hkl_vector_scalar_product(self, &tmp);
	d2 = hkl_vector_scalar_product(point, &tmp);
	hkl_vector_times_double(&tmp, d1 - d2);
	hkl_vector_minus_vector(self, &tmp);
}
