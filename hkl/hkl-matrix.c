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
 * Copyright (C) 2003-2020, 2022 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#include <math.h>                       // for cos, fabs, atan2, sin, asin
#include <stdio.h>                      // for fprintf, FILE
#include <stdlib.h>                     // for free
#include <string.h>                     // for memcpy
#include "hkl-macros-private.h"         // for HKL_MALLOC
#include "hkl-matrix-private.h"         // for _HklMatrix
#include "hkl-vector-private.h"         // for HklVector, etc
#include "hkl.h"                        // for HklMatrix, HKL_EPSILON, etc

/**
 * hkl_matrix_new: (skip)
 *
 * Returns: a new uninitialized HklMatrix
 */
HklMatrix *hkl_matrix_new()
{
	return g_new(HklMatrix, 1);
}

/**
 * hkl_matrix_new_full: (skip)
 * @m11: the matrix 11 value
 * @m12: the matrix 12 value
 * @m13: the matrix 13 value
 * @m21: the matrix 21 value
 * @m22: the matrix 22 value
 * @m23: the matrix 23 value
 * @m31: the matrix 31 value
 * @m32: the matrix 32 value
 * @m33: the matrix 33 value
 *
 * @todo test
 * Returns: a new HklMAtrix
 **/
HklMatrix *hkl_matrix_new_full(double m11, double m12, double m13,
			       double m21, double m22, double m23,
			       double m31, double m32, double m33)
{
	HklMatrix *self = hkl_matrix_new();
	hkl_matrix_init(self,
			m11, m12, m13,
			m21, m22, m23,
			m31, m32, m33);

	return self;
}

/**
 * hkl_matrix_new_euler:
 * @euler_x: the eulerian value along X
 * @euler_y: the eulerian value along Y
 * @euler_z: the eulerian value along Z
 *
 * Returns: Create a rotation #HklMatrix from three eulerians angles.
 **/
HklMatrix *hkl_matrix_new_euler(double euler_x, double euler_y, double euler_z)
{
	HklMatrix *self = hkl_matrix_new();
	hkl_matrix_init_from_euler(self, euler_x, euler_y, euler_z);

	return self;
}

/**
 * hkl_matrix_dup: (skip)
 * @self:
 *
 *
 *
 * Returns:
 **/
HklMatrix *hkl_matrix_dup(const HklMatrix* self)
{
	HklMatrix *dup = g_new(HklMatrix, 1);

        *dup = *self;

	return dup;
}

/**
 * hkl_matrix_free: (skip)
 * @self:
 *
 *
 **/
void hkl_matrix_free(HklMatrix *self)
{
	free(self);
}

/**
 * hkl_matrix_init:
 * @self: the #HklMatrix to initialize
 * @m11: the matrix 11 value
 * @m12: the matrix 12 value
 * @m13: the matrix 13 value
 * @m21: the matrix 21 value
 * @m22: the matrix 22 value
 * @m23: the matrix 23 value
 * @m31: the matrix 31 value
 * @m32: the matrix 32 value
 * @m33: the matrix 33 value
 *
 *
 **/
void hkl_matrix_init(HklMatrix *self,
		     double m11, double m12, double m13,
		     double m21, double m22, double m23,
		     double m31, double m32, double m33)
{
	double (*M)[3] = self->data;

	M[0][0] = m11, M[0][1] = m12, M[0][2] = m13;
	M[1][0] = m21, M[1][1] = m22, M[1][2] = m23;
	M[2][0] = m31, M[2][1] = m32, M[2][2] = m33;
}

/**
 * hkl_matrix_matrix_set: (skip)
 * @self: the this ptr
 * @m: the matrix to set
 *
 * @todo test
 **/
void hkl_matrix_matrix_set(HklMatrix *self, const HklMatrix *m)
{
	if (self == m)
		return;

	memcpy(self->data, m->data, sizeof(double) * 9);
}

/**
 * hkl_matrix_get:
 * @self: the this ptr
 * @i: the i coordinate
 * @j: the j coordinate
 *
 * @todo test
 * Return value: the Mij value
 **/
double hkl_matrix_get(const HklMatrix *self, unsigned int i, unsigned int j)
{
	return self->data[i][j];
}

