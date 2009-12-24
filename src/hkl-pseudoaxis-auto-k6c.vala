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

/************************/
/* bissector_horizontal */
/************************/

static int bissector_h_f1_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double gamma, mu, komega, kappa, omega;
	int i;

	for(i=0;i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	mu = x.data[0];
	komega = x.data[1];
	kappa = x.data[2];
	gamma = x.data[4];

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD)) - Math.PI_2;

	f.data[3] = Math.fmod(omega, Math.PI);
	f.data[4] = Math.fmod(gamma - 2 * Math.fmod(mu, Math.PI), 2*Math.PI);

	return  Gsl.Status.SUCCESS;
}

static int bissector_h_f2_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double gamma, mu, komega, kappa, omega;
	int i;

	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	mu = x.data[0];
	komega = x.data[1];
	kappa = x.data[2];
	gamma = x.data[4];

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD)) + Math.PI_2;

	f.data[3] = Math.fmod(omega, Math.PI);
	f.data[4] = Math.fmod(gamma - 2 * Math.fmod(mu, Math.PI), 2*Math.PI);


	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklKappaBissectorHorizontal : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklKappaBissectorHorizontal(PseudoAxisEngineHkl engine,
							       string name, string[] axes_names)
	{
		base(engine, name, axes_names);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		bool status = false;
		Gsl.MultirootFunction f1 = {bissector_h_f1_func, 5, this.engine};
		Gsl.MultirootFunction f2 = {bissector_h_f2_func, 5, this.engine};

		this.engine.prepare_internal(geometry, detector, sample);
		status |= this.engine.solve_function(f1);
		status |= this.engine.solve_function(f2);

		return status;
	}
}

/****************************/
/* constant_kphi_horizontal */
/****************************/

static int constant_kphi_h_f1_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double gamma, mu, komega, kappa, omega;
	int i;

	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	mu = x.data[0];
	komega = x.data[1];
	kappa = x.data[2];
	gamma = x.data[3];

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD)) - Math.PI_2;

	f.data[3] = Math.fmod(omega, Math.PI);

	return  Gsl.Status.SUCCESS;
}

static int constant_kphi_h_f2_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double gamma, mu, komega, kappa, omega;
	int i;

	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	mu = x.data[0];
	komega = x.data[1];
	kappa = x.data[2];
	gamma = x.data[3];

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD)) + Math.PI_2;

	f.data[3] = Math.fmod(omega, Math.PI);

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklKappaConstantKphiHorizontal : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklKappaConstantKphiHorizontal(PseudoAxisEngineHkl engine,
								  string name,
								  string[] axes_names)
	{
		base(engine, name, axes_names);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		bool status = false;
		Gsl.MultirootFunction f1 = {constant_kphi_h_f1_func, 4, this.engine};
		Gsl.MultirootFunction f2 = {constant_kphi_h_f2_func, 4, this.engine};

		this.engine.prepare_internal(geometry, detector, sample);
		status |= this.engine.solve_function(f1);
		status |= this.engine.solve_function(f2);

		return status;
	}
}

/***************************/
/* constant_phi_horizontal */
/***************************/

static int constant_phi_h_f1_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double gamma, mu, komega, kappa, kphi;
	double omega, phi, p;
	int i;

	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	mu = x.data[0];
	komega = x.data[1];
	kappa = x.data[2];
	kphi = x.data[3];
	gamma = x.data[4];

	p = Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD));

	omega = komega + p - Math.PI_2;
	phi = kphi + p + Math.PI_2;

	f.data[3] = Math.fmod(omega, Math.PI);
	f.data[4] = phi;

	return  Gsl.Status.SUCCESS;
}

static int constant_phi_h_f2_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double gamma, mu, komega, kappa, kphi;
	double omega, phi, p;
	int i;

	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x.data, params, f.data);

	mu = x.data[0];
	komega = x.data[1];
	kappa = x.data[2];
	kphi = x.data[3];
	gamma = x.data[4];

	p = Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD));

	omega = komega + p + Math.PI_2;
	phi = kphi + p - Math.PI_2;

	f.data[3] = Math.fmod(omega, Math.PI);
	f.data[4] = phi;

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklKappaConstantPhiHorizontal : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklKappaConstantPhiHorizontal(PseudoAxisEngineHkl engine,
								 string name, string[] axes_names)
	{
		base(engine, name, axes_names);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		bool status = false;
		Gsl.MultirootFunction f1 = {constant_phi_h_f1_func, 5, this.engine};
		Gsl.MultirootFunction f2 = {constant_phi_h_f2_func, 5, this.engine};

		this.engine.prepare_internal(geometry, detector, sample);
		status |= this.engine.solve_function(f1);
		status |= this.engine.solve_function(f2);

		return status;
	}
}

