SUBDIRS = tap .
if HAVE_INTROSPECTION
SUBDIRS += bindings
endif

all_tests = \
	hkl-unit-t \
	hkl-bench-t \
	hkl-axis-t \
	hkl-error-t \
	hkl-pseudoaxis-t \
	hkl-quaternion-t \
	hkl-interval-t \
	hkl-pseudoaxis-e4cv-t \
	hkl-pseudoaxis-e4ch-t \
	hkl-sample-t \
	hkl-lattice-t \
	hkl-pseudoaxis-e6c-t \
	hkl-source-t \
	hkl-detector-t \
	hkl-matrix-t \
	hkl-pseudoaxis-k4cv-t \
	hkl-vector-t \
	hkl-geometry-t \
	hkl-parameter-t \
	hkl-pseudoaxis-k6c-t \
	hkl-pseudoaxis-zaxis-t \
	hkl-pseudoaxis-soleil-sixs-med-t

AM_CPPFLAGS = -Wextra -pedantic -D_BSD_SOURCE \
	-I$(top_srcdir) \
	-I$(top_srcdir)/hkl \
	-I$(top_srcdir)/tests

LDADD = $(top_builddir)/hkl/libhkl.la \
	$(top_builddir)/tests/tap/libtap.a \
	$(GSL_LIBS)

AM_LDFLAGS=-static

if HKL3D

all_tests += hkl3d-test-t

AM_CPPFLAGS += -I$(top_srcdir)/hkl3d \
	$(G3D_CFLAGS)

LDADD += $(top_builddir)/hkl3d/libhkl3d.la

endif

check_PROGRAMS = runtests $(all_tests)

## tap tests

check-local: $(check_PROGRAMS)
	./runtests -s $(abs_top_srcdir) $(all_tests)

# Support for GNU Flymake, in Emacs.
check-syntax: AM_CFLAGS += -fsyntax-only -pipe
check-syntax:
	test -z "$(CHK_SOURCES)" || $(COMPILE) $(CHK_SOURCES)

.PHONY: check-syntax