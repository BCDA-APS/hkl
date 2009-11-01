## Process this file with automake to produce Makefile.in

ACLOCAL_AMFLAGS = -I m4

DISTCHECK_CONFIGURE_FLAGS=--enable-gtk-doc

SUBDIRS = src test Documentation

EXTRA_DIST = hkl.pc.in

pkgconfigdir = $(libdir)/pkgconfig
pkgconfig_DATA = hkl.pc
