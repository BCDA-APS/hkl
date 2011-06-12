.. _development:

Developpement
#############

Getting hkl
***********

To get hkl, you can download the last stable version from sourceforge or if you
want the latest development version use `git <http://git.or.cz/>`_ or
`msysgit <http://code.google.com/p/msysgit/downloads/list>`_ on windows system and
do::

	$ git clone git://repo.or.cz/hkl.git

or::

	$ git clone http://repo.or.cz/r/hkl.git (slower)

then checkout the next branch like this::

	$ cd hkl
	$ git checkout -b next origin/next

Building hkl
************

To build hkl you need `Python 2.3+ <http://www.python.org>`_ and the
`GNU Scientific Library 1.12 <http://www.gnu.org/software/gsl/>`_::

     $ ./configure --disable-ghkl
     $ make
     $ sudo make install

you can also build a GUI interfaces which use `gtkmm <http://www.gtkmm.org>`_::

    $ ./configure
    $ make
    $ sudo make install

eventually if you want to work also on the documentation you need:

+ `gtk-doc <http://www.gtk.org/gtk-doc/>`_ for the api
+ `sphinx <http://sphinx.pocoo.org/>`_ for the html and latex doc.
+ `asymptote <http://asymptote.sourceforge.net/>`_ for the figures.::

  $ ./configure --enable-gtk-doc
  $ make
  $ make html

Hacking hkl
***********

you can send your patch to `Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>`_ using
``git``

The developpement process is like this. Suppose you wan to add a new feature to
hkl create first a new branch from the next one::

    $ git checkout -b my-next next

hack, hack::

     $ git commit -a

more hacks::

     $ git commit -a

now that your new feature is ready for a review, you can send by
email your work using git format-patch::

     $ git format-patch origin/next

and send generated files `0001_xxx`, `0002_xxx`, ... to the author.

Howto add a diffractometer
**************************

In this section we will describe all steps requiered to add a new
diffractometer. We will use the kappa 4 circles exemple.

Adding Geometry
===============

.. highlight:: c
   :linenothreshold: 5

The first thing to do is to add the Geometry of this
diffractometer. You need to edit the `hkl/hkl-geometry-factory.h` file

add a new type ``HKL_GEOMETRY_KAPPA4C_VERTICAL`` into the ``_HklGeometryType`` enum::

    enum _HklGeometryType
    {
	...
	HKL_GEOMETRY_KAPPA4C_VERTICAL
    }

Now you must describe the diffractometer axes and the way they are
connected all togethers.  This diffractometer have one sample holder
and one detecter holder and four axes ("komega", "kappa", "kphi" and
"tth") So you need to add a new init method for this diffractometer.::

       static void hkl_geometry_init_kappa4C_vertical(HklGeometry *self, double alpha)
       {
		HklHolder *h;

		self->name = "K4CV";
		h = hkl_geometry_add_holder(self);
		hkl_holder_add_rotation_axis(h, "komega", 0, -1, 0);
		hkl_holder_add_rotation_axis(h, "kappa", 0, -cos(alpha), -sin(alpha));
		hkl_holder_add_rotation_axis(h, "kphi", 0, -1, 0);

		h = hkl_geometry_add_holder(self);
		hkl_holder_add_rotation_axis(h, "tth", 0, -1, 0);
	}

first we set the diffractometer name by::

      self->name = "K4CV";

This name is used in the Tango diffractometer device to refer to this
diffractometer.

Then you can create the first holder with it's three axes. The order
of the axis is from the farest to the closest of the sample. In this
case, komega -> kappa -> kphi::

      h = hkl_geometry_add_holder(self);
      hkl_holder_add_rotation_axis(h, "komega", 0, -1, 0);
      hkl_holder_add_rotation_axis(h, "kappa", 0, -cos(alpha), -sin(alpha));
      hkl_holder_add_rotation_axis(h, "kphi", 0, -1, 0);

Same thing for the other holder holding the detector::

     h = hkl_geometry_add_holder(self);
     hkl_holder_add_rotation_axis(h, "tth", 0, -1, 0);

now it is almost finish for the geometry part. you just need to add it
in the factory::

   Hklgeometry *hkl_geometry_factory_new(HklGeometryType type, ...)
   {
	...
	switch(type){
		...
		case HKL_GEOMETRY_KAPPA4C_VERTICAL:
			va_start(ap, type);
			alpha = va_arg(ap, double);
			va_end(ap);
			hkl_geometry_init_kappa4C_vertical(geom, alpha);
		break;
	}
	...
   }

in this exemple the geometry take one parameter. The fatory can have a
variable number of parameters you just need to take care of this with
the va_arg methods.

Adding PseudoAxis mode
======================

Suppose you want to add a new mode to the hkl pseudo axes. Lets call
it ``psi constant vertical`` to the eulerian 6 circle geometry.

The starting point is to look in the file ``src/hkl-pseudoaxis-factory.c`` for::

    HklPseudoAxisEngineList *hkl_pseudo_axis_engine_list_factory(HklGeometryType type)

