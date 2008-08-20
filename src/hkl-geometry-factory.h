#ifndef __HKL_GEOMETRY_FACTORY_H__
#define __HKL_GEOMETRY_FACTORY_H__

#include <stdarg.h>
#include <hkl-geometry.h>
#include <hkl-holder.h>
#include <hkl-macros.h>

HKL_BEGIN_DECLS

typedef enum _HklGeometryType HklGeometryType;

enum _HklGeometryType
{
	HKL_GEOMETRY_TWOC_VERTICAL,
	HKL_GEOMETRY_EULERIAN4C_VERTICAL,
	HKL_GEOMETRY_KAPPA4C_VERTICAL,
	HKL_GEOMETRY_EULERIAN6C,
	HKL_GEOMETRY_KAPPA6C,
};

static HklGeometry *hkl_geometry_factory_new(HklGeometryType type, ...)
{
	HklGeometry *geom;
	double alpha;
	va_list ap;

	switch(type) {
		case HKL_GEOMETRY_TWOC_VERTICAL:
			geom = hkl_geometry_new_TwoCV();
			break;
		case HKL_GEOMETRY_EULERIAN4C_VERTICAL:
			geom = hkl_geometry_new_E4CV();
			break;
		case HKL_GEOMETRY_KAPPA4C_VERTICAL:
			va_start(ap, type);
			alpha = va_arg(ap, double);
			va_end(ap);
			geom = hkl_geometry_new_K4CV(alpha);
			break;
		case HKL_GEOMETRY_EULERIAN6C:
			geom = hkl_geometry_new_E6C();
			break;
		case HKL_GEOMETRY_KAPPA6C:
			va_start(ap, type);
			alpha = va_arg(ap, double);
			va_end(ap);
			geom = hkl_geometry_new_K6C(alpha);
			break;
	}

	return geom;
}

HKL_END_DECLS

#endif /* __HKL_GEOMETRY_FACTORY_H__ */
