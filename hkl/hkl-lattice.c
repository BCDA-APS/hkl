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
 * Copyright (C) 2003-2014 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#include <math.h>                       // for cos, sin, M_PI, atan2, sqrt
#include <stdio.h>                      // for fprintf, FILE
#include <stdlib.h>                     // for NULL, free
#include "hkl-lattice-private.h"        // for _HklLattice
#include "hkl-macros-private.h"         // for HKL_MALLOC
#include "hkl-matrix-private.h"         // for _HklMatrix
#include "hkl-parameter-private.h"      // for hkl_parameter_init_copy, etc
#include "hkl-unit-private.h"           // for hkl_unit_length_nm, etc
#include "hkl-vector-private.h"         // for hkl_vector_angle, etc
#include "hkl.h"                        // for HklLattice, etc

/* private */

static double convert_to_default(const HklParameter *p, double value, HklUnitEnum unit_type)
{
	switch(unit_type){
	case HKL_UNIT_DEFAULT:
		return value;
	case HKL_UNIT_USER:
		return value / hkl_unit_factor(p->unit, p->punit);
	}
}

static int check_lattice_param(double a, double b, double c,
			       double alpha, double beta, double gamma,
			       GError **error)
{
	hkl_error (error == NULL || *error == NULL);

	double D = 1. - cos(alpha)*cos(alpha) - cos(beta)*cos(beta)
		- cos(gamma)*cos(gamma) + 2. * cos(alpha)*cos(beta)*cos(gamma);

	if (D < 0.){
		g_set_error(error,
			    HKL_LATTICE_ERROR,
			    HKL_LATTICE_CHECK_LATTICE,
			    "these lattice parameters are not valid, check alpha, beta and gamma");
		return FALSE;
	}else
		return TRUE;
}

/* public */

/**
 * hkl_lattice_new:
 * @a: the length of the a parameter
 * @b: the length of the b parameter
 * @c: the length of the c parameter
 * @alpha: the angle between b and c (radian)
 * @beta: the angle between a and c (radian)
 * @gamma: the angle between a and b (radian)
 * @error: return location for a GError, or NULL
 *
 * constructor
 *
 * Returns: a new HklLattice
 **/
HklLattice *hkl_lattice_new(double a, double b, double c,
			    double alpha, double beta, double gamma,
			    GError **error)
{
	HklLattice *self = NULL;

	hkl_error (error == NULL || *error == NULL);

	if(!check_lattice_param(a, b, c, alpha, beta, gamma, error))
	{
		g_assert (error == NULL || *error != NULL);
		return FALSE;
	}
	g_assert (error == NULL || *error == NULL);

	self = HKL_MALLOC(HklLattice);

	self->a = hkl_parameter_new("a", 0, a, a+10,
				    TRUE, TRUE,
				    &hkl_unit_length_nm,
				    &hkl_unit_length_nm);
	self->b = hkl_parameter_new("b", 0, b, b+10,
				    TRUE, TRUE,
				    &hkl_unit_length_nm,
				    &hkl_unit_length_nm);
	self->c = hkl_parameter_new("c", 0, c, c+10,
				    TRUE, TRUE,
				    &hkl_unit_length_nm,
				    &hkl_unit_length_nm);
	self->alpha = hkl_parameter_new("alpha", -M_PI, alpha, M_PI,
					TRUE, TRUE,
					&hkl_unit_angle_rad,
					&hkl_unit_angle_deg);
	self->beta = hkl_parameter_new("beta", -M_PI, beta, M_PI,
				       TRUE, TRUE,
				       &hkl_unit_angle_rad,
				       &hkl_unit_angle_deg);
	self->gamma = hkl_parameter_new("gamma", -M_PI, gamma, M_PI,
					TRUE, TRUE,
					&hkl_unit_angle_rad,
					&hkl_unit_angle_deg);
	return self;
}

/**
 * hkl_lattice_new_copy: (skip)
 * @self:
 *
 * copy constructor
 *
 * Returns:
 **/
HklLattice *hkl_lattice_new_copy(const HklLattice *self)
{
	HklLattice *copy = NULL;

	copy = HKL_MALLOC(HklLattice);

	copy->a = hkl_parameter_new_copy(self->a);
	copy->b = hkl_parameter_new_copy(self->b);
	copy->c = hkl_parameter_new_copy(self->c);
	copy->alpha = hkl_parameter_new_copy(self->alpha);
	copy->beta = hkl_parameter_new_copy(self->beta);
	copy->gamma = hkl_parameter_new_copy(self->gamma);

	return copy;
}

