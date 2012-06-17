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
 * Copyright (C) 2003-2010 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#include <stdlib.h>
#include <math.h>
#include <string.h>

#include <hkl/hkl-macros.h>
#include <hkl/hkl-vector.h>
#include <hkl/hkl-matrix.h>
#include <hkl/hkl-quaternion.h>

/* public */
/**
 * hkl_quaternion_dup: (skip)
 * @self: 
 *
 * 
 *
 * Returns: 
 **/
HklQuaternion *hkl_quaternion_dup(const HklQuaternion* self)
{
	HklQuaternion *dup;

	dup = HKL_MALLOC(HklQuaternion);
	memcpy(dup, self, sizeof(*self));

	return dup;
}

/**
 * hkl_quaternion_free: (skip)
 * @self: 
 *
 * 
 **/
void hkl_quaternion_free(HklQuaternion *self)
{
	if(!self)
		return;

	free(self);
}

/**
 * hkl_quaternion_init:
 * @self: the #HklQuaternion to initialize
 * @a: the 1st element value
 * @b: the 2nd element value
 * @c: the 3rd element value
 * @d: the 4th element value
 *
 * initialize the four elements of an #HklQuaternion
 **/
void hkl_quaternion_init(HklQuaternion *self,
			 double a, double b, double c, double d)
{
	self->data[0] = a;
	self->data[1] = b;
	self->data[2] = c;
	self->data[3] = d;
}

/**
 * hkl_quaternion_fprintf:
 * @file: the file to send the #HklQuaternion into
 * @self: the #HklQuaternion to write into the file stream.
 *
 *  print an #HklQuaternion into a FILE stream
 **/
void hkl_quaternion_fprintf(FILE *file, HklQuaternion const *self)
{
	double const *Q;

	Q = self->data;
	fprintf(file, "<%f, %f, %f, %f>", Q[0], Q[1], Q[2], Q[3]);
}

/**
 * hkl_quaternion_init_from_vector:
 * @self: the #HklQuaternion to set
 * @v: the #HklVector used to set the self #HklQuaternion
 *
 * initialize an #HklQuaternion from an #HklVector
 **/
void hkl_quaternion_init_from_vector(HklQuaternion *self, HklVector const *v)
{
	self->data[0] = 0;
	memcpy(&self->data[1], &v->data[0], sizeof(v->data));
}

/**
 * hkl_quaternion_init_from_angle_and_axe:
 * @self: the #HklQuaternion to set
 * @angle: the angles of the rotation
 * @v: the axe of rotation
 *
 * initialize an #HklQuaternion from a vector and a angle.
 **/
void hkl_quaternion_init_from_angle_and_axe(HklQuaternion *self,
					    double angle, HklVector const *v)
{
	double norm;
	double c;
	double s;

	/* check that parameters are ok. */
	norm = hkl_vector_norm2(v);

	c = cos(angle / 2.);
	s = sin(angle / 2.) / norm;

	self->data[0] = c;
	self->data[1] = s * v->data[0];
	self->data[2] = s * v->data[1];
	self->data[3] = s * v->data[2];
}

/**
 * hkl_quaternion_cmp:
 * @self: the first #HklQuaternion
 * @q: the second #HklQuaternion
 *
 * compare two #HklQuaternion.
 *
 * Returns: #HKL_TRUE if both are equal, #HKL_FALSE otherwise.
 **/
int hkl_quaternion_cmp(HklQuaternion const *self, HklQuaternion const *q)
{
	unsigned int i;

	for (i=0;i<4;i++)
		if ( fabs(self->data[i] - q->data[i]) > HKL_EPSILON )
			return HKL_FALSE;
	return HKL_TRUE;
}

/**
 * hkl_quaternion_minus_quaternion:
 * @self: the #HklQuaternion to modify.
 * @q: the #HklQuaternion to substract
 *
 * substract two #HklQuaternions
 * Todo: test
 **/
void hkl_quaternion_minus_quaternion(HklQuaternion *self, const HklQuaternion *q)
{
	unsigned int i;

	for (i=0;i<4;i++)
		self->data[i] -= q->data[i];
}

/**
 * hkl_quaternion_times_quaternion:
 * @self: the #HklQuaternion to modify
 * @q: the #HklQuaternion to multiply by
 *
 * multiply two quaternions
 **/
void hkl_quaternion_times_quaternion(HklQuaternion *self, const HklQuaternion *q)
{
	HklQuaternion Tmp;
	double *Q;

	Tmp = *self;
	Q = Tmp.data;
	if (self == q){
		self->data[0] = Q[0]*Q[0] - Q[1]*Q[1] - Q[2]*Q[2] - Q[3]*Q[3];
		self->data[1] = Q[0]*Q[1] + Q[1]*Q[0] + Q[2]*Q[3] - Q[3]*Q[2];
		self->data[2] = Q[0]*Q[2] - Q[1]*Q[3] + Q[2]*Q[0] + Q[3]*Q[1];
		self->data[3] = Q[0]*Q[3] + Q[1]*Q[2] - Q[2]*Q[1] + Q[3]*Q[0];
	}else{
		double const *Q1 = q->data;
		self->data[0] = Q[0]*Q1[0] - Q[1]*Q1[1] - Q[2]*Q1[2] - Q[3]*Q1[3];
		self->data[1] = Q[0]*Q1[1] + Q[1]*Q1[0] + Q[2]*Q1[3] - Q[3]*Q1[2];
		self->data[2] = Q[0]*Q1[2] - Q[1]*Q1[3] + Q[2]*Q1[0] + Q[3]*Q1[1];
		self->data[3] = Q[0]*Q1[3] + Q[1]*Q1[2] - Q[2]*Q1[1] + Q[3]*Q1[0];
	}
}

