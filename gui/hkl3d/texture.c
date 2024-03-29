/* $Id: texture.c 42 2006-05-22 13:31:45Z mmmaddd $ */

/*
	G3DViewer - 3D object viewer

	Copyright (C) 2005, 2006  Markus Dahms <mad@automagically.de>

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
*/

#ifdef HAVE_CONFIG_H
#	include <config.h>
#endif

#include <stdlib.h>

#include <g3d/g3d.h>

#include "hkl3d-gui-gl.h"

int texture_load_all_textures(G3DModel *model)
{
	if(model == NULL) return EXIT_FAILURE;

	if(model->tex_images != NULL)
		g_hash_table_foreach(model->tex_images,
			gl_load_texture, NULL);

	return EXIT_SUCCESS;
}