/**
 * hkl_lattice_new_default: (skip)
 *
 * default constructor
 *
 * Returns:
 **/
HklLattice* hkl_lattice_new_default(void)
{
	return hkl_lattice_new(1.54, 1.54, 1.54,
			       90*HKL_DEGTORAD, 90*HKL_DEGTORAD, 90*HKL_DEGTORAD,
			       NULL);
}

/**
 * hkl_lattice_free: (skip)
 * @self:
 *
 * destructor
 **/
void hkl_lattice_free(HklLattice *self)
{
	hkl_parameter_free(self->a);
	hkl_parameter_free(self->b);
	hkl_parameter_free(self->c);
	hkl_parameter_free(self->alpha);
	hkl_parameter_free(self->beta);
	hkl_parameter_free(self->gamma);
	free(self);
}

/**
 * hkl_lattice_a_get: (skip)
 * @self: the this ptr
 **/
const HklParameter *hkl_lattice_a_get(const HklLattice *self)
{
	return self->a;
}

/**
 * hkl_lattice_a_set: (skip)
 * @self: the this ptr
 * @parameter: the parameter to set
 * @error: return location for a GError, or NULL
 *
 * Returns: TRUE on success, FALSE if an error occurred
 **/
int hkl_lattice_a_set(HklLattice *self, const HklParameter *parameter,
		      GError **error)
{
	hkl_error (error == NULL || *error == NULL);

	return hkl_parameter_init_copy(self->a, parameter, error);
}

/**
 * hkl_lattice_b_get: (skip)
 * @self: the this ptr
 **/
const HklParameter *hkl_lattice_b_get(const HklLattice *self)
{
	return self->b;
}

/**
 * hkl_lattice_b_set: (skip)
 * @self: the this ptr
 * @parameter: the parameter to set
 * @error: return location for a GError, or NULL
 *
 * Returns: TRUE on success, FALSE if an error occurred
 **/
int hkl_lattice_b_set(HklLattice *self, const HklParameter *parameter,
		      GError **error)
{
	hkl_error (error == NULL || *error == NULL);

	return hkl_parameter_init_copy(self->b, parameter, error);
}

/**
 * hkl_lattice_c_get: (skip)
 * @self: the this ptr
 **/
const HklParameter *hkl_lattice_c_get(const HklLattice *self)
{
	return self->c;
}

/**
 * hkl_lattice_c_set: (skip)
 * @self: the this ptr
 * @parameter: the parameter to set
 * @error: return location for a GError, or NULL
 *
 * Returns: TRUE on success, FALSE if an error occurred
 **/
int hkl_lattice_c_set(HklLattice *self, const HklParameter *parameter,
		      GError **error)
{
	hkl_error (error == NULL || *error == NULL);

	return hkl_parameter_init_copy(self->c, parameter, error);
}

/**
 * hkl_lattice_alpha_get: (skip)
 * @self: the this ptr
 **/
const HklParameter *hkl_lattice_alpha_get(const HklLattice *self)
{
	return self->alpha;
}

/**
 * hkl_lattice_alpha_set: (skip)
 * @self: the this ptr
 * @parameter: the parameter to set
 * @error: return location for a GError, or NULL
 *
 * Returns: TRUE on success, FALSE if an error occurred
 **/
int hkl_lattice_alpha_set(HklLattice *self, const HklParameter *parameter,
			  GError **error)
{
	hkl_error (error == NULL || *error == NULL);

	return hkl_parameter_init_copy(self->alpha, parameter, error);
}

/**
 * hkl_lattice_beta_get: (skip)
 * @self: the this ptr
 **/
const HklParameter *hkl_lattice_beta_get(const HklLattice *self)
{
	return self->beta;
}

/**
 * hkl_lattice_beta_set: (skip)
 * @self: the this ptr
 * @parameter: the parameter to set
 * @error: return location for a GError, or NULL
 *
 * Returns: TRUE on success, FALSE if an error occurred
 **/
int hkl_lattice_beta_set(HklLattice *self, const HklParameter *parameter,
			 GError **error)
{
	hkl_error (error == NULL || *error == NULL);

	return hkl_parameter_init_copy(self->beta, parameter, error);
}

