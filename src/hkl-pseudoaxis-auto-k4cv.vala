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
 * Copyright (C) 2003-2009 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 *          Maria-Teresa Nunez-Pardo-de-Verra <tnunez@mail.desy.de>
 */

using Gsl;

/******************/
/* Bissector mode */
/******************/

static int bissector_f1_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double komega, tth, kappa, omega;
	int i;

	for(i=0; i<x.size; ++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	komega = x.data[0];
	kappa = x.data[1];
	tth = x.data[3];

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50.0 * Hkl.DEGTORAD)) + Math.PI_2;

	f.data[3] = Math.fmod(tth - 2.0 * Math.fmod(omega, Math.PI), 2.0*Math.PI);

	return  Gsl.Status.SUCCESS;
}

static int bissector_f2_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double komega, tth, kappa, omega;
	size_t i;
	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	komega = x.data[0];
	kappa = x.data[1];
	tth = x.data[3];

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50.0 * Hkl.DEGTORAD)) - Math.PI_2;

	f.data[3] = Math.fmod(tth - 2 * Math.fmod(omega, Math.PI), 2.0*Math.PI);

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklKappaBissector : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklKappaBissector(PseudoAxisEngineHkl engine,
						     string name, string[] axes_names)
	{
		base(engine, name, axes_names);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		bool status = false;
		Gsl.MultirootFunction f1 = {bissector_f1_func, 4, this.engine};
		Gsl.MultirootFunction f2 = {bissector_f2_func, 4, this.engine};

		this.engine.prepare_internal(geometry, detector, sample);
		status |= this.engine.solve_function(f1);
		status |= this.engine.solve_function(f2);

		return status;
	}
}

/***********************/
/* Constant omega mode */
/***********************/

static int constant_omega_f1_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double komega, kappa, omega;
	Hkl.PseudoAxisEngineHkl *engine = params;
	Hkl.PseudoAxisEngineModeHklKappaConstantOmega *mode = engine->mode;

	uint i=0U;
	for(i=0;i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	komega = x.data[0];
	kappa = x.data[1];

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50.0 * Hkl.DEGTORAD)) - Math.PI_2;

	f.data[3] = mode->omega.value - omega;

	return  Gsl.Status.SUCCESS;
}

static int constant_omega_f2_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double komega, kappa, omega;
	Hkl.PseudoAxisEngineHkl *engine = params;
	Hkl.PseudoAxisEngineModeHklKappaConstantOmega *mode = engine->mode;

	uint i=0U;
	for(i=0;i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	komega = x.data[0];
	kappa = x.data[1];

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50.0 * Hkl.DEGTORAD)) + Math.PI_2;

	f.data[3] = mode->omega.value - omega;

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklKappaConstantOmega : Hkl.PseudoAxisEngineModeHkl
{
	public unowned Parameter omega;

	public PseudoAxisEngineModeHklKappaConstantOmega(PseudoAxisEngineHkl engine,
							 string name, string[] axes_names)
	{
		base(engine, name, axes_names);

		this.omega = this.add_parameter(
			new Parameter("omega", -Math.PI, 0.0, Math.PI,
				      false, true,
				      hkl_unit_angle_rad, hkl_unit_angle_deg)
			);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		bool status = false;
		Gsl.MultirootFunction f1 = {constant_omega_f1_func, 4, this.engine};
		Gsl.MultirootFunction f2 = {constant_omega_f2_func, 4, this.engine};

		this.engine.prepare_internal(geometry, detector, sample);
		status |= this.engine.solve_function(f1);
		status |= this.engine.solve_function(f2);

		return status;
	}
}

/*********************/
/* Constant chi mode */
/*********************/

static int constant_chi_f1_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double kappa, chi;
	Hkl.PseudoAxisEngineHkl *engine = params;
	Hkl.PseudoAxisEngineModeHklKappaConstantChi *mode = engine->mode;

	uint i=0U;
	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	kappa = x.data[1];

	chi = 2.0 * Math.asin(Math.sin(kappa/2.0) * Math.sin(50.0 * Hkl.DEGTORAD));

	f.data[3] = mode->chi.value - chi;

	return  Gsl.Status.SUCCESS;
}

static int constant_chi_f2_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double kappa, chi;
	Hkl.PseudoAxisEngineHkl *engine = params;
	Hkl.PseudoAxisEngineModeHklKappaConstantChi *mode = engine->mode;

	uint i=0U;
	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	kappa = x.data[1];

	chi = -2.0 * Math.asin(Math.sin(kappa/2.0) * Math.sin(50.0 * Hkl.DEGTORAD));

	f.data[3] = mode->chi.value - chi;

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklKappaConstantChi : Hkl.PseudoAxisEngineModeHkl
{
	public unowned Parameter chi;

	public PseudoAxisEngineModeHklKappaConstantChi(PseudoAxisEngineHkl engine,
						       string name, string[] axes_names)
	{
		base(engine, name, axes_names);

		this.chi = this.add_parameter(
			new Parameter("chi", -Math.PI, 0.0, Math.PI,
				      false, true,
				      hkl_unit_angle_rad, hkl_unit_angle_deg)
			);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		bool status = false;
		Gsl.MultirootFunction f1 = {constant_chi_f1_func, 4, this.engine};
		Gsl.MultirootFunction f2 = {constant_chi_f2_func, 4, this.engine};

		this.engine.prepare_internal(geometry, detector, sample);
		status |= this.engine.solve_function(f1);
		status |= this.engine.solve_function(f2);

		return status;
	}
}

