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

public class Hkl.PseudoAxis : Hkl.Parameter
{
	public PseudoAxisEngine? engine;

	public PseudoAxis(Parameter parameter)
	{
		base.copy(parameter);
		this.engine = null;
	}

	[CCode (instance_pos=-1)]
	public new void fprintf(FileStream f)
	{
		base.fprintf(f);
		f.printf(" %p", this.engine);
	}
}

public abstract class Hkl.PseudoAxisEngineMode
{
	public string name;
	public abstract bool get(Geometry geometry, Detector detector, Sample sample) throws Error;
	public abstract bool set(Geometry geometry, Detector detector, Sample sample) throws Error;
	public Parameter[] parameters;
	public string[] axes_names;
	public Geometry geometry_init;
	public Detector detector_init;
	public Sample sample_init;

	public PseudoAxisEngineMode(string name, string[] axes_names)
	{
		this.name = name;
		this.axes_names = axes_names;
	}

	public virtual bool initialize(Geometry geometry, Detector detector, Sample sample) throws Error
	{
		geometry.update();
		this.geometry_init = new Geometry.copy(geometry);
		this.detector_init = detector;
		this.sample_init = sample;

		return true;
	}

	public unowned Parameter add_parameter(owned Parameter parameter)
	{
		int len = this.parameters.length;
		this.parameters.resize(len + 1);
		this.parameters[len] = parameter;
		return parameter;
	}
}

public class Hkl.PseudoAxisEngine
{
	public string name;
	public Geometry geometry;
	public Detector detector;
	public unowned Sample sample;
	public PseudoAxisEngineMode[] modes;
	public unowned PseudoAxisEngineMode mode;
	public Axis[] axes;
	public PseudoAxis[] pseudoAxes;
	public PseudoAxisEngineList engines;

	public PseudoAxisEngine(string name)
	{
		this.name = name;
	}

	public unowned PseudoAxis add_pseudoAxis(owned PseudoAxis pseudoAxis)
	{
		pseudoAxis.engine = this;
		int len = this.pseudoAxes.length;
		this.pseudoAxes.resize(len + 1);
		this.pseudoAxes[len] = pseudoAxis;
		return pseudoAxis;
	}

	public void add_mode(owned PseudoAxisEngineMode mode)
	{
		int len = this.modes.length;
		this.modes.resize(len + 1);
		this.modes[len] = mode;
	}

	public void add_geometry(Gsl.Vector x) requires (x.size == this.axes.length)
	{
		double *x_data = x.data;
		int i=0;
		foreach(weak Axis axis in this.axes)
			axis.set_value(Gsl.Trig.angle_restrict_symm(x_data[i++]));
		this.engines.geometries.add(this.geometry);
	}

	public void select_mode(int idx) requires (idx < this.modes.length)
	{
		this.mode = this.modes[idx];
		this.prepare_internal(this.geometry, this.detector, this.sample);
	}

	public bool initialize() throws Error
	{
		return this.mode.initialize(this.engines.geometry,
					    this.engines.detector,
					    this.engines.sample);
	}

	public bool get() throws Error
	{
		return this.mode.get(this.engines.geometry,
				     this.engines.detector,
				     this.engines.sample);
	}

	public bool set() throws Error
	{
		bool res;

		this.engines.geometries.clear();
		res = this.mode.set(this.geometry,
				    this.detector,
				    this.sample);
		if(!res){
			this.engines.geometries.multiply();
			this.engines.geometries.multiply_from_range();
			this.engines.geometries.sort(this.engines.geometry);
			this.engines.geometries.remove_invalid();
		}

		return res;
	}