/**
 * hkl_lattice_gamma_get: (skip)
 * @self: the this ptr
 **/
const HklParameter *hkl_lattice_gamma_get(const HklLattice *self)
{
	return self->gamma;
}

/**
 * hkl_lattice_gamma_set: (skip)
 * @self: the this ptr
 * @parameter: the parameter to set
 * @error: return location for a GError, or NULL
 *
 * Returns: TRUE on success, FALSE if an error occurred
 **/
int hkl_lattice_gamma_set(HklLattice *self, const HklParameter *parameter,
			   GError **error)
{
	hkl_error (error == NULL || *error == NULL);

	return hkl_parameter_init_copy(self->gamma, parameter, error);
}

/**
 * hkl_lattice_lattice_set: (skip)
 * @self: the this ptr
 * @lattice: the lattice to set from.
 **/
void hkl_lattice_lattice_set(HklLattice *self, const HklLattice *lattice)
{
	if (self == lattice)
		return;

	hkl_parameter_init_copy(self->a, lattice->a, NULL);
	hkl_parameter_init_copy(self->b, lattice->b, NULL);
	hkl_parameter_init_copy(self->c, lattice->c, NULL);
	hkl_parameter_init_copy(self->alpha, lattice->alpha, NULL);
	hkl_parameter_init_copy(self->beta, lattice->beta, NULL);
	hkl_parameter_init_copy(self->gamma, lattice->gamma, NULL);
}

/**
 * hkl_lattice_set:
 * @self:
 * @a:
 * @b:
 * @c:
 * @alpha:
 * @beta:
 * @gamma:
 *
 * set the lattice parameters
 *
 * Returns:
 **/
int hkl_lattice_set(HklLattice *self,
		    double a, double b, double c,
		    double alpha, double beta, double gamma,
		    HklUnitEnum unit_type, GError **error)
{
	hkl_error (error == NULL || *error == NULL);

	double _a, _b, _c, _alpha, _beta, _gamma;

	_a = convert_to_default(self->a, a, unit_type);
	_b = convert_to_default(self->b, b, unit_type);
	_c = convert_to_default(self->c, c, unit_type);
	_alpha = convert_to_default(self->alpha, alpha, unit_type);
	_beta = convert_to_default(self->beta, beta, unit_type);
	_gamma = convert_to_default(self->gamma, gamma, unit_type);

	/* need to do the conversion before the check */
	if(!check_lattice_param(_a, _b, _c, _alpha, _beta, _gamma, error)){
		g_assert (error == NULL || *error != NULL);
		return FALSE;
	}
	g_assert (error == NULL || *error == NULL);

	hkl_parameter_value_set(self->a, _a, HKL_UNIT_DEFAULT, NULL);
	hkl_parameter_value_set(self->b, _b, HKL_UNIT_DEFAULT, NULL);
	hkl_parameter_value_set(self->c, _c, HKL_UNIT_DEFAULT, NULL);
	hkl_parameter_value_set(self->alpha, _alpha, HKL_UNIT_DEFAULT, NULL);
	hkl_parameter_value_set(self->beta, _beta, HKL_UNIT_DEFAULT, NULL);
	hkl_parameter_value_set(self->gamma, _gamma, HKL_UNIT_DEFAULT, NULL);

	return TRUE;
}

/**
 * hkl_lattice_get:
 * @self:
 * @a: (out caller-allocates):
 * @b: (out caller-allocates):
 * @c: (out caller-allocates):
 * @alpha: (out caller-allocates):
 * @beta: (out caller-allocates):
 * @gamma: (out caller-allocates):
 *
 * get the lattice parameters
 * Return value: all the parameters
 **/
void hkl_lattice_get(const HklLattice *self,
		     double *a, double *b, double *c,
		     double *alpha, double *beta, double *gamma,
		     HklUnitEnum unit_type)
{
	*a = hkl_parameter_value_get(self->a, unit_type);
	*b = hkl_parameter_value_get(self->b, unit_type);
	*c = hkl_parameter_value_get(self->c, unit_type);
	*alpha = hkl_parameter_value_get(self->alpha, unit_type);
	*beta = hkl_parameter_value_get(self->beta, unit_type);
	*gamma = hkl_parameter_value_get(self->gamma, unit_type);
}

/**
 * hkl_lattice_get_B: (skip)
 * @self:
 * @B: (out): where to store the B matrix
 *
 * Get the B matrix from the lattice parameters
 *
 * Returns:
 **/
