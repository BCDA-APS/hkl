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
 * Copyright (C) 2010      Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#include <gsl/gsl_math.h>
#include <gsl/gsl_vector.h>

#include <hkl/hkl-pseudoaxis-petra3.h>
#include <hkl/hkl-pseudoaxis-common-hkl.h>

static int reflectivity(const gsl_vector *x, void *params, gsl_vector *f)
{
	double mu, gamma;
	double const *x_data = gsl_vector_const_ptr(x, 0);
	double *f_data = gsl_vector_ptr(f, 0);

	RUBh_minus_Q(x_data, params, f_data);

	mu = x_data[0];
	gamma = x_data[3];

	f_data[3] = mu - gamma;

	return  GSL_SUCCESS;
}

static int bissector_horizontal(const gsl_vector *x, void *params, gsl_vector *f)
{
	double omega, delta;
	double const *x_data = gsl_vector_const_ptr(x, 0);
	double *f_data = gsl_vector_ptr(f, 0);

	RUBh_minus_Q(x_data, params, f_data);

	omega = x_data[0];
	delta = x_data[3];

	f_data[3] = delta - 2 * fmod(omega, M_PI);

	return  GSL_SUCCESS;
}

/**********************************/
/* PETRA3 P09 EH2 PseudoAxeEngine */
/**********************************/

HklPseudoAxisEngine *hkl_pseudo_axis_engine_petra3_p09_eh2_hkl_new(void)
{
	HklPseudoAxisEngine *self;
	HklPseudoAxisEngineMode *mode;

	self = hkl_pseudo_axis_engine_hkl_new();

	/* zaxis + alpha-fixed */
	mode = hkl_pseudo_axis_engine_mode_new(
		"zaxis + alpha-fixed",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_hkl_real,
		1, RUBh_minus_Q_func,
		(size_t)0,
		(size_t)3, "omega", "delta", "gamma");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* zaxis + beta-fixed */
	mode = hkl_pseudo_axis_engine_mode_new(
		"zaxis + beta-fixed",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_hkl_real,
		1, RUBh_minus_Q_func,
		(size_t)0,
		(size_t)3, "mu", "delta", "gamma");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* zaxis + alpha=beta */
	mode = hkl_pseudo_axis_engine_mode_new(
		"zaxis + alpha=beta",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_hkl_real,
		1, reflectivity,
		(size_t)0,
		(size_t)4, "mu", "omega", "delta", "gamma");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* 4-circles bissecting_horizontal */
	mode = hkl_pseudo_axis_engine_mode_new(
		"4-circles bissecting horizontal",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_real,
		1, bissector_horizontal,
		(size_t)0,
		(size_t)4, "omega", "chi", "phi", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* 4-circles constant_omega_horizontal */
	mode = hkl_pseudo_axis_engine_mode_new(
		"4-circles constant omega horizontal",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_real,
		1, RUBh_minus_Q_func,
		(size_t)0,
		(size_t)3, "chi", "phi", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* 4-circles constant_chi_horizontal */
	mode = hkl_pseudo_axis_engine_mode_new(
		"4-circles constant chi horizontal",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_real,
		1, RUBh_minus_Q_func,
		(size_t)0,
		(size_t)3, "omega", "phi", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* 4-circles constant_phi_horizontal */
	mode = hkl_pseudo_axis_engine_mode_new(
		"4-circles constant phi horizontal",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_real,
		1, RUBh_minus_Q_func,
		(size_t)0,
		(size_t)3, "omega", "chi", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	hkl_pseudo_axis_engine_select_mode(self, 0);

	return self;
}