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
 * Copyright (C) 2003-2020 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
#include <time.h>
#include "hkl-binoculars.h"
#include "ccan/array_size/array_size.h"
#include "hkl-geometry-private.h"
#include "hkl-matrix-private.h"
#include "hkl-quaternion-private.h"
#include "hkl-vector-private.h"

inline int32_t min(int32_t x, int32_t y)
{
	return y ^ ((x ^ y) & -(x < y));
}

inline int32_t max(int32_t x, int32_t y)
{
	return x ^ ((x ^ y) & -(x < y));
}

static int axis_size(const HklBinocularsAxis *self)
{
	return self->imax - self->imin + 1;
}

static double axis_min(const HklBinocularsAxis *self)
{
	return self->imin * self->resolution;
}

static double axis_max(const HklBinocularsAxis *self)
{
	return self->imax * self->resolution;
}

static void hkl_binoculars_axis_init(HklBinocularsAxis *self,
				     const char *name,
				     int index,
				     int imin,
				     int imax,
				     double resolution)
{
	self->name = name;
	self->index = index;
	self->resolution = resolution;
	self->imin = imin;
	self->imax = imax;
}

double *hkl_binoculars_axis_array(const HklBinocularsAxis *self)
{
	double *arr = malloc(6 * sizeof(*arr));

	arr[0] = self->index;
	arr[1] = axis_min(self);
	arr[2] = axis_max(self);
	arr[3] = self->resolution;
	arr[4] = self->imin;
	arr[5] = self->imax;

	return arr;
}
static void hkl_binoculars_axis_merge(HklBinocularsAxis *self, const HklBinocularsAxis *other)
{
	self->imin = min(self->imin, other->imin);
	self->imax = max(self->imax, other->imax);
}

void hkl_binoculars_axis_fprintf(FILE *f, const HklBinocularsAxis *self)
{
	fprintf(f, "%s : %d min: %f max: %f res: %f size: %d",
		self->name, self->index,
		axis_min(self), axis_max(self),
		self->resolution, axis_size(self));
}

HklBinocularsSpace *space_new(int32_t n_indexes_0, int32_t n_axes)
{
	HklBinocularsSpace *self = malloc(sizeof(*self));

	self->n_indexes_0 = n_indexes_0;
	self->indexes_0 = malloc(n_indexes_0 * n_axes * sizeof(*self->indexes_0));
	self->n_axes = n_axes;
	self->axes = malloc(sizeof(*self->axes) * n_axes);

	return self;
}

void hkl_binoculars_space_free(HklBinocularsSpace *self)
{
	free(self->axes);
	free(self->indexes_0);
	free(self);
}

void hkl_binoculars_space_fprintf(FILE *f, const HklBinocularsSpace *self)
{
	uint32_t i;

	fprintf(f, "'self: %p\n", self);
	fprintf(f, "n_indexes_0: %d\n", self->n_indexes_0);
	fprintf(f, "n_axes: %d", self->n_axes);
	for(i=0; i<self->n_axes; ++i){
		fprintf(f, "\n");
		hkl_binoculars_axis_fprintf(f, &self->axes[i]);
	}
}

static inline int32_t *space_indexes(const HklBinocularsSpace *space, int index)
{
	return &space->indexes_0[index * space->n_indexes_0];
}

static inline void space_update_axes(HklBinocularsSpace *space,
                                     const char *names[],
                                     int32_t n_pixels,
                                     const double resolutions[])
{
        int32_t i;
        int32_t j;

	/* compress the coordinates into the space */
	for(i=0; i<space->n_axes; ++i){
		const int32_t *idx = space_indexes(space, i);
		const double resolution = resolutions[i];
		HklBinocularsAxis *axis = &space->axes[i];
		int32_t origin = idx[0];
		int32_t last = idx[0];

		for(j=1; j<n_pixels; ++j){
			int32_t index = idx[j];

			origin = min(origin, index);
			last = max(last, index);
		}
		hkl_binoculars_axis_init(axis, names[i], i, origin, last, resolution);
	}
}

