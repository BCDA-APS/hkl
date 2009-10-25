TESTS = $(check_PROGRAMS)

check_PROGRAMS = test bench

test_SOURCES = \
hkl-test.h \
hkl-test-pseudoaxis.c \
hkl-test-quaternion.c \
hkl-test-axis.c \
hkl-test-interval.c \
hkl-test-pseudoaxis-e4cv.c \
hkl-test-sample.c \
hkl-test.c \
hkl-test-lattice.c \
hkl-test-pseudoaxis-e6c.c \
hkl-test-source.c \
hkl-test-detector.c \
hkl-test-matrix.c \
hkl-test-pseudoaxis-k4cv.c \
hkl-test-vector.c \
hkl-test-geometry.c \
hkl-test-parameter.c \
hkl-test-pseudoaxis-k6c.c \
main.c

test_LDADD = $(top_builddir)/src/libhkl.la $(GSL_LIBS) $(GLIB_LIBS)
test_CFLAGS = $(GSL_CFLAGS) $(GLIB_CFLAGS)
test_CPPFLAGS = -I$(top_srcdir)/src

bench_SOURCES = \
	bench.c

bench_LDADD = $(top_builddir)/src/libhkl.la $(GSL_LIBS) $(GLIB_LIBS)
bench_CFLAGS = $(GSL_CFLAGS) $(GLIB_CFLAGS)
bench_CPPFLAGS = -I$(top_srcdir)/src
