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

/*****/
/* q */
/*****/

static int q_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double q;
	double tth;
	double *x_data = x.data;
	double *f_data = f.data;
	Hkl.PseudoAxisEngineAutoQ *engine = params;

	// update the workspace from x;
	uint i = 0;
	foreach(weak Hkl.Axis axis in engine->axes)
		axis.set_value(x_data[i++]);
	engine->geometry.update();

	tth = x_data[0];
	q = 2.0 * Hkl.TAU / engine->geometry.source.get_wavelength() * Math.sin(tth/2.0);

	f_data[0] = engine->q.value - q;

	return  Gsl.Status.SUCCESS;
}

class Hkl.PseudoAxisEngineModeQ : Hkl.PseudoAxisEngineMode
{
	public unowned PseudoAxisEngineAutoQ engine;

	public PseudoAxisEngineModeQ(PseudoAxisEngineAutoQ engine, string name,
				     string[] axes_names)
	{
		base(name, axes_names);
		this.engine = engine;
	}

	public override bool get(Geometry geometry,Detector detector,Sample sample)
	{
		double wavelength;
		double theta;
		double q;
		Interval range = {0.0, 0.0};
		Vector ki, kf;

		wavelength = geometry.source.get_wavelength();
		geometry.source.compute_ki(out ki);
		detector.compute_kf(geometry, out kf);
		theta = ki.angle(kf) / 2.0;
	
		ki.vectorial_product(kf);
		if(ki.y > 0)
			theta = -theta;

		q = 2 * Hkl.TAU / wavelength * Math.sin(theta);

		// update q
		this.engine.q.set_value(q);
		this.engine.q.set_range(range.min, range.max);

		return true;
	}

	public override bool set(Geometry geometry,Detector detector,Sample sample)
	{
		this.engine.prepare_internal(geometry, detector, sample);
		Gsl.MultirootFunction f = {q_func, 1, this.engine};
		return this.engine.solve_function(f);
	}
}

public class Hkl.PseudoAxisEngineAutoQ : PseudoAxisEngineAuto
{
	public unowned PseudoAxis q;

	public PseudoAxisEngineAutoQ()
	{
		base("q");

		this.q = this.add_pseudoAxis(
			new PseudoAxis(
				new Parameter(
					"q", -1.0, 0.0, 1.0,
					false, true,
					null, null)
				)
			);
	}
}

/******/
/* q2 */
/******/

static int q2_func(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double q;
	double alpha;
	double wavelength, theta;
	Hkl.PseudoAxisEngineAutoQ2 *engine = params;
	Hkl.Vector kf, ki;
	Hkl.Vector X = {1.0, 0.0, 0.0};

	// update the workspace from x;
	uint i=0U;
	foreach(weak Hkl.Axis axis in engine->axes)
		axis.set_value(x.data[i++]);
	engine->geometry.update();

	wavelength = engine->geometry.source.get_wavelength();
	engine->geometry.source.compute_ki(out ki);
	engine->detector.compute_kf(engine->geometry, out kf);
	theta = ki.angle(kf) / 2.0;
	
	q = 2 * Hkl.TAU / wavelength * Math.sin(theta);

	// project kf on the x plan to compute alpha
	kf.project_on_plan(X);
	alpha = Math.atan2(kf.z, kf.y);

	f.data[0] = engine->q.value - q;
	f.data[1] = engine->alpha.value - alpha;

	return  Gsl.Status.SUCCESS;
}

class Hkl.PseudoAxisEngineModeQ2 : Hkl.PseudoAxisEngineMode
{
	public unowned PseudoAxisEngineAutoQ2 engine;

	public PseudoAxisEngineModeQ2(PseudoAxisEngineAutoQ2 engine, string name,
				      string[] axes_names)
	{
		base(name, axes_names);
		this.engine = engine;
	}
	public override bool get(Geometry geometry, Detector detector,Sample sample)
	{
		double wavelength;
		double theta;
		double q, alpha;
		Vector x = {1.0, 0.0, 0.0};
		Vector ki, kf;

		wavelength = geometry.source.get_wavelength();
		geometry.source.compute_ki(out ki);
		detector.compute_kf(geometry, out kf);
		theta = ki.angle(kf) / 2.0;
	
		q = 2 * Hkl.TAU / wavelength * Math.sin(theta);

		// project kf on the x plan to compute alpha
		kf.project_on_plan(x);
		alpha = Math.atan2(kf.z, kf.y);

		// update q
		this.engine.q.set_value(q);
		this.engine.alpha.set_value(alpha);
		this.engine.alpha.set_range(-Math.PI, Math.PI);

		return true;
	}

	public override bool set(Geometry geometry,Detector detector,Sample sample)
	{
		this.engine.prepare_internal(geometry, detector, sample);
		Gsl.MultirootFunction f = {q2_func, 2, this.engine};
		return this.engine.solve_function(f);
	}
}

public class Hkl.PseudoAxisEngineAutoQ2 : PseudoAxisEngineAutoQ
{
	public unowned PseudoAxis alpha;

	public PseudoAxisEngineAutoQ2()
	{
		base();
		this.name = "q2";

		this.alpha = this.add_pseudoAxis(
			new PseudoAxis(
				new Parameter(
					"alpha", -Math.PI, 0.0, Math.PI,
					false, true,
					hkl_unit_angle_rad, hkl_unit_angle_deg)
				)
			);
	}
}