/* the array is pre filled with the pixel coordinates */
HklBinocularsSpace *hkl_binoculars_space_q(const HklGeometry *geometry,
					   double k,
					   const uint16_t *image,
					   int32_t n_pixels,
					   const double *pixels_coordinates,
					   int32_t pixels_coordinates_ndim,
					   const int32_t *pixels_coordinates_dims,
					   const double *resolutions,
					   int32_t n_resolutions)
{
	int32_t i, j;
	const char * names[] = {"qx", "qy", "qz"};

	const double *q_x = &pixels_coordinates[0 * n_pixels];
	const double *q_y = &pixels_coordinates[1 * n_pixels];
	const double *q_z = &pixels_coordinates[2 * n_pixels];

	HklSample *sample = hkl_sample_new("test");
	HklDetector *detector = hkl_detector_factory_new(HKL_DETECTOR_TYPE_0D);
	const HklQuaternion q = hkl_geometry_detector_rotation_get(geometry, detector);
	HklQuaternion qs_1 = hkl_geometry_sample_rotation_get(geometry, sample);
	const HklVector ki = hkl_geometry_ki_get(geometry);
	hkl_quaternion_conjugate(&qs_1);

	HklBinocularsSpace *space = space_new(n_pixels, ARRAY_SIZE(names));

	/* compute the coordinates in the last axis basis and the
	 * indexes */
	for(i=0;i<n_pixels;++i){
		HklVector v = {{ q_x[i],
				 q_y[i],
				 q_z[i]}};

		hkl_vector_rotated_quaternion(&v, &q);
		hkl_vector_normalize(&v);
		hkl_vector_minus_vector(&v, &ki);
		hkl_vector_rotated_quaternion(&v, &qs_1);
		hkl_vector_times_double(&v, k);

                for(j=0; j<ARRAY_SIZE(names); ++j)
                        space_indexes(space, j)[i] = rint(v.data[j] / resolutions[j]);
	}

        space_update_axes(space, names, n_pixels, resolutions);

	hkl_detector_free(detector);
        hkl_sample_free(sample);

	return space;
}

/* the array is pre filled with the pixel coordinates */
HklBinocularsSpace *hkl_binoculars_space_hkl(const HklGeometry *geometry,
                                             const HklSample *sample,
                                             double K,
                                             const uint16_t *image,
                                             int32_t n_pixels,
                                             const double *pixels_coordinates,
                                             int32_t pixels_coordinates_ndim,
                                             const int32_t *pixels_coordinates_dims,
                                             const double *resolutions,
                                             int32_t n_resolutions)
{
	int32_t i, j;
	const char * names[] = {"h", "k", "l"};

        const double *h = &pixels_coordinates[0 * n_pixels];
	const double *k = &pixels_coordinates[1 * n_pixels];
	const double *l = &pixels_coordinates[2 * n_pixels];

	HklDetector *detector = hkl_detector_factory_new(HKL_DETECTOR_TYPE_0D);
	const HklQuaternion q_d = hkl_geometry_detector_rotation_get(geometry, detector);
	HklQuaternion qs = hkl_geometry_sample_rotation_get(geometry, sample);
	const HklVector ki = hkl_geometry_ki_get(geometry);
        HklMatrix RUB;
        HklMatrix RUB_1;
        hkl_quaternion_to_matrix(&qs, &RUB);
	hkl_matrix_times_matrix(&RUB, hkl_sample_UB_get(sample));
        hkl_matrix_inv(&RUB, &RUB_1);

	HklBinocularsSpace *space = space_new(n_pixels, ARRAY_SIZE(names));

	/* compute the coordinates in the last axis basis and the
	 * indexes */
	for(i=0;i<n_pixels;++i){
		HklVector v = {{ h[i], k[i], l[i]}};

		hkl_vector_rotated_quaternion(&v, &q_d);
		hkl_vector_normalize(&v);
		hkl_vector_minus_vector(&v, &ki);
		hkl_vector_times_double(&v, K);
                hkl_matrix_times_vector(&RUB_1, &v);

                for(j=0; j<ARRAY_SIZE(names); ++j)
                        space_indexes(space, j)[i] = rint(v.data[j] / resolutions[j]);
	}

        space_update_axes(space, names, n_pixels, resolutions);

	hkl_detector_free(detector);
        hkl_sample_free(sample);

	return space;
}

