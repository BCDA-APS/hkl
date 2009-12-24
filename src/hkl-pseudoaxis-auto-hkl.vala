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

/***********************************************/
/* default hkl mode use if only 3 unknows axes */
/***********************************************/

public int RUBh_minus_Q(double *x, void *params, double *f)
{
	Hkl.PseudoAxisEngineHkl *engine = params;
	Hkl.Vector ki, dQ;
	Hkl.Vector hkl = {engine->h.value, engine->k.value, engine->l.value};
	uint idx=0U;

	// update the axes from x;
	foreach(weak Hkl.Axis axis in engine->axes){
		axis.set_value(x[idx++]);
	}
	engine->geometry.update();

	// R * UB * h = Q
	// for now the 0 holder is the sample holder.
	engine->sample.UB.times_vector(ref hkl);
	hkl.rotated_quaternion(engine->geometry.holders[0].q);

	// kf - ki = Q
	engine->geometry.source.compute_ki(out ki);
	engine->detector.compute_kf(engine->geometry, out dQ);
	dQ.minus_vector(ki);

	dQ.minus_vector(hkl);

	f[0] = dQ.x;
	f[1] = dQ.y;
	f[2] = dQ.z;

	return Gsl.Status.SUCCESS;
}

public int RUBh_minus_Q_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	RUBh_minus_Q(x.data, params, f.data);

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHkl : Hkl.PseudoAxisEngineMode
{
	public PseudoAxisEngineHkl engine;

	public PseudoAxisEngineModeHkl(PseudoAxisEngineHkl engine, string name,
				       string[] axes_names)
	{
		base(name, axes_names);
		this.engine = engine;
	}

	public override bool get(Geometry geometry, Detector detector, Sample sample)
	{
		Holder holder;
		Matrix RUB;
		Vector hkl, ki, Q;

		// update the geometry internals
		geometry.update();

		// R * UB
		// for now the 0 holder is the sample holder.
		holder = geometry.holders[0];
		holder.q.to_matrix(out RUB);
		RUB.times_matrix(sample.UB);

		// kf - ki = Q
		geometry.source.compute_ki(out ki);
		detector.compute_kf(geometry, out Q);
		Q.minus_vector(ki);

		RUB.solve(out hkl, Q);

		this.engine.h.set_value(hkl.x);
		this.engine.k.set_value(hkl.y);
		this.engine.l.set_value(hkl.z);

		return false;
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		this.engine.prepare_internal(geometry, detector, sample);
		
		Gsl.MultirootFunction f = {RUBh_minus_Q_func, 3, this.engine};

		return this.engine.solve_function(f);
	}
}

/***************************************/
/* the double diffraction get set part */
/***************************************/

static int double_diffraction_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	return double_diffraction(x.data, params, f.data);
}

