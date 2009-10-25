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

/*******************************************************/
/* default hkl mode use if no mode necessary 3 unknows */
/*******************************************************/

static int RUBh_minus_Q(double *x, void *params, double *f)
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

static int RUBh_minus_Q_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	RUBh_minus_Q(x.data, params, f.data);

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHkl : Hkl.PseudoAxisEngineMode
{
	public PseudoAxisEngineHkl engine;

	PseudoAxisEngineModeHkl(string name, string[] axes_names, Parameter[]? parameters)
	{
		base(name, axes_names, parameters);
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
		
		Gsl.MultirootFunction f = {RUBh_minus_Q_func, 3, this};

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

static int double_diffraction(double *x, void *params, double *f)
{
	Hkl.PseudoAxisEngineHkl *engine = params;
	Hkl.Vector ki;
	Hkl.Vector dQ;

	// TODO simplify
	Hkl.Vector hkl = {engine->h.value, engine->k.value, engine->l.value};
	Hkl.Vector kf2 = {
		engine->mode.parameters[0].value,
		engine->mode.parameters[1].value,
		engine->mode.parameters[2].value
	};

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
	PseudoAxisEngineModeHklDoubleDiffraction(string name, string[] axes_names)
	{
		Parameter h2 = new Parameter("h2", -1, 1, 1, false, true, null, null);
		Parameter k2 = new Parameter("k2", -1, 1, 1, false, true, null, null);
		Parameter l2 = new Parameter("l2", -1, 1, 1, false, true, null, null);
		Parameter[] parameters = {h2, k2, l2};

		base(name, axes_names, parameters);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		this.engine.prepare_internal(geometry, detector, sample);
		Gsl.MultirootFunction f = {double_diffraction_func, 4, this};
		return this.engine.solve_function(f);
	}
}

/*******/
/* hkl */
/*******/

public class Hkl.PseudoAxisEngineHkl : Hkl.PseudoAxisEngineAuto
{
	public Hkl.PseudoAxis h;
	public Hkl.PseudoAxis k;
	public Hkl.PseudoAxis l;

	public PseudoAxisEngineHkl()
	{
		base("hkl");

		this.h = new Hkl.PseudoAxis(new Parameter("h", -1, 0, 1, false, true, null, null));
		this.k = new Hkl.PseudoAxis(new Parameter("k", -1, 0, 1, false, true, null, null));
		this.l = new Hkl.PseudoAxis(new Parameter("l", -1, 0, 1, false, true, null, null));

		this.add_pseudoAxis(this.h);
		this.add_pseudoAxis(this.k);
		this.add_pseudoAxis(this.l);
	}
}

/**************/
/* E4CV Modes */
/**************/

static int bissector_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double omega, tth;

	RUBh_minus_Q(x, params, f);

	omega = x.data[0];
	tth = x.data[3];

	f.data[3] = tth - 2 * Math.fmod(omega, Math.PI);

	return  Gsl.Status.SUCCESS;
}

public class Hkl.PseudoAxisEngineModeHklE4CVBissector : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklE4CVBissector()
	{
		string[] axes_names = {"omega", "chi", "phi", "tth"};

		base("bissector", axes_names, null);
	}

	public override bool set(Geometry geometry, Detector detector, Sample sample)
	{
		this.engine.prepare_internal(geometry, detector, sample);
		Gsl.MultirootFunction f = {bissector_func, 4, this};
		return this.engine.solve_function(f);
	}
}

public class Hkl.PseudoAxisEngineModeHklE4CVConstantOmega : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklE4CVConstantOmega()
	{
		string[] axes_names = {"chi", "phi", "tth"};

		base("constant_omega", axes_names, null);
	}
}

public class Hkl.PseudoAxisEngineModeHklE4CVConstantChi : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklE4CVConstantChi()
	{
		string[] axes_names = {"omega", "phi", "tth"};

		base("constant_chi", axes_names, null);
	}
}

public class Hkl.PseudoAxisEngineModeHklE4CVConstantPhi : Hkl.PseudoAxisEngineModeHkl
{
	public PseudoAxisEngineModeHklE4CVConstantPhi()
	{
		string[] axes_names = {"omega", "chi", "tth"};

		base("constant_phi", axes_names, null);
	}
}

public class Hkl.PseudoAxisEngineModeHklE4CVDoubleDiffraction : Hkl.PseudoAxisEngineModeHklDoubleDiffraction
{
	public PseudoAxisEngineModeHklE4CVDoubleDiffraction()
	{
		string[] axes_names = {"omega", "chi", "phi", "tth"};

		base("double_diffraction", axes_names);
	}
}

public class Hkl.PseudoAxisEngineHklE4CV : Hkl.PseudoAxisEngineHkl
{
	public PseudoAxisEngineHklE4CV()
	{
		this.add_mode(new PseudoAxisEngineModeHklE4CVBissector());
		this.add_mode(new PseudoAxisEngineModeHklE4CVConstantOmega());
		this.add_mode(new PseudoAxisEngineModeHklE4CVConstantChi());
		this.add_mode(new PseudoAxisEngineModeHklE4CVConstantPhi());
		this.add_mode(new PseudoAxisEngineModeHklE4CVDoubleDiffraction());
		this.select_mode(0);
	}
}