int hkl_lattice_get_B(const HklLattice *self, HklMatrix *B)
{
	double D;
	double c_alpha, s_alpha;
	double c_beta, s_beta;
	double c_gamma, s_gamma;
	double b11, b22, tmp;

	c_alpha = cos(hkl_parameter_value_get(self->alpha, HKL_UNIT_DEFAULT));
	c_beta = cos(hkl_parameter_value_get(self->beta, HKL_UNIT_DEFAULT));
	c_gamma = cos(hkl_parameter_value_get(self->gamma, HKL_UNIT_DEFAULT));
	D = 1 - c_alpha*c_alpha - c_beta*c_beta - c_gamma*c_gamma
		+ 2*c_alpha*c_beta*c_gamma;

	if (D > 0.)
		D = sqrt(D);
	else
		return FALSE;

	s_alpha = sin(hkl_parameter_value_get(self->alpha, HKL_UNIT_DEFAULT));
	s_beta  = sin(hkl_parameter_value_get(self->beta, HKL_UNIT_DEFAULT));
	s_gamma = sin(hkl_parameter_value_get(self->gamma, HKL_UNIT_DEFAULT));

	b11 = HKL_TAU / (hkl_parameter_value_get(self->b, HKL_UNIT_DEFAULT) * s_alpha);
	b22 = HKL_TAU / hkl_parameter_value_get(self->c, HKL_UNIT_DEFAULT);
	tmp = b22 / s_alpha;

	B->data[0][0] = HKL_TAU * s_alpha / (hkl_parameter_value_get(self->a, HKL_UNIT_DEFAULT) * D);
	B->data[0][1] = b11 / D * (c_alpha*c_beta - c_gamma);
	B->data[0][2] = tmp / D * (c_gamma*c_alpha - c_beta);

	B->data[1][0] = 0;
	B->data[1][1] = b11;
	B->data[1][2] = tmp / (s_beta*s_gamma) * (c_beta*c_gamma - c_alpha);

	B->data[2][0] = 0;
	B->data[2][1] = 0;
	B->data[2][2] = b22;

	return TRUE;
}

/**
 * hkl_lattice_get_1_B: (skip)
 * @self: the @HklLattice
 * @B: (out): where to store the 1/B matrix
 *
 * Compute the invert of B (needed by the hkl_sample_UB_set method)
 * should be optimized
 *
 * Returns: TRUE or FALSE depending of the success of the
 * computation.
 **/
int hkl_lattice_get_1_B(const HklLattice *self, HklMatrix *B)
{
	HklMatrix tmp;
	double a;
	double b;
	double c;
	double d;
	double e;
	double f;

	if(!self || !B)
		return FALSE;

	/*
	 * first compute the B matrix
	 * | a b c |
	 * | 0 d e |
	 * | 0 0 f |
	 */
	hkl_lattice_get_B(self, &tmp);

	/*
	 * now invert this triangular matrix
	 */
	a = tmp.data[0][0];
	b = tmp.data[0][1];
	c = tmp.data[0][2];
	d = tmp.data[1][1];
	e = tmp.data[1][2];
	f = tmp.data[2][2];

	B->data[0][0] = 1 / a;
	B->data[0][1] = -b / a / d;
	B->data[0][2] = (b * e - d * c) / a / d / f;

	B->data[1][0] = 0;
	B->data[1][1] = 1 / d;
	B->data[1][2] = -e / d / f;

	B->data[2][0] = 0;
	B->data[2][1] = 0;
	B->data[2][2] = 1 / f;

	return TRUE;
}

/**
 * hkl_lattice_reciprocal:
 * @self: the this ptr
 * @reciprocal: the lattice where the result will be computed
 *
 * compute the reciprocal #HklLattice and put the result id the
 * provided @reciprocal parameter
 *
 * Returns: 0 or 1 if it succeed.
 **/
