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
 * Copyright (C) 2010-2014 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#include <gsl/gsl_errno.h>				 // for ::GSL_SUCCESS
#include <gsl/gsl_sys.h>				 // for gsl_isnan
#include <gsl/gsl_vector_double.h>		 // for gsl_vector
#include <math.h>						 // for fmod, M_PI
#include "hkl-pseudoaxis-auto-private.h" // for HklFunction, etc
#include "hkl-pseudoaxis-common-hkl-private.h"
#include "hkl-pseudoaxis-common-psi-private.h"  // for hkl_engine_psi_new, etc
#include "hkl-pseudoaxis-private.h"			// for hkl_engine_add_mode
#include "hkl/ccan/array_size/array_size.h" // for ARRAY_SIZE
#include "hkl.h"							// for HklMode, HklEngine, etc

/***********************/
/* numerical functions */
/***********************/

static int _reflectivity(const gsl_vector *x, void *params, gsl_vector *f)
{
	const double mu = x->data[0];
	const double gamma = x->data[3];

	CHECK_NAN(x->data, x->size);

	RUBh_minus_Q(x->data, params, f->data);
	f->data[3] = mu - gamma;

	return GSL_SUCCESS;
}

static const HklFunction reflectivity = {
	.function = _reflectivity,
	.size = 4,
};

static int _bissector_horizontal(const gsl_vector *x, void *params, gsl_vector *f)
{
	const double omega = x->data[0];
	const double delta = x->data[3];

	CHECK_NAN(x->data, x->size);

	RUBh_minus_Q(x->data, params, f->data);
	f->data[3] = delta - 2 * fmod(omega, M_PI);

	return GSL_SUCCESS;
}

static const HklFunction bissector_horizontal = {
	.function = _bissector_horizontal,
	.size = 4,
};

/********/
/* mode */
/********/

static HklMode *zaxis_alpha_fixed()
{
	static const char *axes_r[] = {"mu", "omega", "chi", "phi", "delta", "gamma"};
	static const char *axes_w[] = {"omega", "delta", "gamma"};
	static const HklFunction *functions[] = {&RUBh_minus_Q_func};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO("zaxis + alpha-fixed", axes_r, axes_w, functions),
	};

	return hkl_mode_auto_new(&info,
							 &hkl_full_mode_operations,
							 TRUE);
}

static HklMode *zaxis_beta_fixed()
{
	static const char *axes_r[] = {"mu", "omega", "chi", "phi", "delta", "gamma"};
	static const char *axes_w[] = {"mu", "delta", "gamma"};
	static const HklFunction *functions[] = {&RUBh_minus_Q_func};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO("zaxis + beta-fixed", axes_r, axes_w, functions),
	};

	return hkl_mode_auto_new(&info,
							 &hkl_full_mode_operations,
							 TRUE);
}

static HklMode *zaxis_alpha_eq_beta()
{
	static const char *axes_r[] = {"mu", "omega", "chi", "phi", "delta", "gamma"};
	static const char *axes_w[] = {"mu", "omega", "delta", "gamma"};
	static const HklFunction *functions[] = {&reflectivity};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO("zaxis + alpha=beta", axes_r, axes_w, functions),
	};

	return hkl_mode_auto_new(&info,
							 &hkl_full_mode_operations,
							 TRUE);
}

static HklMode *fourc_bissector_horizontal()
{
	static const char *axes_r[] = {"mu", "omega", "chi", "phi", "delta", "gamma"};
	static const char *axes_w[] = {"omega", "chi", "phi", "delta"};
	static const HklFunction *functions[] = {&bissector_horizontal};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO("4-circles bissecting horizontal", axes_r, axes_w, functions),
	};

	return hkl_mode_auto_new(&info,
							 &hkl_full_mode_operations,
							 TRUE);
}

static HklMode *fourc_constant_omega_horizontal()
{
	static const char *axes_r[] = {"mu", "omega", "chi", "phi", "delta", "gamma"};
	static const char *axes_w[] = {"chi", "phi", "delta"};
	static const HklFunction *functions[] = {&RUBh_minus_Q_func};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO("4-circles constant omega horizontal", axes_r, axes_w, functions),
	};

	return hkl_mode_auto_new(&info,
							 &hkl_full_mode_operations,
							 TRUE);
}

static HklMode *fourc_constant_chi_horizontal()
{
	static const char *axes_r[] = {"mu", "omega", "chi", "phi", "delta", "gamma"};
	static const char *axes_w[] = {"omega", "phi", "delta"};
	static const HklFunction *functions[] = {&RUBh_minus_Q_func};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO("4-circles constant chi horizontal", axes_r, axes_w, functions),
	};

	return hkl_mode_auto_new(&info,
							 &hkl_full_mode_operations,
							 TRUE);
}

