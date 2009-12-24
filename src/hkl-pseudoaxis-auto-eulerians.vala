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

class Hkl.PseudoAxisEngineModeEulerians : Hkl.PseudoAxisEngineMode
{
	public unowned PseudoAxisEngineAutoEulerians engine;
	public unowned Parameter solution;

	public PseudoAxisEngineModeEulerians(PseudoAxisEngineAutoEulerians engine,
					     string name, string[] axes_names)
	{
		base(name, axes_names);
		this.engine = engine;

		this.solution = this.add_parameter(
			new Parameter("solution", 0.0, 0.0, 1.0,
				      false, true, null, null));
	}

	public override bool get(Geometry geometry, Detector detector, Sample sample)
	{
		double komega, kappa, kphi;
		double Kappa;
		double p;
		double alpha = 50.0 * Hkl.DEGTORAD;

		geometry.update();

		komega = geometry.get_axis_by_name("komega").value;
		kappa = geometry.get_axis_by_name("kappa").value;
		kphi = geometry.get_axis_by_name("kphi").value;

		Kappa = Gsl.Trig.angle_restrict_symm(kappa);
		p = Math.atan(Math.tan(Kappa/2.0) * Math.cos(alpha));
	
		if (this.solution.value > 0.0){
			this.engine.omega.set_value(komega + p - Math.PI_2);
			this.engine.chi.set_value(2 * Math.asin(Math.sin(Kappa/2.0) * Math.sin(alpha)));
			this.engine.phi.set_value(kphi + p + Math.PI_2);
		}else{
			this.engine.omega.set_value(komega + p + Math.PI_2);
			this.engine.chi.set_value(-2 * Math.asin(Math.sin(Kappa/2.0) * Math.sin(alpha)));
			this.engine.phi.set_value(kphi + p - Math.PI_2);
		}
		return true;
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		bool status = true;
		double alpha = 50.0 * Hkl.DEGTORAD;
		Gsl.Vector angles = new Gsl.Vector(3);

		this.engine.prepare_internal(geometry, detector, sample);

		if (Math.fabs(this.engine.chi.value) <= alpha * 2){
			double p = Math.asin(Math.tan(this.engine.chi.value/2.0)/Math.tan(alpha));

			if (this.solution.value > 0.0){
				angles.data[0] = this.engine.omega.value - p + Math.PI_2;
				angles.data[1] = 2 * Math.asin(Math.sin(this.engine.chi.value/2.0)/Math.sin(alpha));
				angles.data[2] = this.engine.phi.value - p - Math.PI_2;
			}else{
				angles.data[0] = this.engine.omega.value + p - Math.PI_2;
				angles.data[1] = -2 * Math.asin(Math.sin(this.engine.chi.value/2.0)/Math.sin(alpha));
				angles.data[2] = this.engine.phi.value + p + Math.PI_2;
			}
			this.engine.add_geometry(angles);
		}else
			status = false;

		return status;
	}
}

public class Hkl.PseudoAxisEngineAutoEulerians : PseudoAxisEngineAuto
{
	public unowned PseudoAxis omega;
	public unowned PseudoAxis chi;
	public unowned PseudoAxis phi;

	public PseudoAxisEngineAutoEulerians()
	{
		base("eulerians");

		this.omega = this.add_pseudoAxis(
			new PseudoAxis(
				new Parameter(
					"omega", -Math.PI, 0.0, Math.PI,
					false, true,
					hkl_unit_angle_rad, hkl_unit_angle_deg)
				)
			);
		this.chi = this.add_pseudoAxis(
			new PseudoAxis(
				new Parameter(
					"chi", -Math.PI, 0.0, Math.PI,
					false, true,
					hkl_unit_angle_rad, hkl_unit_angle_deg)
				)
			);
		this.phi = this.add_pseudoAxis(
			new PseudoAxis(
				new Parameter(
					"phi", -Math.PI, 0.0, Math.PI,
					false, true,
					hkl_unit_angle_rad, hkl_unit_angle_deg)
				)
			);
	}
}