int hkl_lattice_reciprocal(const HklLattice *self, HklLattice *reciprocal)
{
	double c_alpha, c_beta, c_gamma;
	double s_alpha, s_beta, s_gamma;
	double c_beta1, c_beta2, c_beta3;
	double s_beta1, s_beta2, s_beta3;
	double s_beta_s_gamma, s_gamma_s_alpha, s_alpha_s_beta;
	double D;

	c_alpha = cos(hkl_parameter_value_get(self->alpha, HKL_UNIT_DEFAULT));
	c_beta  = cos(hkl_parameter_value_get(self->beta, HKL_UNIT_DEFAULT));
	c_gamma = cos(hkl_parameter_value_get(self->gamma, HKL_UNIT_DEFAULT));
	D = 1 - c_alpha*c_alpha - c_beta*c_beta - c_gamma*c_gamma
		+ 2*c_alpha*c_beta*c_gamma;

	if (D > 0.)
		D = sqrt(D);
	else
		return FALSE;

	s_alpha = sin(hkl_parameter_value_get(self->alpha, HKL_UNIT_DEFAULT));
	s_beta  = sin(hkl_parameter_value_get(self->beta, HKL_UNIT_DEFAULT));
	s_gamma = sin(hkl_parameter_value_get(self->gamma, HKL_UNIT_DEFAULT));

	s_beta_s_gamma  = s_beta  * s_gamma;
	s_gamma_s_alpha = s_gamma * s_alpha;
	s_alpha_s_beta  = s_alpha * s_beta;

	c_beta1 = (c_beta  * c_gamma - c_alpha) / s_beta_s_gamma;
	c_beta2 = (c_gamma * c_alpha - c_beta)  / s_gamma_s_alpha;
	c_beta3 = (c_alpha * c_beta  - c_gamma) / s_alpha_s_beta;
	s_beta1 = D / s_beta_s_gamma;
	s_beta2 = D / s_gamma_s_alpha;
	s_beta3 = D / s_alpha_s_beta;

	hkl_lattice_set(reciprocal,
			HKL_TAU * s_alpha / (hkl_parameter_value_get(self->a, HKL_UNIT_DEFAULT) * D),
			HKL_TAU * s_beta  / (hkl_parameter_value_get(self->b, HKL_UNIT_DEFAULT) * D),
			HKL_TAU * s_gamma / (hkl_parameter_value_get(self->c, HKL_UNIT_DEFAULT) * D),
			atan2(s_beta1, c_beta1),
			atan2(s_beta2, c_beta2),
			atan2(s_beta3, c_beta3),
			HKL_UNIT_DEFAULT, NULL);

	return TRUE;
}

/**
 * hkl_lattice_randomize: (skip)
 * @self:
 *
 * randomize the lattice
 **/
