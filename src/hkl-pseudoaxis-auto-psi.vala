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

static int psi_func(Gsl.Vector x, void *params, Gsl.Vector f)
{

	Hkl.Vector ki;
	Hkl.Vector kf;
	Hkl.Vector Q;
	Hkl.PseudoAxisEngineAutoPsi *engine = params;
	double *x_data = x.data;
	double *f_data = f.data;

	// update the workspace from x;
	uint i = 0U;
	foreach(weak Hkl.Axis axis in engine->axes)
		axis.set_value(x_data[i++]);
	engine->geometry.update();

	// kf - ki = Q
	engine->geometry.source.compute_ki(out ki);
	engine->detector.compute_kf(engine->geometry, out kf);
	Q = kf;
	Q.minus_vector(ki);
	if (Q.is_null()){
		f_data[0] = 1;
		f_data[1] = 1;
		f_data[2] = 1;
		f_data[3] = 1;
	}else{
		Hkl.Vector dhkl0;
		Hkl.Vector n;
		Hkl.Matrix RUB;
		Hkl.PseudoAxisEngineModePsi *mode = engine->mode;
		Hkl.Vector hkl1 = {mode->h1.value, mode->k1.value, mode->l1.value};

		// R * UB
		// for now the 0 holder is the sample holder.
		engine->geometry.holders[0].q.to_matrix(out RUB);
		RUB.times_matrix(engine->sample.UB);

		// compute dhkl0
		RUB.solve(out dhkl0, Q);
		dhkl0.minus_vector(mode->hkl0);

		// compute the intersection of the plan P(kf, ki) and PQ (normal Q)
		/* 
		 * now that dhkl0 have been computed we can use a
		 * normalized Q to compute n and psi
		 */ 
		Q.normalize();
		n = kf;
		n.vectorial_product(ki);
		n.vectorial_product(Q);

		// compute hkl1 in the laboratory referentiel
		// for now the 0 holder is the sample holder.
		hkl1.times_matrix(engine->sample.UB);
		hkl1.rotated_quaternion(engine->geometry.holders[0].q);
	
		// project hkl1 on the plan of normal Q
		hkl1.project_on_plan(Q);
		f_data[0] = dhkl0.x;
		f_data[1] = dhkl0.y;
		f_data[2] = dhkl0.z;
		if (hkl1.is_null()) // hkl1 colinear with Q
			f_data[3] = 1;
		else
			f_data[3] = engine->psi.value - n.oriented_angle(hkl1, Q);
	}
	return Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModePsi : Hkl.PseudoAxisEngineMode
{
	public unowned PseudoAxisEngineAutoPsi engine;

	public unowned Parameter h1;
	public unowned Parameter k1;
	public unowned Parameter l1;

	public Vector hkl0;
	public Vector Q0;

	public PseudoAxisEngineModePsi(PseudoAxisEngineAutoPsi engine, string name,
				       string[] axes_names)
	{
		base(name, axes_names);
		this.engine = engine;

		this.h1 = this.add_parameter(new Parameter("h1", -1.0, 1.0, 1.0,
							   false, true, null, null));
		this.k1 = this.add_parameter(new Parameter("k1", -1.0, 1.0, 1.0,
							   false, true, null, null));
		this.l1 = this.add_parameter(new Parameter("l1", -1.0, 1.0, 1.0,
							   false, true, null, null));
	}

	public override bool init(Geometry geometry, Detector detector, Sample sample)
	{
		Vector ki;
		Matrix RUB;
		bool status = true;
	
		status = base.init(geometry, detector, sample);
		if (status == false)
			return status;

		// update the geometry internals
		geometry.update();

		// R * UB
		// for now the 0 holder is the sample holder.
		geometry.holders[0].q.to_matrix(out RUB);
		RUB.times_matrix(sample.UB);

		// kf - ki = Q0
		geometry.source.compute_ki(out ki);
		detector.compute_kf(geometry, out this.Q0);
		this.Q0.minus_vector(ki);
		if (this.Q0.is_null())
			status = false;
		else
			// compute hkl0
			RUB.solve(out this.hkl0, this.Q0);

		return status;
	}

	public override bool get(Geometry geometry,Detector detector,Sample sample)
	{
		bool status = true;
		Vector ki;
		Vector kf;
		Vector Q;

		// get kf, ki and Q
		geometry.source.compute_ki(out ki);
		detector.compute_kf(geometry, out kf);
		Q = kf;
		Q.minus_vector(ki);
		if (Q.is_null())
			status = false;
		else{
			Vector n;
			Vector hkl1 = {this.h1.value, this.k1.value, this.l1.value};

			Q.normalize(); // needed for a problem of precision

			// compute the intersection of the plan P(kf, ki) and PQ (normal Q)
			n = kf;
			n.vectorial_product(ki);
			n.vectorial_product(Q);

			// compute hkl1 in the laboratory referentiel
			// the geometry was already updated in the detector compute kf
			// for now the 0 holder is the sample holder.
			hkl1.times_matrix(sample.UB);
			hkl1.rotated_quaternion(geometry.holders[0].q);
	
			// project hkl1 on the plan of normal Q
			hkl1.project_on_plan(Q);
	
			if (hkl1.is_null())
				status = false;
			else
				// compute the angle beetween hkl1 and n
				this.engine.psi.value = n.oriented_angle(hkl1, Q);
		}
		return status;
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		this.engine.prepare_internal(geometry, detector, sample);
		Gsl.MultirootFunction f = {psi_func, 4, this.engine};
		return this.engine.solve_function(f);
	}
}

public class Hkl.PseudoAxisEngineAutoPsi : Hkl.PseudoAxisEngineAuto
{
	public unowned PseudoAxis psi;

	public PseudoAxisEngineAutoPsi()
	{
		base("psi");

		this.psi = this.add_pseudoAxis(
			new PseudoAxis(
				new Parameter(
					"psi", -Math.PI, 0.0, Math.PI,
					false, true,
					hkl_unit_angle_rad, hkl_unit_angle_deg
					)
				)
			);
	}
}