	public void prepare_internal(Geometry geometry, Detector detector, Sample sample)
	{
		this.geometry = new Geometry.copy(this.engines.geometry);
		this.detector = new Detector.copy(this.engines.detector);
		this.sample = this.engines.sample;
		this.axes.resize(this.mode.axes_names.length);
		int i=0;
		foreach(weak string name in this.mode.axes_names)
			this.axes[i++] = this.geometry.get_axis_by_name(name);
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
	{
		f.printf("\nPseudoAxesEngine : \"%s\"", this.name);
		if(this.mode != null){
			f.printf(" %s", this.mode.name);
			foreach(weak Parameter parameter in this.mode.parameters){
				f.printf("\n     ");
				parameter.fprintf(f);
			}
		}
		foreach(weak PseudoAxis pseudoAxis in this.pseudoAxes){
			f.printf("\n     ");
			pseudoAxis.fprintf(f);
		}
		if(this.engines.geometries.items.length > 0)
			this.engines.geometries.fprintf(f);
		f.printf("\n");
	}
}

public class Hkl.PseudoAxisEngineList
{
	public PseudoAxisEngine[] engines;
	public GeometryList geometries;
	public Geometry geometry;
	public Detector detector;
	public Sample sample;

	public PseudoAxisEngineList()
	{
		this.geometries = new GeometryList();
	}

	public void add(PseudoAxisEngine engine)
	{
		engine.engines = this;
		int len = this.engines.length;
		this.engines.resize(len + 1);
		this.engines[len] = engine;
	}

	public unowned PseudoAxisEngine? get_by_name(string name)
	{
		foreach(weak PseudoAxisEngine engine in this.engines){
			if(engine.name == name)
				return engine;
		}
		return null;
	}

	public unowned PseudoAxis? get_pseudo_axis_by_name(string name)
	{
		foreach(weak PseudoAxisEngine engine in this.engines){
			foreach(weak PseudoAxis pseudoaxis in engine.pseudoAxes){
				if (pseudoaxis.name == name)
					return pseudoaxis;
			}
		}
		return null;
	}

	public void clear()
	{
		this.engines.resize(0);
	}

	public void init(Geometry geometry, Detector detector, Sample sample)
	{
		this.geometry = geometry;
		this.detector = detector;
		this.sample = sample;

		foreach(weak PseudoAxisEngine engine in this.engines)
			engine.prepare_internal(this.geometry, this.detector, this.sample);
	}

	public bool get()
	{
		bool res = true;

		foreach(weak PseudoAxisEngine engine in this.engines)
			try{
				engine.mode.get(this.geometry, this.detector, this.sample);
			}catch (Error err) {
				res = false;
			}
		return res;
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
	{
		foreach(weak PseudoAxisEngine engine in this.engines)
			engine.fprintf(f);
	}
}

public Hkl.PseudoAxisEngineList hkl_pseudo_axis_engine_list_factory(Hkl.GeometryConfig config)
{
	Hkl.PseudoAxisEngineList list = new Hkl.PseudoAxisEngineList();

	switch(config.type){
	case Hkl.GeometryType.EULERIAN4C_VERTICAL:
		list.add(new Hkl.PseudoAxisEngineHklE4CV());
		list.add(new Hkl.PseudoAxisEngineAutoPsiE4CV());
		list.add(new Hkl.PseudoAxisEngineAutoQE4CV());
		break;
	case Hkl.GeometryType.KAPPA4C_VERTICAL:
		list.geometries = new Hkl.GeometryListKappa4C();
		list.add(new Hkl.PseudoAxisEngineHklK4CV());
		list.add(new Hkl.PseudoAxisEngineAutoEuleriansK4CV());
		list.add(new Hkl.PseudoAxisEngineAutoPsiK4CV());
		list.add(new Hkl.PseudoAxisEngineAutoQK4CV());
		break;
	case Hkl.GeometryType.EULERIAN6C:
		list.add(new Hkl.PseudoAxisEngineHklE6C());
		list.add(new Hkl.PseudoAxisEngineAutoPsiE6C());
		list.add(new Hkl.PseudoAxisEngineAutoQ2E6C());
		break;
	case Hkl.GeometryType.KAPPA6C:
		list.geometries = new Hkl.GeometryListKappa6C();
		list.add(new Hkl.PseudoAxisEngineHklK6C());
		list.add(new Hkl.PseudoAxisEngineAutoEuleriansK4CV());
		list.add(new Hkl.PseudoAxisEngineAutoPsiK6C());
		list.add(new Hkl.PseudoAxisEngineAutoQ2K6C());
		break;
	}

	return list;
}