void hkl_lattice_randomize(HklLattice *self)
{
	static HklVector vector_x = {{1, 0, 0}};
	HklVector a, b, c;
	HklVector axe;
	unsigned int angles_to_randomize;

	/* La valeur des angles alpha, beta et gamma ne sont pas indépendant. */
	/* Il faut donc gérer les différents cas. */
	hkl_parameter_randomize(self->a);
	hkl_parameter_randomize(self->b);
	hkl_parameter_randomize(self->c);

	angles_to_randomize = self->alpha->fit
		+ self->beta->fit
		+ self->gamma->fit;
	switch (angles_to_randomize) {
	case 0:
		break;
	case 1:
		if (self->alpha->fit) {
			/* alpha */
			a = b = c = vector_x;

			/* randomize b */
			hkl_vector_randomize_vector(&axe, &a);
			hkl_vector_rotated_around_vector(&b, &axe,
							 hkl_parameter_value_get(self->gamma,
										 HKL_UNIT_DEFAULT));

			/* randomize c */
			hkl_vector_randomize_vector(&axe, &a);
			hkl_vector_rotated_around_vector(&c, &axe,
							 hkl_parameter_value_get(self->beta,
										 HKL_UNIT_DEFAULT));

			/* compute the alpha angle. */
			hkl_parameter_value_set(self->alpha, hkl_vector_angle(&b, &c),
						HKL_UNIT_DEFAULT, NULL);
		} else if (self->beta->fit) {
			/* beta */
			a = b = vector_x;

			/* randomize b */
			hkl_vector_randomize_vector(&axe, &a);
			hkl_vector_rotated_around_vector(&b, &axe,
							 hkl_parameter_value_get(self->gamma,
										 HKL_UNIT_DEFAULT));

			/* randomize c */
			c = b;
			hkl_vector_randomize_vector(&axe, &b);
			hkl_vector_rotated_around_vector(&c, &axe,
							 hkl_parameter_value_get(self->alpha,
										 HKL_UNIT_DEFAULT));

			/* compute beta */
			hkl_parameter_value_set(self->beta, hkl_vector_angle(&a, &c),
						HKL_UNIT_DEFAULT, NULL);
		} else {
			/* gamma */
			a = c = vector_x;

			/* randomize c */
			hkl_vector_randomize_vector(&axe, &a);
			hkl_vector_rotated_around_vector(&c, &axe,
							 hkl_parameter_value_get(self->beta,
										 HKL_UNIT_DEFAULT));

			/* randomize b */
			b = c;
			hkl_vector_randomize_vector(&axe, &c);
			hkl_vector_rotated_around_vector(&b, &axe,
							 hkl_parameter_value_get(self->alpha,
										 HKL_UNIT_DEFAULT));

			/* compute gamma */
			hkl_parameter_value_set(self->gamma, hkl_vector_angle(&a, &b),
						HKL_UNIT_DEFAULT, NULL);
		}
		break;
	case 2:
		if (self->alpha->fit) {
			if (self->beta->fit) {
				/* alpha + beta */
				a = b = vector_x;

				/* randomize b */
				hkl_vector_randomize_vector(&axe, &a);
				hkl_vector_rotated_around_vector(&b, &axe,
								 hkl_parameter_value_get(self->gamma,
											 HKL_UNIT_DEFAULT));

				/* randomize c */
				hkl_vector_randomize_vector_vector(&c, &a, &b);

				hkl_parameter_value_set(self->alpha, hkl_vector_angle(&b, &c),
							HKL_UNIT_DEFAULT, NULL);
				hkl_parameter_value_set(self->beta, hkl_vector_angle(&a, &c),
							HKL_UNIT_DEFAULT, NULL);
			} else {
				/* alpha + gamma */
				a = c = vector_x;

				/* randomize c */
				hkl_vector_randomize_vector(&axe, &a);
				hkl_vector_rotated_around_vector(&c, &axe,
								 hkl_parameter_value_get(self->beta,
											 HKL_UNIT_DEFAULT));

				/* randomize c */
				hkl_vector_randomize_vector_vector(&b, &a, &c);

				hkl_parameter_value_set(self->alpha, hkl_vector_angle(&b, &c),
							HKL_UNIT_DEFAULT, NULL);
				hkl_parameter_value_set(self->gamma, hkl_vector_angle(&a, &b),
							HKL_UNIT_DEFAULT, NULL);
			}
		} else {
			/* beta + gamma */
			b = c = vector_x;

			/* randomize c */
			hkl_vector_randomize_vector(&axe, &b);
			hkl_vector_rotated_around_vector(&c, &axe,
							 hkl_parameter_value_get(self->alpha,
										 HKL_UNIT_DEFAULT));

			/* randomize c */
			hkl_vector_randomize_vector_vector(&a, &b, &c);

			hkl_parameter_value_set(self->beta, hkl_vector_angle(&a, &c),
						HKL_UNIT_DEFAULT, NULL);
			hkl_parameter_value_set(self->gamma, hkl_vector_angle(&a, &b),
						HKL_UNIT_DEFAULT, NULL);
		}
		break;
	case 3:
		hkl_vector_randomize(&a);
		hkl_vector_randomize_vector(&b, &a);
		hkl_vector_randomize_vector_vector(&c, &b, &a);

		hkl_parameter_value_set(self->alpha, hkl_vector_angle(&b, &c),
					HKL_UNIT_DEFAULT, NULL);
		hkl_parameter_value_set(self->beta, hkl_vector_angle(&a, &c),
					HKL_UNIT_DEFAULT, NULL);
		hkl_parameter_value_set(self->gamma, hkl_vector_angle(&a, &b),
					HKL_UNIT_DEFAULT, NULL);
		break;
	}
}

/**
 * hkl_lattice_fprintf: (skip)
 * @f:
 * @self:
 *
 * print into a file the lattice.
 **/
void hkl_lattice_fprintf(FILE *f, HklLattice const *self)
{
	fprintf(f, "\n");
	hkl_parameter_fprintf(f, self->a);
	fprintf(f, "\n");
	hkl_parameter_fprintf(f, self->b);
	fprintf(f, "\n");
	hkl_parameter_fprintf(f, self->c);
	fprintf(f, "\n");
	hkl_parameter_fprintf(f, self->alpha);
	fprintf(f, "\n");
	hkl_parameter_fprintf(f, self->beta);
	fprintf(f, "\n");
	hkl_parameter_fprintf(f, self->gamma);
}