/*********************/
/* Constant phi mode */
/*********************/

static int constant_phi_f1_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double kappa, kphi, phi;
	uint i=0U;
	Hkl.PseudoAxisEngineHkl *engine = params;
	Hkl.PseudoAxisEngineModeHklKappaConstantPhi *mode = engine->mode;

	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	kappa = x.data[1];
	kphi = x.data[2];

	phi = kphi + Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD)) + Math.PI_2;

	f.data[3] = mode->phi.value - phi;

	return  Gsl.Status.SUCCESS;
}

static int constant_phi_f2_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double kappa, kphi, phi;
	uint i=0U;
	Hkl.PseudoAxisEngineHkl *engine = params;
	Hkl.PseudoAxisEngineModeHklKappaConstantPhi *mode = engine->mode;

	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	kappa = x.data[1];
	kphi = x.data[2];

	phi = kphi + Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD)) - Math.PI_2;

	f.data[3] = mode->phi.value - phi;

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklKappaConstantPhi : Hkl.PseudoAxisEngineModeHkl
{
	public unowned Parameter phi;

	public PseudoAxisEngineModeHklKappaConstantPhi(PseudoAxisEngineHkl engine,
						       string name, string[] axes_names)
	{
		base(engine, name, axes_names);

		this.phi = this.add_parameter(
			new Parameter("phi", -Math.PI, 0.0, Math.PI,
				      false, true,
				      hkl_unit_angle_rad, hkl_unit_angle_deg)
			);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		bool status = false;
		Gsl.MultirootFunction f1 = {constant_phi_f1_func, 4, this.engine};
		Gsl.MultirootFunction f2 = {constant_phi_f2_func, 4, this.engine};

		this.engine.prepare_internal(geometry, detector, sample);
		status |= this.engine.solve_function(f1);
		status |= this.engine.solve_function(f2);

		return status;
	}
}

/*************************/
/* K4CV PseudoAxisEngine */
/*************************/

public class Hkl.PseudoAxisEngineHklK4CV : Hkl.PseudoAxisEngineHkl
{
	public PseudoAxisEngineHklK4CV()
	{
		base();

		this.add_mode(new PseudoAxisEngineModeHklKappaBissector(
				      this,
				      "bissector", {"komega", "kappa", "kphi", "tth"}));
		this.add_mode(new PseudoAxisEngineModeHklKappaConstantOmega(
				      this,
				      "constant_omega", {"komega", "kappa", "kphi", "tth"}));
		this.add_mode(new PseudoAxisEngineModeHklKappaConstantChi(
				      this,
				      "constant_chi", {"komega", "kappa", "kphi", "tth"}));
		this.add_mode(new PseudoAxisEngineModeHklKappaConstantPhi(
				      this,
				      "constant_phi", {"komega", "kappa", "kphi", "tth"}));
		this.add_mode(new PseudoAxisEngineModeHklDoubleDiffraction(
				      this,
				      "double_diffraction", {"komega", "kappa", "kphi", "tth"})); 
		this.add_mode(new PseudoAxisEngineModeHklConstantPsi(
				      this,
				      "constant_psi", {"komega", "kappa", "kphi", "tth"})); 
		this.select_mode(0);
	}
}

public class Hkl.PseudoAxisEngineAutoEuleriansK4CV : Hkl.PseudoAxisEngineAutoEulerians
{
	public PseudoAxisEngineAutoEuleriansK4CV()
	{
		base();

		this.add_mode(new PseudoAxisEngineModeEulerians(
				      this, "eulerians",
				      {"komega", "kappa", "kphi"}));

		this.select_mode(0);
	}
}

public class Hkl.PseudoAxisEngineAutoPsiK4CV : Hkl.PseudoAxisEngineAutoPsi
{
	public PseudoAxisEngineAutoPsiK4CV()
	{
		base();

		this.add_mode(new PseudoAxisEngineModePsi(
				      this, "psi",
				      {"komega", "kappa", "kphi", "tth"}));

		this.select_mode(0);
	}
}

public class Hkl.PseudoAxisEngineAutoQK4CV : Hkl.PseudoAxisEngineAutoQ
{
	public PseudoAxisEngineAutoQK4CV()
	{
		base();

		this.add_mode(new PseudoAxisEngineModeQ(
				      this, "q",
				      {"tth"}));

		this.select_mode(0);
	}
}