/**
 * hkl_quaternion_norm2:
 * @self: the quaternion use to compute the norm
 *
 * compute the norm2 of an #HklQuaternion
 *
 * Returns: the self #hklquaternion norm
 **/
double hkl_quaternion_norm2(const HklQuaternion *self)
{
	double sum2 = 0;
	unsigned int i;
	for (i=0;i<4;i++)
		sum2 += self->data[i] *self->data[i];
	return sqrt(sum2);
}

/**
 * hkl_quaternion_conjugate:
 * @self: the #HklQuaternion to conjugate
 *
 * compute the conjugate of a quaternion
 **/
void hkl_quaternion_conjugate(HklQuaternion *self)
{
	unsigned int i;
	for (i=1;i<4;i++)
		self->data[i] = -self->data[i];
}

/**
 * hkl_quaternion_to_matrix:
 * @self: the #HklQuaternion use to compute the #HklMatrix
 * @m: the #HklMatrix return.
 *
 * Compute the rotation matrix of a Quaternion.
 *
 * compute the rotation matrix corresponding to the unitary quaternion.
 * \f$ q = a + b \cdot i + c \cdot j + d \cdot k \f$
 *
 * \f$
 * \left(
 *  \begin{array}{ccc}
 *    a^2+b^2-c^2-d^2 & 2bc-2ad         & 2ac+2bd\\
 *    2ad+2bc         & a^2-b^2+c^2-d^2 & 2cd-2ab\\
 *    2bd-2ac         & 2ab+2cd         & a^2-b^2-c^2+d^2
 *  \end{array}
 * \right)
 * \f$
 * Todo: optimize
 */
void hkl_quaternion_to_matrix(const HklQuaternion *self, HklMatrix *m)
{
	double const *Q;

	/* check that parameters are ok. */
	hkl_assert(fabs(hkl_quaternion_norm2(self) - 1) < HKL_EPSILON);

	Q = self->data;

	m->data[0][0] = Q[0]*Q[0] + Q[1]*Q[1] - Q[2]*Q[2] - Q[3]*Q[3];
	m->data[0][1] = 2 * (Q[1]*Q[2] - Q[0]*Q[3]);
	m->data[0][2] = 2 * (Q[0]*Q[2] + Q[1]*Q[3]);

	m->data[1][0] = 2 * (Q[0]*Q[3] + Q[1]*Q[2]);
	m->data[1][1] = Q[0]*Q[0] - Q[1]*Q[1] + Q[2]*Q[2] - Q[3]*Q[3];
	m->data[1][2] = 2 * (Q[2]*Q[3] - Q[0]*Q[1]);

	m->data[2][0] = 2 * (Q[1]*Q[3] - Q[0]*Q[2]);
	m->data[2][1] = 2 * (Q[0]*Q[1] + Q[2]*Q[3]);
	m->data[2][2] = Q[0]*Q[0] - Q[1]*Q[1] - Q[2]*Q[2] + Q[3]*Q[3];
}

/**
 * hkl_quaternion_to_angle_and_axe:
 * @self: The #HklQuaternion use to compute the angle and the roation axis.
 * @angle: the returned angle of the rotation.
 * @v: the returned axis of the rotation.
 *
 * compute the axe and angle of the unitary quaternion angle [-pi, pi]
 * if q is the (1, 0, 0, 0) quaternion return the (0,0,0) axe and a 0 angle
 */
void hkl_quaternion_to_angle_and_axe(HklQuaternion const *self,
				     double *angle, HklVector *v)
{
	double angle_2;
	double cos_angle_2;
	double sin_angle_2;

	/* check that parameters are ok. (norm must be equal to 1) */
	hkl_assert(fabs(hkl_quaternion_norm2(self) - 1) < HKL_EPSILON);

	/* compute the angle */
	cos_angle_2 = self->data[0];
	angle_2 = acos(cos_angle_2);
	*angle = 2 *angle_2;
	/* we want an angle between -pi, pi */
	if (*angle > M_PI) *angle -= 2 *M_PI;

	/* compute the axe */
	sin_angle_2 = sin(angle_2);
	if (fabs(sin_angle_2) > HKL_EPSILON) {
		/* compute the axe using the vector part of the unitary quaterninon */
		memcpy(v->data, &self->data[1], sizeof(v->data));
		hkl_vector_div_double(v, sin_angle_2);
	} else {
		*angle = 0;
		memset(v->data, 0, sizeof(v->data));
	}
}