public int double_diffraction(double *x, void *params, double *f)
{
	Hkl.PseudoAxisEngineHkl *engine = params;
	Hkl.PseudoAxisEngineModeHklDoubleDiffraction *mode = engine->mode;
	Hkl.Vector ki;
	Hkl.Vector dQ;

	// TODO simplify
	Hkl.Vector hkl = {engine->h.value, engine->k.value, engine->l.value};
	Hkl.Vector kf2 = {mode->h2.value, mode->k2.value, mode->l2.value};

	// update the workspace from x;
	uint i=0u;
	foreach(weak Hkl.Axis axis in engine->axes){
		axis.set_value(x[i++]);
	}
	engine->geometry.update();

	// R * UB * hkl = Q
	// for now the 0 holder is the sample holder.
	engine->sample.UB.times_vector(ref hkl);
	hkl.rotated_quaternion(engine->geometry.holders[0].q);

	// kf - ki = Q
	engine->geometry.source.compute_ki(out ki);
	engine->detector.compute_kf(engine->geometry, out dQ);
	dQ.minus_vector(ki);
	dQ.minus_vector(hkl);

	// R * UB * hlk2 = Q2
	engine->sample.UB.times_vector(ref kf2);
	kf2.rotated_quaternion(engine->geometry.holders[0].q);
	kf2.add_vector(ki);

	f[0] = dQ.x;
	f[1] = dQ.y;
	f[2] = dQ.z;
	f[3] = kf2.norm2() - ki.norm2();

	return Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklDoubleDiffraction : Hkl.PseudoAxisEngineModeHkl
{
	public unowned Parameter h2;
	public unowned Parameter k2;
	public unowned Parameter l2;

	public PseudoAxisEngineModeHklDoubleDiffraction(PseudoAxisEngineHkl engine, string name,
							string[] axes_names)
	{
		base(engine, name, axes_names);

		this.h2 = this.add_parameter(new Parameter("h2", -1.0, 1.0, 1.0,
							   false, true, null, null));
		this.k2 = this.add_parameter(new Parameter("k2", -1.0, 1.0, 1.0,
							   false, true, null, null));
		this.l2 = this.add_parameter(new Parameter("l2", -1.0, 1.0, 1.0,
							   false, true, null, null));
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		this.engine.prepare_internal(geometry, detector, sample);
		Gsl.MultirootFunction f = {double_diffraction_func, 4, this.engine};
		return this.engine.solve_function(f);
	}
}

/*******/
/* hkl */
/*******/

public class Hkl.PseudoAxisEngineHkl : Hkl.PseudoAxisEngineAuto
{
	public unowned PseudoAxis h;
	public unowned PseudoAxis k;
	public unowned PseudoAxis l;

	public PseudoAxisEngineHkl()
	{
		base("hkl");

		this.h = this.add_pseudoAxis(
			new Hkl.PseudoAxis(
				new Parameter("h", -1.0, 0.0, 1.0, false, true, null, null)
				)
			);
		this.k = this.add_pseudoAxis(
			new Hkl.PseudoAxis(
				new Parameter("k", -1.0, 0.0, 1.0, false, true, null, null)
				)
			);
		this.l = this.add_pseudoAxis(
			new Hkl.PseudoAxis(
				new Parameter("l", -1.0, 0.0, 1.0, false, true, null, null)
				)
			);
	}
}

/*********************/
/* psi constant mode */
/*********************/

static int constant_psi_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
       
	double *x_data = x.data;
	double *f_data = f.data;

	Hkl.Vector hkl = {1, 0, 0};
	Hkl.Vector ki, kf, Q, n;
	Hkl.PseudoAxisEngineHkl *engine = params;
	Hkl.PseudoAxisEngineModeHklConstantPsi *mode = engine->mode;

	RUBh_minus_Q(x_data, params, f_data);

	// update the workspace from x;
	uint i=0U;
	foreach(weak Hkl.Axis axis in engine->axes)
		axis.set_value(x_data[i++]);
	engine->geometry.update();

	// kf - ki = Q
	engine->geometry.source.compute_ki(out ki);
	engine->detector.compute_kf(engine->geometry, out kf);
	Q = kf;
	Q.minus_vector(ki);

	Q.normalize();
	n = kf;
	n.vectorial_product(ki);
	n.vectorial_product(Q);

	
	hkl.times_matrix(engine->sample.UB);
	hkl.rotated_quaternion(engine->geometry.holders[0].q);

	// project hkl on the plan of normal Q
	hkl.project_on_plan(Q);

	f_data[3] =  mode->psi.value - n.oriented_angle(hkl, Q);

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklConstantPsi : Hkl.PseudoAxisEngineModeHkl
{
	public unowned Parameter h2;
	public unowned Parameter k2;
	public unowned Parameter l2;
	public unowned Parameter psi;

	public PseudoAxisEngineModeHklConstantPsi(PseudoAxisEngineHkl engine, string name,
						  string[] axes_names)
	{
		base(engine, name, axes_names);

		this.h2 = this.add_parameter(new Parameter("h2", -1.0, 1.0, 1.0,
							   false, true, null, null));
		this.k2 = this.add_parameter(new Parameter("k2", -1.0, 1.0, 1.0,
							   false, true, null, null));
		this.l2 = this.add_parameter(new Parameter("l2", -1.0, 1.0, 1.0,
							   false, true, null, null));
		this.psi = this.add_parameter(new Parameter("psi", -Math.PI, 0.0, Math.PI,
							    false, true,
							    hkl_unit_angle_rad, hkl_unit_angle_deg));
	}

	public override bool init(Geometry geometry, Detector detector, Sample sample)
	{
		Vector hkl = {1, 0, 0};
		Vector ki, kf, Q, n;
		bool status = true;

		status = base.init(geometry, detector, sample);
		if(status == false)
			return status;

		// kf - ki = Q
		geometry.source.compute_ki(out ki);
		detector.compute_kf(geometry, out kf);
		Q = kf;
		Q.minus_vector(ki);

		if (Q.is_null())
			status = false;
		else{
			Q.normalize(); // needed for a problem of precision

			// compute the intersection of the plan P(kf, ki) and PQ (normal Q)
			n = kf;
			n.vectorial_product(ki);
			n.vectorial_product(Q);

			// compute hkl in the laboratory referentiel
			// the geometry was already updated in the detector compute kf
			// for now the 0 holder is the sample holder
			hkl.set(this.h2.value, this.k2.value, this.l2.value);			
			hkl.times_matrix(sample.UB);
			hkl.rotated_quaternion(geometry.holders[0].q);
	
			// project hkl on the plan of normal Q
			hkl.project_on_plan(Q);

			if (hkl.is_null())
				status = false;
			else
				// compute the angle beetween hkl and n and store in in the fourth parameter
				this.psi.value = n.oriented_angle(hkl, Q);
		}
		return status;
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		this.engine.prepare_internal(geometry, detector, sample);
		Gsl.MultirootFunction f = {constant_psi_func, 4, this.engine};
		return this.engine.solve_function(f);
	}
}
