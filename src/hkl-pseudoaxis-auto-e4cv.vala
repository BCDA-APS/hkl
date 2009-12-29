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
 */

using Gsl;

/******************/
/* Bisector Modes */
/******************/

static int bissector_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double omega, tth;

	RUBh_minus_Q_func(x, params, f);

	omega = x.data[0];
	tth = x.data[3];

	f.data[3] = tth - 2 * Math.fmod(omega, Math.PI);

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklE4CVBissector : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklE4CVBissector(PseudoAxisEngineHkl engine)
	{
		base(engine, "bissector", {"omega", "chi", "phi", "tth"});
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		Gsl.MultirootFunction f = {bissector_func, 4, this.engine};
		return this.engine.solve_function(f);
	}
}

/****************************************************/
/* The PseudoAxisEngines of the E4CV diffractometer */
/****************************************************/

public class Hkl.PseudoAxisEngineHklE4CV : Hkl.PseudoAxisEngineHkl
{
	public PseudoAxisEngineHklE4CV()
	{
		base();

		this.add_mode(new PseudoAxisEngineModeHklE4CVBissector(this));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "constant_omega",
				      {"chi", "phi", "tth"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "constant_chi",
				      {"omega", "phi", "tth"}));
		this.add_mode(new PseudoAxisEngineModeHkl(
				      this, "constant_phi",
				      {"omega", "chi", "tth"}));
		this.add_mode(new PseudoAxisEngineModeHklDoubleDiffraction(
				      this, "double_diffraction",
				      {"omega", "chi", "phi", "tth"}));
		this.add_mode(new PseudoAxisEngineModeHklConstantPsi(
				      this, "constant_psi",
				      {"omega", "chi", "phi", "tth"}));
		this.select_mode(0);
	}
}

public class Hkl.PseudoAxisEngineAutoPsiE4CV : Hkl.PseudoAxisEngineAutoPsi
{
	public PseudoAxisEngineAutoPsiE4CV()
	{
		base();
		this.add_mode(new PseudoAxisEngineModePsi(
				      this, "psi",
				      {"omega", "chi", "phi", "tth"}));

		this.select_mode(0);
	}
}

public class Hkl.PseudoAxisEngineAutoQE4CV : Hkl.PseudoAxisEngineAutoQ
{
	public PseudoAxisEngineAutoQE4CV()
	{
		base();
		this.add_mode(new PseudoAxisEngineModeQ(
				      this, "q",
				      {"tth"}));

		this.select_mode(0);
	}
}