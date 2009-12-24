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
/* bissector horizontal */
/************************/

static int bissector_horizontal_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double mu, omega, gamma;

	RUBh_minus_Q(x.data, params, f.data);

	mu = x.data[0];
	omega = x.data[1];
	gamma = x.data[4];

	f.data[3] = Math.fmod(omega, Math.PI);
	f.data[4] = gamma - 2 * Math.fmod(mu, Math.PI);

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklE6CBissectorHorizontal : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklE6CBissectorHorizontal(PseudoAxisEngineHkl engine,
							     string name, string[] axes_names)
	{
		base(engine, name, axes_names);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		this.engine.prepare_internal(geometry, detector, sample);
		Gsl.MultirootFunction f = {bissector_horizontal_func, 5, this.engine};
		return this.engine.solve_function(f);
	}
}

// TODO improve an use the same class than e4cv bissector vertical
/**********************/
/* bissector vertical */
/**********************/

static int bissector_vertical_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double omega, tth;

	RUBh_minus_Q(x.data, params, f.data);

	omega = x.data[0];
	tth = x.data[3];

	f.data[3] = tth - 2 * Math.fmod(omega, Math.PI);

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklE6CBissectorVertical : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklE6CBissectorVertical(PseudoAxisEngineHkl engine,
							     string name, string[] axes_names)
	{
		base(engine, name, axes_names);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		this.engine.prepare_internal(geometry, detector, sample);
		Gsl.MultirootFunction f = {bissector_vertical_func, 4, this.engine};
		return this.engine.solve_function(f);
	}
}

/***********************/
/* E6C PseudoAxeEngine */
/***********************/

public class Hkl.PseudoAxisEngineHklE6C : Hkl.PseudoAxisEngineHkl
{
	public PseudoAxisEngineHklE6C()
	{
		base();

		this.add_mode(new PseudoAxisEngineModeHklE6CBissectorVertical(
				      this, "bissector_vertical",
				      {"omega", "chi", "phi", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "constant_omega_vertical",
				      {"chi", "phi", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "constant_chi_vertical",
				      {"omega", "phi", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "constant_phi_vertical",
				      {"omega", "chi", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "lifting_detector_phi",
				      {"phi", "gamma", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "lifting_detector_omega",
				      {"omega", "gamma", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "lifting_detector_mu",
				      {"mu", "gamma", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHklDoubleDiffraction(
				      this, "double_diffraction_vertical",
				      {"omega", "chi", "phi", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHklE6CBissectorHorizontal(
				      this, "bissector_horizontal",
				      {"mu", "omega", "chi", "phi", "delta"}));
		this.add_mode(new PseudoAxisEngineModeHklDoubleDiffraction(
				      this, "double_diffraction_horizontal",
				      {"mu", "chi", "phi", "gamma"}));
		this.add_mode(new PseudoAxisEngineModeHklConstantPsi(
				      this, "constant_psi_vertical",
				      {"omega", "chi", "phi", "delta"}));


		this.select_mode(0);
	}
}
public class Hkl.PseudoAxisEngineAutoPsiE6C : Hkl.PseudoAxisEngineAutoPsi
{
	public PseudoAxisEngineAutoPsiE6C()
	{
		base();
		this.add_mode(new PseudoAxisEngineModePsi(
				      this, "psi_vertical",
				      {"omega", "chi", "phi", "delta"}));

		this.select_mode(0);
	}
}

public class Hkl.PseudoAxisEngineAutoQ2E6C : Hkl.PseudoAxisEngineAutoQ2
{
	public PseudoAxisEngineAutoQ2E6C()
	{
		base();
		this.add_mode(new PseudoAxisEngineModeQ2(
				      this, "q2",
				      {"gamma", "delta"}));

		this.select_mode(0);
	}
}
