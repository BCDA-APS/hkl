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
#include <gsl/gsl_errno.h>              // for ::GSL_SUCCESS
#include <gsl/gsl_sys.h>                // for gsl_isnan
#include <gsl/gsl_vector_double.h>      // for gsl_vector
#include "hkl-pseudoaxis-auto-private.h"  // for HklFunction, etc
#include "hkl-pseudoaxis-common-hkl-private.h"  // for RUBh_minus_Q, etc
#include "hkl-pseudoaxis-private.h"     // for hkl_engine_add_mode
#include "hkl/ccan/array_size/array_size.h"  // for ARRAY_SIZE
#include "hkl.h"                        // for HklMode, HklEngine, etc

/* #define DEBUG */

/***********************/
/* numerical functions */
/***********************/

static int _reflectivity_func(const gsl_vector *x, void *params, gsl_vector *f)
{
	const double mu = x->data[0];
	const double gamma = x->data[3];

	CHECK_NAN(x->data, x->size);

	RUBh_minus_Q(x->data, params, f->data);
	f->data[3] = mu - gamma;

	return  GSL_SUCCESS;
}

static const HklFunction reflectivity_func = {
	.function = _reflectivity_func,
	.size = 4,
};

/********/
/* mode */
/********/

static HklMode* zaxis()
{
	static const char *axes_r[] = {"mu", "omega", "delta", "gamma"};
	static const char* axes_w[] = {"omega", "delta", "gamma"};
	static const HklFunction *functions[] = {&RUBh_minus_Q_func};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO(__func__, axes_r, axes_w, functions),
	};

	return hkl_mode_auto_new(&info,
				 &hkl_full_mode_operations,
				 TRUE);
}

static HklMode* reflectivity()
{
	static const char* axes[] = {"mu", "omega", "delta", "gamma"};
	static const HklFunction *functions[] = {&reflectivity_func};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO(__func__, axes, axes, functions),
	};

	return hkl_mode_auto_new(&info,
				 &hkl_full_mode_operations,
				 TRUE);
}

/**********************/
/* pseudo axis engine */
/**********************/

HklEngine *hkl_engine_zaxis_hkl_new(void)
{
	HklEngine *self;
	HklMode *default_mode;

	self = hkl_engine_hkl_new();

	default_mode = zaxis();
	hkl_engine_add_mode(self, default_mode);
	hkl_engine_mode_set(self, default_mode);

	hkl_engine_add_mode(self, reflectivity());

	return self;
}