/**
 * hkl_matrix_fprintf:
 * @file: the FILE stream
 * @self: the #HklMatrix to print into the file stream
 *
 * printf an #HklMatrix into a FILE stream.
 **/
void hkl_matrix_fprintf(FILE *file, const HklMatrix *self)
{
	double const (*M)[3] = self->data;

	fprintf(file, "|%f, %f, %f|\n", M[0][0], M[0][1], M[0][2]);
	fprintf(file, "|%f, %f, %f|\n", M[1][0], M[1][1], M[1][2]);
	fprintf(file, "|%f, %f, %f|\n", M[2][0], M[2][1], M[2][2]);
}

/**
 * hkl_matrix_init_from_two_vector:
 * @self: The #HklMatrix to initialize
 * @v1: the first #HklVector
 * @v2: the second #HklVector
 *
 * Create an #HklMatrix which represent a direct oriented base of the space
 * the first row correspond to the |v1|, the second row |v2| and the last one
 * is |v1 ^ v2|
 **/
void hkl_matrix_init_from_two_vector(HklMatrix *self,
				     const HklVector *v1, const HklVector *v2)
{
	HklVector x, y, z;
	double (*M)[3] = self->data;

	x = *v1;
	hkl_vector_normalize(&x);

	z = *v1;
	hkl_vector_vectorial_product(&z, v2);
	hkl_vector_normalize(&z);

	y = z;
	hkl_vector_vectorial_product(&y, &x);

	M[0][0] = x.data[0], M[0][1] = y.data[0], M[0][2] = z.data[0];
	M[1][0] = x.data[1], M[1][1] = y.data[1], M[1][2] = z.data[1];
	M[2][0] = x.data[2], M[2][1] = y.data[2], M[2][2] = z.data[2];
}

/**
 * hkl_matrix_init_from_euler:
 * @self: the #HklMatrix to initialize
 * @euler_x: the eulerian value along X
 * @euler_y: the eulerian value along Y
 * @euler_z: the eulerian value along Z
 *
 * Create a rotation #HklMatrix from three eulerians angles.
 **/
void hkl_matrix_init_from_euler(HklMatrix *self,
				double euler_x, double euler_y, double euler_z)
{
	double (*M)[3] = self->data;

	double A = cos(euler_x);
	double B = sin(euler_x);
	double C = cos(euler_y);
	double D = sin(euler_y);
	double E = cos(euler_z);
	double F = sin(euler_z);
	double AD = A *D;
	double BD = B *D;

	M[0][0] = C*E;
	M[0][1] =-C*F;
	M[0][2] = D;
	M[1][0] = BD *E + A *F;
	M[1][1] =-BD *F + A *E;
	M[1][2] =-B *C;
	M[2][0] =-AD *E + B *F;
	M[2][1] = AD *F + B *E;
	M[2][2] = A *C;
}

/**
 * hkl_matrix_to_euler:
 * @self: the rotation #HklMatrix use to compute the eulerians angles
 * @euler_x: the eulerian value along X
 * @euler_y: the eulerian value along Y
 * @euler_z: the eulerian value along Z
 *
 * compute the three eulerians values for a given rotation #HklMatrix
 **/
void hkl_matrix_to_euler(const HklMatrix *self,
			 double *euler_x, double *euler_y, double *euler_z)
{
	double tx, ty;
	double C;
	double const (*M)[3] = self->data;

	*euler_y = asin( self->data[0][2] );      /*Calculate Y-axis angle */
	C = cos( *euler_y );
	if (fabs(C) > HKL_EPSILON) {
		/*Gimball lock? */
		tx       =  M[2][2] / C; /*No, so get X-axis angle */
		ty       = -M[1][2] / C;
		*euler_x = atan2( ty, tx );
		tx       =  M[0][0] / C; /*Get Z-axis angle */
		ty       = -M[0][1] / C;
		*euler_z = atan2( ty, tx );
	} else {
		/*Gimball lock has occurred */
		*euler_x = 0.;              /*Set X-axis angle to zero */
		tx       =  M[1][1];    /*And calculate Z-axis angle */
		ty       =  M[1][0];
		*euler_z = atan2( ty, tx );
	}
}

/**
 * hkl_matrix_cmp:
 * @self: the first #HklMatrix
 * @m: the #HklMatrix to compare with
 *
 * compare two #HklMatrix.
 *
 * Returns: return TRUE if | self - m | > HKL_EPSILON
 **/