in that method you can see this in the eulerian 6 circle part::

   case HKL_GEOMETRY_EULERIAN6C:
	hkl_pseudo_axis_engine_list_add(self, hkl_pseudo_axis_engine_e6c_hkl_new());
	hkl_pseudo_axis_engine_list_add(self, hkl_pseudo_axis_engine_e6c_psi_new());
	hkl_pseudo_axis_engine_list_add(self, hkl_pseudo_axis_engine_q2_new());
   break;

so as you can see there is three pseudo axis engine for this
geometry. Your mode if for the hkl pseudo axis. so let look in the
``hkl_pseudo_axis_engine_e6c_hkl_new()`` method.  You can find it
in the file ``include/hkl/hkl-pseudoaxis-e6c.h`` which contain this::

   #ifndef __HKL_PSEUDOAXIS_E6C_H__
   #define __HKL_PSEUDOAXIS_E6C_H__

   #include <hkl/hkl-pseudoaxis-auto.h>

   HKL_BEGIN_DECLS

   extern HklPseudoAxisEngine *hkl_pseudo_axis_engine_e6c_hkl_new(void);
   extern HklPseudoAxisEngine *hkl_pseudo_axis_engine_e6c_psi_new(void);

   HKL_END_DECLS

   #endif /* __HKL_PSEUDOAXIS_E6C_H__ */

strange only 2 methods nothing about
``hkl_pseudo_axis_engine_q2_new()``. This is because the
implementation of this method is common to more than one geometry. So
you can find it in the file ``hkl/hkl-pseudoaxis-common-q.h``