static inline HklBinocularsCube *empty_cube(int32_t n_axes)
{
        HklBinocularsCube *self = malloc(sizeof(HklBinocularsCube));

	/* compute the final cube dimensions and the index offset */
	self->n_axes = n_axes;
	self->axes = calloc(n_axes, sizeof(HklBinocularsAxis));
        self->photons = NULL;
        self->contributions = NULL;

        return self;
}

static inline size_t cube_size(const HklBinocularsCube *self)
{
	int i;
	size_t n = 1;

	for(i=0; i<self->n_axes; ++i)
		n *= axis_size(&self->axes[i]);
	return n;
}

static inline size_t malloc_cube(HklBinocularsCube *self)
{
        size_t n = cube_size(self);

	self->photons = malloc(n * sizeof(*self->photons));
	self->contributions = malloc(n * sizeof(*self->contributions));

        return n;
}

static inline size_t calloc_cube(HklBinocularsCube *self)
{
        size_t n = cube_size(self);

	self->photons = calloc(n, sizeof(*self->photons));
	self->contributions = calloc(n, sizeof(*self->contributions));

        return n;
}

void hkl_binoculars_cube_free(HklBinocularsCube *self)
{
	free(self->contributions);
	free(self->photons);
	free(self->axes);
	free(self);
}

static int64_t compute_offset(int32_t n_axes, const HklBinocularsAxis *axes)
{
	int i;
	int64_t len = 1;
	int64_t offset = 0;

	for(i=0; i<n_axes; ++i){
		const HklBinocularsAxis *axis = &axes[n_axes-1-i];
		offset += len * axis->imin;
		len *= axis_size(axis);
	}
	return offset;
}

void add_space(HklBinocularsCube *cube,
	       const HklBinocularsSpace *space,
	       int32_t n_pixels,
	       const uint16_t *img,
	       int64_t offset0)
{
	int i;
	int j;
	int64_t len = 1;
	int64_t indexes[n_pixels];

	for(i=0; i<n_pixels; ++i){
		indexes[i] = -offset0;
	}

	for(i=0; i<cube->n_axes; ++i){
		int32_t *idx = space_indexes(space, cube->n_axes - 1 - i);
		for(j=0; j<n_pixels; ++j){
			indexes[j] += len * idx[j];
		}
		len *= axis_size(&cube->axes[cube->n_axes - 1 - i]);
	}

	for(i=0; i<n_pixels; ++i){
		size_t w = indexes[i];
		cube->photons[w] += img[i];
		cube->contributions[w] += 1;
	}
}

void hkl_binoculars_cube_fprintf(FILE *f, const HklBinocularsCube *self)
{
	int i;

	fprintf(f, "HklBinocularsCube: %p\n", self);
	fprintf(f, "n_axes: %d", self->n_axes);
	for(i=0; i<self->n_axes;  ++i){
		fprintf(f, "\n");
		hkl_binoculars_axis_fprintf(f, &self->axes[i]);
	}
	fprintf(f, "photons: %p\n", self->photons);
	fprintf(f, "contributions: %p\n", self->contributions);
}

void hkl_binoculars_cube_dims(const HklBinocularsCube *self, int ndim, int *dims)
{
	int i;

	for(i=0; i<ndim; ++i)
		dims[i] = axis_size(&self->axes[i]);
}

