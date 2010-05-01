## Process this file with automake to produce Makefile.in

AM_VALAFLAGS = --pkg=gsl --header=hkl.h

AM_LDFLAGS = -no-undefined -version-info 4:0:0
AM_LIBS = $(GSL_LIBS) $(GLIB_LIBS)
AM_CFLAGS = -Wmissing-declarations -std=c89 -ansi -pedantic \
	-I$(top_srcdir) \
	$(GSL_CFLAGS) \
	$(GLIB_CFLAGS)

include_HEADERS=hkl.h

lib_LTLIBRARIES = \
	libhkl.la

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
	hkl-pseudoaxis-auto-eulerians.vala \
	hkl-pseudoaxis-auto-hkl.vala \
	hkl-pseudoaxis-auto-psi.vala \
	hkl-pseudoaxis-auto-q.vala \
	hkl-pseudoaxis-auto-e4cv.vala \
	hkl-pseudoaxis-auto-k4cv.vala \
	hkl-pseudoaxis-auto-e6c.vala \
	hkl-pseudoaxis-auto-k6c.vala \
	hkl-quaternion.vala \
	hkl-sample.vala \
	hkl-source.vala \
	hkl-unit.vala \
	hkl-vector.vala

# Support for GNU Flymake, in Emacs.
check-syntax: AM_CFLAGS += -fsyntax-only -pipe
check-syntax:
	test -z "$(CHK_SOURCES)" || $(COMPILE) $(CHK_SOURCES)

.PHONY: check-syntax