int hkl_matrix_cmp(const HklMatrix *self, const HklMatrix *m)
{
	unsigned int i;
	unsigned int j;
	for(i=0;i<3;i++)
		for(j=0;j<3;j++)
			if( fabs(self->data[i][j] - m->data[i][j]) > HKL_EPSILON )
				return FALSE;
	return TRUE;
}


/**
 * hkl_matrix_times_matrix:
 * @self: the #HklMatrix to modify
 * @m: the #HklMatrix to multiply by
 *
 * compute the matrix multiplication self = self * m
 **/
void hkl_matrix_times_matrix(HklMatrix *self, const HklMatrix *m)
{
	HklMatrix const tmp = *self;
	double (*M)[3] = self->data;
	double const (*Tmp)[3] = tmp.data;
	double const (*M1)[3];
	if (self == m)
		M1 = tmp.data;
	else
		M1 = m->data;

	M[0][0] = Tmp[0][0]*M1[0][0] + Tmp[0][1]*M1[1][0] + Tmp[0][2]*M1[2][0];
	M[0][1] = Tmp[0][0]*M1[0][1] + Tmp[0][1]*M1[1][1] + Tmp[0][2]*M1[2][1];
	M[0][2] = Tmp[0][0]*M1[0][2] + Tmp[0][1]*M1[1][2] + Tmp[0][2]*M1[2][2];

	M[1][0] = Tmp[1][0]*M1[0][0] + Tmp[1][1]*M1[1][0] + Tmp[1][2]*M1[2][0];
	M[1][1] = Tmp[1][0]*M1[0][1] + Tmp[1][1]*M1[1][1] + Tmp[1][2]*M1[2][1];
	M[1][2] = Tmp[1][0]*M1[0][2] + Tmp[1][1]*M1[1][2] + Tmp[1][2]*M1[2][2];

	M[2][0] = Tmp[2][0]*M1[0][0] + Tmp[2][1]*M1[1][0] + Tmp[2][2]*M1[2][0];
	M[2][1] = Tmp[2][0]*M1[0][1] + Tmp[2][1]*M1[1][1] + Tmp[2][2]*M1[2][1];
	M[2][2] = Tmp[2][0]*M1[0][2] + Tmp[2][1]*M1[1][2] + Tmp[2][2]*M1[2][2];
}


/**
 * hkl_matrix_times_vector:
 * @self: the #HklMatrix use to multiply the #HklVector
 * @v: the #HklVector multiply by the #HklMatrix
 *
 * multiply an #HklVector by an #HklMatrix
 **/
void hkl_matrix_times_vector(const HklMatrix *self, HklVector *v)
{
	HklVector tmp;
	double *Tmp;
	double *V = v->data;
	double const (*M)[3] = self->data;

	tmp = *v;
	Tmp = tmp.data;

	V[0] = Tmp[0]*M[0][0] + Tmp[1]*M[0][1] + Tmp[2]*M[0][2];
	V[1] = Tmp[0]*M[1][0] + Tmp[1]*M[1][1] + Tmp[2]*M[1][2];
	V[2] = Tmp[0]*M[2][0] + Tmp[1]*M[2][1] + Tmp[2]*M[2][2];
}


/**
 * hkl_matrix_transpose:
 * @self: the #HklMatrix to transpose
 *
 * transpose an #HklMatrix
 **/
void hkl_matrix_transpose(HklMatrix *self)
{
#define SWAP(a, b) {double tmp=a; a=b; b=tmp;}
	SWAP(self->data[1][0], self->data[0][1]);
	SWAP(self->data[2][0], self->data[0][2]);
	SWAP(self->data[2][1], self->data[1][2]);
}

/**
 * hkl_matrix_det:
 * @self: the #HklMatrix use to compute the determinant
 *
 * compute the determinant of an #HklMatrix
 *
 * Returns: the determinant of the self #HklMatrix
 * Todo: test
 **/
double hkl_matrix_det(const HklMatrix *self)
{
	double det;
	double const (*M)[3] = self->data;

	det  =  M[0][0] * (M[1][1] * M[2][2] - M[2][1] * M[1][2]);
	det += -M[0][1] * (M[1][0] * M[2][2] - M[2][0] * M[1][2]);
	det +=  M[0][2] * (M[1][0] * M[2][1] - M[2][0] * M[1][1]);

	return det;
}