static HklMode *fourc_constant_phi_horizontal()
{
	static const char *axes_r[] = {"mu", "omega", "chi", "phi", "delta", "gamma"};
	static const char *axes_w[] = {"omega", "chi", "delta"};
	static const HklFunction *functions[] = {&RUBh_minus_Q_func};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO("4-circles constant phi horizontal", axes_r, axes_w, functions),
	};

	return hkl_mode_auto_new(&info,
							 &hkl_full_mode_operations,
							 TRUE);
}

static HklMode *psi_constant()
{
	static const char *axes_r[] = {"mu", "omega", "chi", "phi", "gamma", "delta"};
	static const char *axes_w[] = {"omega", "chi", "phi", "delta"};
	static const HklFunction *functions[] = {&psi_func};
	static const HklParameter parameters[] = {
		{
			HKL_PARAMETER_DEFAULTS,
			.name = "h1",
			.range = {.min = -1, .max = 1},
			._value = 1,
		},
		{
			HKL_PARAMETER_DEFAULTS,
			.name = "k1",
			.range = {.min = -1, .max = 1},
			._value = 1,
		},
		{
			HKL_PARAMETER_DEFAULTS,
			.name = "l1",
			.range = {.min = -1, .max = 1},
			._value = 1,
		},
	};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO_WITH_PARAMS(__func__, axes_r, axes_w, functions, parameters),
	};

	return hkl_mode_psi_new(&info);
}

static HklMode *psi_constant_vertical(void)
{
	static const char *axes_r[] = {"mu", "omega", "chi", "phi", "gamma", "delta"};
	static const char *axes_w[] = {"omega", "chi", "phi", "delta"};
	static const HklFunction *functions[] = {&psi_constant_vertical_func};
	static const HklParameter parameters[] = {
		{
			HKL_PARAMETER_DEFAULTS,
			.name = "h2",
			.range = {.min = -1, .max = 1},
			._value = 1,
		},
		{
			HKL_PARAMETER_DEFAULTS,
			.name = "k2",
			.range = {.min = -1, .max = 1},
			._value = 0,
		},
		{
			HKL_PARAMETER_DEFAULTS,
			.name = "l2",
			.range = {.min = -1, .max = 1},
			._value = 0,
		},
		{HKL_PARAMETER_DEFAULTS_ANGLE, .name = "psi"},
	};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO_WITH_PARAMS(__func__, axes_r, axes_w, functions, parameters),
	};

	return hkl_mode_auto_new(&info,
							 &psi_constant_vertical_mode_operations,
							 TRUE);
}

static HklMode *psi_constant_horizontal(void)
{
	static const char *axes_r[] = {"mu", "omega", "chi", "phi", "gamma", "delta"};
	static const char *axes_w[] = {"omega", "chi", "phi", "gamma"};
	static const HklFunction *functions[] = {&psi_constant_vertical_func};
	static const HklParameter parameters[] = {
		{
			HKL_PARAMETER_DEFAULTS,
			.name = "h2",
			.range = {.min = -1, .max = 1},
			._value = 1,
		},
		{
			HKL_PARAMETER_DEFAULTS,
			.name = "k2",
			.range = {.min = -1, .max = 1},
			._value = 0,
		},
		{
			HKL_PARAMETER_DEFAULTS,
			.name = "l2",
			.range = {.min = -1, .max = 1},
			._value = 0,
		},
		{HKL_PARAMETER_DEFAULTS_ANGLE, .name = "psi"},
	};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO_WITH_PARAMS(__func__, axes_r, axes_w, functions, parameters),
	};

	return hkl_mode_auto_new(&info,
							 &psi_constant_vertical_mode_operations,
							 TRUE);
}

/**********************/
/* pseudo axis engine */
/**********************/

HklEngine *hkl_engine_aps_polar_hkl_new(void)
{
	HklEngine *self;
	HklMode *default_mode;

	self = hkl_engine_hkl_new();

	default_mode = fourc_constant_phi_horizontal();
	hkl_engine_add_mode(self, default_mode);
	hkl_engine_mode_set(self, default_mode);

	hkl_engine_add_mode(self, zaxis_alpha_fixed());
	hkl_engine_add_mode(self, zaxis_beta_fixed());
	hkl_engine_add_mode(self, zaxis_alpha_eq_beta());
	hkl_engine_add_mode(self, fourc_bissector_horizontal());
	hkl_engine_add_mode(self, fourc_constant_omega_horizontal());
	hkl_engine_add_mode(self, fourc_constant_chi_horizontal());

	/* Which one of these modes do we want? */
	hkl_engine_add_mode(self, psi_constant());			  // copied from hkl-pseudoaxis-e6c-psi.c
	hkl_engine_add_mode(self, psi_constant_vertical());	  // copied from hkl-pseudoaxis-e6c-hkl.c
	hkl_engine_add_mode(self, psi_constant_horizontal()); // copied from hkl-pseudoaxis-e6c-hkl.c

	return self;
}