now you need to change the code of
``hkl_pseudo_axis_engine_e6c_hkl_new(void)``. Lets look about it in
the file ``src/hkl-pseudoaxis-e6c-hkl.c``::

    HklPseudoAxisEngine *hkl_pseudo_axis_engine_e6c_hkl_new(void)
    {
	HklPseudoAxisEngine *self;
	HklPseudoAxisEngineMode *mode;

	self = hkl_pseudo_axis_engine_hkl_new();

	/* bissector_vertical */
	mode = hkl_pseudo_axis_engine_mode_new(
		"bissector_vertical",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_setter_func_bissector_vertical,
		0,
		4, "omega", "chi", "phi", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* constant_omega_vertical */
	mode = hkl_pseudo_axis_engine_mode_new(
		"constant_omega_vertical",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_hkl_real,
		0,
		3, "chi", "phi", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* constant_chi_vertical */
	mode = hkl_pseudo_axis_engine_mode_new(
		"constant_chi_vertical",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_hkl_real,
		0,
		3, "omega", "phi", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* constant_phi_vertical */
	mode = hkl_pseudo_axis_engine_mode_new(
		"constant_phi_vertical",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_hkl_real,
		0,
		3, "omega", "chi", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* lifting_detector_phi */
	mode = hkl_pseudo_axis_engine_mode_new(
		"lifting_detector_phi",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_hkl_real,
		0,
		3, "phi", "gamma", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* lifting_detector_omega */
	mode = hkl_pseudo_axis_engine_mode_new(
		"lifting_detector_omega",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_hkl_real,
		0,
		3, "omega", "gamma", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* lifting_detector_mu */
	mode = hkl_pseudo_axis_engine_mode_new(
		"lifting_detector_mu",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_hkl_real,
		0,
		3, "mu", "gamma", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* double_diffraction vertical*/
	HklParameter h2;
	HklParameter k2;
	HklParameter l2;

	hkl_parameter_init(&h2, "h2", -1, 1, 1,
			   HKL_TRUE, HKL_TRUE,
			   NULL, NULL);
	hkl_parameter_init(&k2, "k2", -1, 1, 1,
			   HKL_TRUE, HKL_TRUE,
			   NULL, NULL);
	hkl_parameter_init(&l2, "l2", -1, 1, 1,
			   HKL_TRUE, HKL_TRUE,
			   NULL, NULL);

	mode = hkl_pseudo_axis_engine_mode_new(
		"double_diffraction_vertical",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_double_diffraction_real,
		3, &h2, &k2, &l2,
		4, "omega", "chi", "phi", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* bissector_horizontal */
	mode = hkl_pseudo_axis_engine_mode_new(
		"bissector_horizontal",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_setter_func_bissector_horizontal,
		0,
		5, "mu", "omega", "chi", "phi", "gamma");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	/* double_diffraction_horizontal */
	mode = hkl_pseudo_axis_engine_mode_new(
		"double_diffraction_horizontal",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_double_diffraction_real,
		3, &h2, &k2, &l2,
		4, "mu", "chi", "phi", "gamma");
	hkl_pseudo_axis_engine_add_mode(self, mode);

	hkl_pseudo_axis_engine_select_mode(self, 0);

	return self;
    }

so you "just" need to add a new mode like this::

	/* double_diffraction_horizontal */
	mode = hkl_pseudo_axis_engine_mode_new(
		"psi_constant_vertical",
		NULL,
		hkl_pseudo_axis_engine_mode_get_hkl_real,
		hkl_pseudo_axis_engine_mode_set_psi_constant_vertical,
		3, &h2, &k2, &l2,
		4, "omega", "chi", "phi", "delta");
	hkl_pseudo_axis_engine_add_mode(self, mode);

So the first parameter of the hkl_pseudo_axis_engine_mode_new method

+ name is the name of the mode
+ then the init functions (usually you need to store the current state of the geometry to be able to use the pseudo axis). Here no need for this init method so we put ``NULL``.

+ then the get method which compute for a given geometry the pseudo axis value. the hkl get method ``hkl_pseudo_axis_engine_mode_get_hkl_real`` is completely generic and do not depend of the geometry. No need to write it.

+ then the set method which compute a geometry for the given pseudo axis values. Now you need to work a little bit and write the set method.

+ the parameters of your mode

  + first the number of parameters : 3
  + then each parameters (pointer on the right parameters) for this mode we have 3 parameters h2, k2, l2 which are the coordinates of a sample reference direction use to compute the psi value.

+ the name of axes used by the set method.

  + first the number of axes used by the set method : 4
  + then all axes names.

In fact the "set" method know nothing about the axes names, so you can
use a set method with different kind of geometries. The association is
only done during the mode creation.

At the end you need to add this mode to the pseudo axis engine with
``hkl_pseudo_axis_engine_add_mode(self, mode);``

that's all.

Now let see how this "set" method could be written. In our case we
want to compute the geometry angles for a given h, k, l pseudo axis
values keeping the angle between the reference reciprocal space vector
(h2, k2, l2) and the diffraction plane defined by the incomming beam
and the outgoing beam::

	    static int hkl_pseudo_axis_engine_mode_set_psi_constant_vertical(HklPseudoAxisEngine *engine,
									     HklGeometry *geometry,
								             HklDetector *detector,
								             HklSample *sample)
	    {
		hkl_pseudo_axis_engine_prepare_internal(engine, geometry, detector,
							sample);

		return hkl_pseudo_axis_engine_solve_function(engine, psi_constant_vertical);
	    }

the prepare internal part is about initializing the solver with the
given geometry, detector and sample. Then comes the
hkl_pseudo_axis_engine_solve_function which need the
psi_constant_vertical function to work. This method use the GSL
library to find the given function roots (where f(x) = 0).  Lets see
how it works for the "bissector_horizontal" mode::

    static int bissector_horizontal(const gsl_vector *x, void *params, gsl_vector *f)
    {
	double mu, omega, gamma;
	double const *x_data = gsl_vector_const_ptr(x, 0);
	double *f_data = gsl_vector_ptr(f, 0);

	RUBh_minus_Q(x_data, params, f_data);

	mu = x_data[0];
	omega = x_data[1];
	gamma = x_data[4];

	f_data[3] = omega;
	f_data[4] = gamma - 2 * fmod(mu, M_PI);

	return  GSL_SUCCESS;
    }

The bissector_horizotal method is used by the setter method of the
mode to compute the right set of axes angles corresponding to the
pseudo axes values you want to reach. This method compute the
difference between these pseudo axes values and the ones computed from
the axes angles. It can be decompose in three parts:

The first three of these equations are given for the function
``RUBH_minus_Q``: they are the diference between the h,k,l values that
want to be set and the h,k,l values computed for a possible
combination of angles::

	    f_data[0] = h-h(x)
	    f_data[1] = k-k(x)
	    f_data[2] = l-l(x)

As the bissector_horizontal mode use 5 axes you need to find 2 other
equations to be able to solve your mode. The first one is :math:`omega
= 0`} for an horizontal mode::

  f_data[3] = omega

and the last one is for the bissector parameter :math:`gamma=2*mu`::

    f_data[4] = gamma - 2 * fmod(mu, M_PI)

One question could be why this complicate ``f4 = gamma - 2 * fmod(mu,
M_PI)`` equation instead of a simpler ``f4 = gamma - 2 * mu`` ?  this
is because the bissector_horizontal method is also called by a
solution multiplicator to gives the user plenty of equivalent
solutions. This multiplicator do some operations like ``omega = pi -
omega`` or ``omega = - omega`` on the axes.  Then it check that the
new angles combination gives also :math:`f(x) = 0`. This is the
explaination of this more complicate equation.

So in our case we need to build something like::

   static int psi_constant_vertical(const gsl_vector *x, void *params, gsl_vector *f)
   {
	double mu, omega, gamma;
	double const *x_data = gsl_vector_const_ptr(x, 0);
	double *f_data = gsl_vector_ptr(f, 0);

	RUBh_minus_Q(x_data, params, f_data);

	f_data[3] = ???;

	return  GSL_SUCCESS;
    }

The missing part is about the psi computation. ``f3 = psi (target) -
psi(x)``.  Calculation psi is done in the psi pseudo axis common
part::

	   static int psi(const gsl_vector *x, void *params, gsl_vector *f)

This psi method is the equivalent of psi_constant_vertical. So you
need to factorize the psi calculation in between psi_constant_vertical
and psi.