HklBinocularsCube *hkl_binoculars_cube_new(int n_spaces, const HklBinocularsSpace *const *spaces,
					   int32_t n_pixels, const uint16_t **imgs)
{
	int i;
	int j;
	const HklBinocularsSpace *space0 = spaces[0];
	int n_axes = space0->n_axes;
	int64_t offset0;
	HklBinocularsCube *self = empty_cube(n_axes);

	/* compute the final cube dimensions and the index offset */
	for(i=0; i<n_axes; ++i)
		self->axes[i] = space0->axes[i];

	for(i=1; i<n_spaces; ++i){
		for(j=0; j<n_axes; ++j){
			hkl_binoculars_axis_merge(&self->axes[j],
						  &spaces[i]->axes[j]);
		}
	}
	offset0 = compute_offset(n_axes, self->axes);

	/* allocated the final cube photons and contributions */
        calloc_cube(self);

	/* hkl_binoculars_cube_fprintf(stdout, self); */

	/* add all the spaces */
	for(i=0; i<n_spaces; ++i){
		add_space(self, spaces[i], n_pixels, imgs[i], offset0);
	}

	/* hkl_binoculars_cube_fprintf(stdout, self); */

	return self;
}

HklBinocularsCube *hkl_binoculars_cube_new_from_space(const HklBinocularsSpace *space,
                                                      int32_t n_pixels, const uint16_t *img)
{
        int i;
	int64_t offset0 = compute_offset(space->n_axes, space->axes);
	HklBinocularsCube *self = empty_cube(space->n_axes);

	for(i=0; i<self->n_axes; ++i)
		self->axes[i] = space->axes[i];

	/* allocated the final cube */
        calloc_cube(self);

        add_space(self, space, n_pixels, img, offset0);

	return self;
}

HklBinocularsCube *hkl_binoculars_cube_new_copy(const HklBinocularsCube *src)
{
	int i;
        size_t n;
	HklBinocularsCube *self = empty_cube(src->n_axes);

	/* allocate and copy the axis part */
        for(i=0; i<self->n_axes; ++i)
                self->axes[i] = src->axes[i];

	/* allocate the final cube */
        n = malloc_cube(self);

        /* copy the data */
        memcpy(self->photons, src->photons, n * sizeof(*self->photons));
        memcpy(self->contributions, src->contributions, n * sizeof(*self->contributions));

        return self;
}


static inline void cube_add_cube(HklBinocularsCube *self,
                                 const HklBinocularsCube *cube)
{
        if ((NULL == cube->photons) || (NULL == cube->contributions))
                return;

        int i, j, k;
        size_t i_offset, j_offset, k_offset;

        size_t stride_i = 1;
        size_t stride_j = stride_i * axis_size(&self->axes[2]);
        size_t stride_k = stride_j * axis_size(&self->axes[1]);

        /* fill the values of cube */
        size_t stride_i_cube = 1;
        size_t stride_j_cube = stride_i_cube * axis_size(&cube->axes[2]);
        size_t stride_k_cube = stride_j_cube * axis_size(&cube->axes[1]);

        i_offset = cube->axes[2].imin - self->axes[2].imin;
        j_offset = cube->axes[1].imin - self->axes[1].imin;
        k_offset = cube->axes[0].imin - self->axes[0].imin;

        for(k=0; k<axis_size(&cube->axes[0]); ++k){
                for(j=0; j<axis_size(&cube->axes[1]); ++j){
                        for(i=0; i<axis_size(&cube->axes[2]); ++i){
                                size_t w = (i + i_offset) * stride_i + (j + j_offset) * stride_j + (k + k_offset) * stride_k;
                                size_t w1 = i * stride_i_cube + j * stride_j_cube + k * stride_k_cube;

                                self->photons[w] += cube->photons[w1];
                                self->contributions[w] += cube->contributions[w1];
                        }
                }
        }
}

HklBinocularsCube *hkl_binoculars_cube_new_merge(const HklBinocularsCube *cube1,
                                                 const HklBinocularsCube *cube2)
{
        /* for now hardcode the dimension in the code 3D */
        int i;
        HklBinocularsCube *self = empty_cube(cube1->n_axes);

        /* compute the finale cube size */
        for(i=0; i<self->n_axes; ++i){
                self->axes[i] = cube1->axes[i];
                hkl_binoculars_axis_merge(&self->axes[i],
                                          &cube2->axes[i]);
        }
        calloc_cube(self);

        cube_add_cube(self, cube1);
        cube_add_cube(self, cube2);

        return self;
}