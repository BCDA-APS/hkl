#! /usr/bin/env python
# encoding: utf-8
# Thomas Nagy, 2006-2008 (ita)

import UnitTest, os, Build, Options

# the following two variables are used by the target "waf dist"
VERSION='4.0.0'
APPNAME='hkl'

# these variables are mandatory ('/' are converted automatically)
srcdir = '.'
blddir = 'build'

def set_options(opt):
	opt.tool_options('compiler_cc')
	opt.tool_options('cc')
	opt.tool_options('vala')

def configure(conf):
	conf.check_tool('compiler_cc cc vala')
	conf.check_cfg(package='gsl', atleast_version='1.12')
	conf.check_cfg(package='glib-2.0', uselib_store='GLIB', atleast_version='2.10.0', mandatory=1, args='--cflags --libs')
	conf.env['HKL_VERSION'] = VERSION.split('-')[0]

def build(bld):
	bld.add_subdirs('src test')