/*********************************/
/* double_diffraction_horizontal */
/*********************************/

static int double_diffraction_h_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double gamma, mu, komega, kappa, omega;
	int i;

	for(i=0; i<x.size;++i)
		if (x.data[i].is_nan())
			return Gsl.Status.ENOMEM;

	double_diffraction(x.data, params, f.data);

	mu = x.data[0];
	komega = x.data[1];
	kappa = x.data[2];
	gamma = x.data[4];

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD)) - Math.PI_2;

	f.data[4] = Math.fmod(omega, Math.PI);

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklKappaDoubleDiffractionHorizontal : Hkl.PseudoAxisEngineModeHklDoubleDiffraction
{
	public PseudoAxisEngineModeHklKappaDoubleDiffractionHorizontal(PseudoAxisEngineHkl engine,
								       string name,
								       string[] axes_names)
	{
		base(engine, name, axes_names);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		bool status = false;
		Gsl.MultirootFunction f1 = {double_diffraction_h_func, 5, this.engine};

		this.engine.prepare_internal(geometry, detector, sample);
		status |= this.engine.solve_function(f1);

		return status;
	}
}

/***********************/
/* K6C PseudoAxeEngine */
/***********************/

public class Hkl.PseudoAxisEngineHklK6C : Hkl.PseudoAxisEngineHkl
{
	public PseudoAxisEngineHklK6C()
	{
		base();

		this.add_mode(new PseudoAxisEngineModeHklKappaBissector(
				      this,
				      "bissector_vertical",
				      {"komega", "kappa", "kphi", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHklKappaConstantOmega(
				      this,
				      "constant_omega_vertical",
				      {"komega", "kappa", "kphi", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHklKappaConstantChi(
				      this,
				      "constant_chi_vertical",
				      {"komega", "kappa", "kphi", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHklKappaConstantPhi(
				      this,
				      "constant_phi_vertical",
				      {"komega", "kappa", "kphi", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "lifting_detector_kphi",
				      {"kphi", "gamma", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "lifting_detector_komega",
				      {"komega", "gamma", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "lifting_detector_mu",
				      {"mu", "gamma", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHklDoubleDiffraction(
				      this,
				      "double_diffraction_vertical",
				      {"komega", "kappa", "kphi", "delta"})); 
		this.add_mode(new PseudoAxisEngineModeHklKappaBissectorHorizontal(
				      this,
				      "bissector_horizontal",
				      {"mu", "komega", "kappa", "kphi", "gamma" }));
		this.add_mode(new PseudoAxisEngineModeHklKappaConstantKphiHorizontal(
				      this,
				      "constant_kphi_horizontal",
				      {"mu", "komega", "kappa", "gamma" }));
		this.add_mode(new PseudoAxisEngineModeHklKappaConstantPhiHorizontal(
				      this,
				      "constant_phi_horizontal",
				      {"mu", "komega", "kappa", "kphi", "gamma" }));
		this.add_mode(new PseudoAxisEngineModeHklKappaDoubleDiffractionHorizontal(
				      this,
				      "double_diffraction_horizontal",
				      {"mu", "komega", "kappa", "kphi", "delta"})); 
		this.add_mode(new PseudoAxisEngineModeHklConstantPsi(
				      this,
				      "constant_psi_vertical",
				      {"komega", "kappa", "kphi", "delta"})); 
		this.select_mode(0);
	}
}

public class Hkl.PseudoAxisEngineAutoPsiK6C : Hkl.PseudoAxisEngineAutoPsi
{
	public PseudoAxisEngineAutoPsiK6C()
	{
		base();

		this.add_mode(new PseudoAxisEngineModePsi(
				      this,
				      "psi_vertical",
				      {"komega", "kappa", "kphi", "delta"}));

		this.select_mode(0);
	}
}

//TODO improve identiq to PseudoAxisEngineAutoQ2E6C
public class Hkl.PseudoAxisEngineAutoQ2K6C : Hkl.PseudoAxisEngineAutoQ2
{
	public PseudoAxisEngineAutoQ2K6C()
	{
		base();
		this.add_mode(new PseudoAxisEngineModeQ2(
				      this, "q2",
				      {"gamma", "delta"}));

		this.select_mode(0);
	}
}
