/* This file is part of the hkl3d library.
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
 *          Oussama Sboui <sboui@synchrotron-soleil.fr>
 */
#include <string.h>

#include "hkl3d.h"
#include "tap/basic.h"

#define MODEL_FILENAME "data/diffabs.yaml"
#define MODEL2_FILENAME "data/toto.yaml"

static void check_model_validity(struct Hkl3D *hkl3d)
{
	int i, j;
	int len;
	int res;
	struct Hkl3DObject *obji;
	struct Hkl3DObject *objj;

	res = TRUE;

	hkl3d_fprintf(stdout, hkl3d);

	/* imported 1 config files with 7 Hkl3DObjects */
	res &= hkl3d->configs->len == 1;
	res &= hkl3d->configs->configs[0]->len == 7;

	/* all Hkl3DObjects must have a different axis_name */
	len = hkl3d->configs->configs[0]->len;
	for(i=0;i<len; ++i){
		obji = hkl3d->configs->configs[0]->objects[i]; 
		for (j=1; j<len-i; ++j){
			objj = hkl3d->configs->configs[0]->objects[i+j];
			if(!(strcmp(obji->axis_name, objj->axis_name))){
				res &= FALSE;
				break;
			}
		}
		obji++;
	}

	/* check the _movingObjects validity, all Hkl3DAxis must have a size of 1 */
	for(i=0; i<hkl3d->movingObjects->len; ++i)
		res &= hkl3d->movingObjects->axes[i]->len == 1;

	ok(res == TRUE, "no identical objects");
}

/* check the collision and that the right axes are colliding */
static void check_collision(struct Hkl3D *hkl3d)
{
	char buffer[1000];
	int res;
	int i;

	/* check the collision and that the right axes are colliding */
	res = TRUE;
	hkl_geometry_set_values_v(hkl3d->geometry, 6,
				  23 * HKL_DEGTORAD, 0., 0., 0., 0., 0.);

	res &= hkl3d_is_colliding(hkl3d) == TRUE;
	strcpy(buffer, "");

	/* now check that only delta and mu are colliding */
	for(i=0; i<hkl3d->configs->configs[0]->len; ++i){
		const char *name;
		int tmp;

		name = hkl3d->configs->configs[0]->objects[i]->axis_name;
		tmp = hkl3d->configs->configs[0]->objects[i]->is_colliding == TRUE;
		/* add the colliding axes to the buffer */
		if(tmp){
			strcat(buffer, " ");
			strcat(buffer, name);
		}

		if(!strcmp(name, "mu") || !strcmp(name, "delta"))
			res &= tmp == TRUE;
		else
			res &= tmp == FALSE;
	}
	ok(res == TRUE,  "collision [%s]", buffer);
}

static void check_no_collision(struct Hkl3D *hkl3d)
{
	int res;
	int i;

	/* check that rotating around komega/kappa/kphi do not create collisison */
	res = TRUE;
	hkl_geometry_set_values_v(hkl3d->geometry, 6,
				  0., 0., 0., 0., 0., 0.);
	/* komega */
	for(i=0; i<=360; i=i+10){
		hkl_geometry_set_values_v(hkl3d->geometry, 6,
					  0., i * HKL_DEGTORAD, 0., 0., 0., 0.);
		res &= hkl3d_is_colliding(hkl3d) == FALSE;
	}
	
	/* kappa */
	for(i=0; i<=360; i=i+10){
		hkl_geometry_set_values_v(hkl3d->geometry, 6,
					  0., 0., i * HKL_DEGTORAD, 0., 0., 0.);
		res &= hkl3d_is_colliding(hkl3d) == FALSE;
	}

	/* kphi */
	for(i=0; i<=360; i=i+10){
		hkl_geometry_set_values_v(hkl3d->geometry, 6,
					  0., 0., 0., i * HKL_DEGTORAD, 0., 0.);
		res &= hkl3d_is_colliding(hkl3d) == FALSE;
	}
	ok(res == TRUE, "no-collision");
}

static void check_serialization(struct Hkl3D *hkl3d)
{
	FILE *f;
	int res;
	char* filename;

	res = TRUE;

	/* compute the filename of the diffractometer config file */
	filename  = test_file_path(MODEL2_FILENAME);

	f = fopen(filename, "w+");
	hkl3d_serialize(f, hkl3d);
	fclose(f);
	hkl3d_unserialize(filename, hkl3d);

	ok(res = TRUE, "serialization");
}

int main(int argc, char** argv)
{
	char* filename;
	const HklGeometryConfig *config;
	HklGeometry *geometry;
	struct Hkl3D *hkl3d;

	config = hkl_geometry_factory_get_config_from_type(HKL_GEOMETRY_TYPE_KAPPA6C);
	geometry = hkl_geometry_factory_new(config, HKL_DEGTORAD * 50.);

	/* compute the filename of the diffractometer config file */
	filename  = test_file_path(MODEL_FILENAME);
	hkl3d = hkl3d_new(filename, geometry);
	test_file_path_free(filename);

	plan(4);
	check_serialization(hkl3d);
	check_model_validity(hkl3d);
	check_collision(hkl3d);
	check_no_collision(hkl3d);

	hkl3d_free(hkl3d);
	hkl_geometry_free(geometry);

	return 0;
}
