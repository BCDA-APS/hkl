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
 * Copyright (C) 2003-2023 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#include "hkl-binoculars-private.h"

mat4s hkl_binoculars_parameter_transformation_get(const HklParameter *self)
{
        CGLM_ALIGN_MAT mat4s r = GLMS_MAT4_IDENTITY_INIT;
        HklParameterType type = hkl_parameter_type_get(self);

        match(type){
                of(Parameter) { };
                of(Rotation, axis_v) {
                        CGLM_ALIGN_MAT vec3s axis = {{axis_v->data[0], axis_v->data[1], axis_v->data[2]}};

                        r = glms_rotate_make(self->_value, axis);
                }
                of(RotationWithOrigin, axis_v, pivot_v) {
                        CGLM_ALIGN_MAT mat4s m = glms_mat4_identity();
                        CGLM_ALIGN_MAT vec3s pivot = {{pivot_v->data[0], pivot_v->data[1], pivot_v->data[2]}};
                        float angle = self->_value;
                        CGLM_ALIGN_MAT vec3s axis = {{axis_v->data[0], axis_v->data[1], axis_v->data[2]}};

                        r = glms_rotate_atm(m, pivot, angle, axis);
                }
                of(Translation, v_v) {
                        CGLM_ALIGN_MAT vec3s v = {{v_v->data[0], v_v->data[1], v_v->data[2]}};
                        r = glms_translate_make(v);
                }
        }

        return r;
}


mat4s hkl_binoculars_holder_transformation_get(const HklHolder *self)
{
        CGLM_ALIGN_MAT mat4s r = GLMS_MAT4_IDENTITY_INIT;
        size_t i;

	/* for each axis from the end apply the transformation to the vector */
	for(i=0;i<self->config->len;i++){
		HklParameter *p = darray_item(self->geometry->axes, self->config->idx[i]);

                r = glms_mat4_mul(r, hkl_binoculars_parameter_transformation_get(p));
	}

	return r;
}