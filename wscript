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
	opt.tool_options('compiler_cc vala misc')
	opt.add_option('--soleil', action='store_true', default=False, help='Build for the Soleil site')

def configure(conf):
	conf.check_tool('compiler_cc vala')
	conf.check_cfg(package='gsl', atleast_version='1.12', mandatory=1, args='--cflags --libs')
	conf.check_cfg(package='gobject-2.0', uselib_store='GOBJECT', atleast_version='2.12.0', mandatory=1, args='--cflags --libs')
	conf.env['HKL_VERSION'] = VERSION.split('-')[0]

def build(bld):
	bld.add_subdirs('src test')

def shutdown():
	# Unit tests are run when "check" target is used
	ut = UnitTest.unit_test()
	ut.change_to_testfile_dir = True
	ut.want_to_see_test_output = True
	ut.want_to_see_test_error = True
	ut.run()
	ut.print_results()
