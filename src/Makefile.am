## Process this file with automake to produce Makefile.in

AM_VALAFLAGS = --pkg=gsl --header=hkl.h

include_HEADERS=hkl.h

lib_LTLIBRARIES = \
	libhkl.la

libhkl_la_LDFLAGS = -version-info 4:0:0
libhkl_la_LIBS = $(GSL_LIBS) $(GLIB_LIBS)
libhkl_la_CFLAGS = \
	-I$(top_srcdir)/include \
	-I$(top_srcdir)/include/hkl \
	$(GSL_CFLAGS) \
	$(GLIB_CFLAGS)


libhkl_la_SOURCES = \
	hkl-constants.vala \
	hkl-axis.vala \
	hkl-detector.vala \
	hkl-geometry.vala \
	hkl-interval.vala \
	hkl-lattice.vala \
	hkl-matrix.vala \
	hkl-parameter.vala \
	hkl-pseudoaxis.vala \
	hkl-pseudoaxis-auto.vala \
	hkl-pseudoaxis-auto-e4cv.vala \
	hkl-quaternion.vala \
	hkl-sample.vala \
	hkl-source.vala \
	hkl-unit.vala \
	hkl-vector.vala