/**
 * hkl_matrix_solve:
 * @self: The #HklMatrix of the system
 * @x: the #HklVector to compute.
 * @b: the #hklVector of the system to solve.
 *
 * solve the system self . X = b
 *
 * Returns: -1 if the système has no solution, 0 otherwise.
 * Todo: test
 **/
int hkl_matrix_solve(const HklMatrix *self, HklVector *x, const HklVector *b)
{
	double det;
	double const (*M)[3] = self->data;
	double *X = x->data;
	double const *B = b->data;

	det = hkl_matrix_det(self);
	if (fabs(det) < HKL_EPSILON)
		return -1;
	else {
		X[0] =   B[0] * (M[1][1]*M[2][2] - M[1][2]*M[2][1]);
		X[0] += -B[1] * (M[0][1]*M[2][2] - M[0][2]*M[2][1]);
		X[0] +=  B[2] * (M[0][1]*M[1][2] - M[0][2]*M[1][1]);

		X[1] =  -B[0] * (M[1][0]*M[2][2] - M[1][2]*M[2][0]);
		X[1] +=  B[1] * (M[0][0]*M[2][2] - M[0][2]*M[2][0]);
		X[1] += -B[2] * (M[0][0]*M[1][2] - M[0][2]*M[1][0]);

		X[2] =   B[0] * (M[1][0]*M[2][1] - M[1][1]*M[2][0]);
		X[2] += -B[1] * (M[0][0]*M[2][1] - M[0][1]*M[2][0]);
		X[2] +=  B[2] * (M[0][0]*M[1][1] - M[0][1]*M[1][0]);

		hkl_vector_div_double(x, det);
	}
	return 0;
}

/**
 * hkl_matrix_is_null:
 * @self: the #HklMatrix to test
 *
 * is all #hklMatrix elementes bellow #HKL_EPSILON
 *
 * Returns: TRUE if the self #HklMatrix is null
 * Todo: test
 **/
int hkl_matrix_is_null(const HklMatrix *self)
{
	unsigned int i;
	unsigned int j;
	for (i=0;i<3;i++)
		for (j=0;j<3;j++)
			if ( fabs(self->data[i][j]) > HKL_EPSILON )
				return FALSE;
	return TRUE;
}

/**
 * hkl_matrix_div_double: (skip)
 * @self: the #HklMatrix to divide.
 * @d: constant use to divide the #HklMatrix
 *
 * divide an #HklMatrix by a constant.
 **/
void hkl_matrix_div_double(HklMatrix *self, double d)
{
	unsigned int i;
        unsigned int j;

	for (i=0;i<3;i++)
                for(j=0; j<3; ++j)
                        self->data[i][j] /= d;
}

/**
 * hkl_matrix_inv:
 * @self: The #HklMatrix of the system
 *
 * Returns: -1 if the HklMatrix can not be inverted, 0 otherwise.
 * Todo: test
 **/
int hkl_matrix_inv(const HklMatrix *self, HklMatrix *inv)
{
	double det;

	double const (*M)[3] = self->data;
        double (*Inv)[3] = inv->data;

	det = hkl_matrix_det(self);
	if (fabs(det) < HKL_EPSILON)
		return -1;
	else {
                Inv[0][0] = M[1][1]*M[2][2] - M[1][2]*M[2][1];
                Inv[0][1] = - (M[0][1]*M[2][2] - M[0][2]*M[2][1]);
                Inv[0][2] = M[0][1]*M[1][2] - M[0][2]*M[1][1];

                Inv[1][0] = - (M[1][0]*M[2][2] - M[1][2]*M[2][0]);
		Inv[1][1] =  M[0][0]*M[2][2] - M[0][2]*M[2][0];
		Inv[1][2] = - (M[0][0]*M[1][2] - M[0][2]*M[1][0]);

		Inv[2][0] = M[1][0]*M[2][1] - M[1][1]*M[2][0];
		Inv[2][1] = - (M[0][0]*M[2][1] - M[0][1]*M[2][0]);
		Inv[2][2] = M[0][0]*M[1][1] - M[0][1]*M[1][0];

		hkl_matrix_div_double(inv, det);
	}
	return 0;
}
