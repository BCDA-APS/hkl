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
 * Copyright (C) 2003-2009 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#ifndef __HKL_DETECTOR_H__
#define __HKL_DETECTOR_H__

#include <hkl/hkl-geometry.h>

HKL_BEGIN_DECLS

typedef struct _HklDetector HklDetector;

struct _HklDetector
{
	size_t idx;
	HklHolder const *holder;
};

extern HklDetector *hkl_detector_new(void);

extern HklDetector *hkl_detector_new_copy(HklDetector const *src);

extern void hkl_detector_free(HklDetector *self);

extern void hkl_detector_attach_to_holder(HklDetector *self, HklHolder const *holder);

extern int hkl_detector_compute_kf(HklDetector const *self, HklGeometry *g,
				   HklVector *kf);

HKL_END_DECLS

#endif /* __HKL_DETECTOR_H__ */
