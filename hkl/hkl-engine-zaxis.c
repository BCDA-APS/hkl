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
 * Copyright (C) 2003-2017 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#include <gsl/gsl_sys.h>                // for gsl_isnan
#include "hkl-factory-private.h"        // for autodata_factories_, etc
#include "hkl-pseudoaxis-common-hkl-private.h"  // for RUBh_minus_Q, etc
#include "hkl-pseudoaxis-common-q-private.h"  // for hkl_engine_q2_new, etc
#include "hkl-pseudoaxis-common-tth-private.h"  // for hkl_engine_tth2_new, etc
#include "hkl-pseudoaxis-common-readonly-private.h"  // for hkl_engine_tth2_new, etc

#define MU "mu"
#define OMEGA "omega"
#define DELTA "delta"
#define GAMMA "gamma"

/* #define DEBUG */

static HklMode* _zaxis()
{
	static const char *axes_r[] = {MU, OMEGA, DELTA, GAMMA};
	static const char *axes_w[] = {OMEGA, DELTA, GAMMA};
	static const HklFunction *functions[] = {&RUBh_minus_Q_func};
	static const HklModeAutoInfo info = {
		HKL_MODE_AUTO_INFO("zaxis", axes_r, axes_w, functions),
	};

	return hkl_mode_auto_new(&info,
				 &hkl_full_mode_operations,
				 TRUE);
}

/* reflectivity */

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

static HklMode* reflectivity()
{
	static const char* axes[] = {MU, OMEGA, DELTA, GAMMA};
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

static HklEngine *hkl_engine_zaxis_hkl_new(HklEngineList *engines)
{
	HklEngine *self;
	HklMode *default_mode;

	self = hkl_engine_hkl_new(engines);

	default_mode = _zaxis();
	hkl_engine_add_mode(self, default_mode);
	hkl_engine_mode_set(self, default_mode);

	hkl_engine_add_mode(self, reflectivity());

	return self;
}

/*****************/
/* mode readonly */
/*****************/

REGISTER_READONLY_INCIDENCE(hkl_engine_zaxis_incidence_new,
			    P99_PROTECT({MU, OMEGA}),
			    surface_parameters_y);

REGISTER_READONLY_EMERGENCE(hkl_engine_zaxis_emergence_new,
			    P99_PROTECT({MU, OMEGA, DELTA, GAMMA}),
			    surface_parameters_y);

/*********/
/* ZAXIS */
/*********/

#define HKL_GEOMETRY_TYPE_ZAXIS_DESCRIPTION				\
	"For this geometry the **mu** axis is common to the sample and the detector.\n" \
	"\n"								\
	"+ xrays source fix allong the :math:`\\vec{x}` direction (1, 0, 0)\n" \
	"+ 2 axes for the sample\n"					\
	"\n"								\
	"  + **" MU "** : rotation around the :math:`\\vec{z}` direction (0, 0, 1)\n" \
	"  + **" OMEGA "** : rotating around the :math:`-\\vec{y}` direction (0, -1, 0)\n" \
	"\n"								\
	"+ 3 axis for the detector\n"					\
	"\n"								\
	"  + **" MU "** : rotation around the :math:`\\vec{z}` direction (0, 0, 1)\n" \
	"  + **" DELTA "** : rotation around the :math:`-\\vec{y}` direction (0, -1, 0)\n" \
	"  + **" GAMMA "** : rotation around the :math:`\\vec{z}` direction (0, 0, 1)\n"

static const char* hkl_geometry_zaxis_axes[] = {MU, OMEGA, DELTA, GAMMA};

static HklGeometry *hkl_geometry_new_zaxis(const HklFactory *factory)
{
	HklGeometry *self = hkl_geometry_new(factory, &hkl_geometry_operations_defaults);
	HklHolder *h;

	h = hkl_geometry_add_holder(self);
	hkl_holder_add_rotation(h, MU, 0, 0, 1, &hkl_unit_angle_deg);
	hkl_holder_add_rotation(h, OMEGA, 0, -1, 0, &hkl_unit_angle_deg);

	h = hkl_geometry_add_holder(self);
	hkl_holder_add_rotation(h, MU, 0, 0, 1, &hkl_unit_angle_deg);
	hkl_holder_add_rotation(h, DELTA, 0, -1, 0, &hkl_unit_angle_deg);
	hkl_holder_add_rotation(h, GAMMA, 0, 0, 1, &hkl_unit_angle_deg);

	return self;
}

static HklEngineList *hkl_engine_list_new_zaxis(const HklFactory *factory)
{
	HklEngineList *self = hkl_engine_list_new();

	hkl_engine_zaxis_hkl_new(self);
	hkl_engine_q2_new(self);
	hkl_engine_qper_qpar_new(self);
	hkl_engine_tth2_new(self);
	hkl_engine_zaxis_incidence_new(self);
	hkl_engine_zaxis_emergence_new(self);

	return self;
}

REGISTER_DIFFRACTOMETER(zaxis, "ZAXIS", HKL_GEOMETRY_TYPE_ZAXIS_DESCRIPTION);
