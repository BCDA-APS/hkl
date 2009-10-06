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
	public weak PseudoAxisEngine engine;

	public PseudoAxis(string name, PseudoAxisEngine engine)
	{
		this.name = name;
		this.engine = engine;
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
	public abstract bool init(Geometry geometry, Detector detector, Sample sample);
	public abstract bool get(Geometry geometry, Detector detector, Sample sample);
	public abstract bool set(Geometry geometry, Detector detector, Sample sample);
	public Parameter[] parameters;
	public string[] axes_names;
}

public class Hkl.PseudoAxisEngine
{
	public weak string name;
	public Geometry geometry;
	public Detector detector;
	public weak Sample sample;
	public PseudoAxisEngineMode[] modes;
	public weak PseudoAxisEngineMode mode;
	public Axis[] axes;
	public PseudoAxis[] pseudoAxes;
	public PseudoAxisEngineList engines;

	public PseudoAxisEngine(string name, string[] names)
	{
		this.name = name;
		this.pseudoAxes = new PseudoAxis[names.length];
		for(int i=0; i<names.length;++i)
			this.pseudoAxes[i] = new PseudoAxis(names[i], this);
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
	}

	public void prepare_internal(Geometry geometry, Detector detector, Sample sample)
	{
		this.geometry = new Geometry.copy(geometry);
		this.detector = detector;
		this.sample = sample;
		this.axes.resize(this.mode.axes_names.length);
		int i=0;
		foreach(weak string name in this.mode.axes_names)
			this.axes[i++] = this.geometry.get_axis_by_name(name);
		this.engines.geometries.clear();
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
	{
		f.printf("\nPseudoAxesEngine : \"%s\"", this.name);
		if(this.mode != null){
			f.printf(" %s", this.mode.name);
			foreach(weak Parameter parameter in this.mode.parameters)
				f.printf(" \"%s\" = %g", parameter.name, parameter.value);
		}
		foreach(weak PseudoAxis pseudoAxis in this.pseudoAxes){
			f.printf("\n     ");
			pseudoAxis.fprintf(f);
		}
		if(this.engines.geometries.geometries.length > 0)
			this.engines.geometries.fprintf(f);
		f.printf("\n");
	}
}

public class Hkl.PseudoAxisEngineList
{
	public PseudoAxisEngine[] engines;
	public GeometryList geometries;

	public void add(PseudoAxisEngine engine)
	{
		int len = engines.length;
		engines.resize(len + 1);
		engines[len] = engine;
	}

	public weak PseudoAxisEngine? get_by_name(string name)
	{
		foreach(weak PseudoAxisEngine engine in this.engines){
			if(engine.name == name)
				return engine;
		}
		return null;
	}

	public weak PseudoAxis? get_pseudo_axis_by_name(string name)
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

	public bool getter(Geometry geometry, Detector detector, Sample sample)
	{
		bool res = true;

		foreach(weak PseudoAxisEngine engine in this.engines)
			if(!engine.mode.get(geometry, detector, sample))
				res = false;

		return res;
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
	{
		foreach(weak PseudoAxisEngine engine in this.engines)
			engine.fprintf(f);
	}
}

public Hkl.PseudoAxisEngineList hkl_pseudo_axis_engine_list_factory(Hkl.GeometryType type)
{
	Hkl.PseudoAxisEngineList list = new Hkl.PseudoAxisEngineList();
/*
	switch(type){
	case Hkl.GeometryType.TWOC_VERTICAL:
		break;
	case Hkl.GeometryType.EULERIAN4C_VERTICAL:
		list.add(hkl_pseudo_axis_engine_e4cv_hkl_new());
		list.add(hkl_pseudo_axis_engine_e4cv_psi_new());
		list.add(hkl_pseudo_axis_engine_q_new());
		break;
	case Hkl.GeometryType.KAPPA4C_VERTICAL:
		//self->geometries->multiply = hkl_geometry_list_multiply_k4c_real;
		list.add(hkl_pseudo_axis_engine_k4cv_hkl_new());
		list.add(hkl_pseudo_axis_engine_eulerians_new());
		list.add(hkl_pseudo_axis_engine_k4cv_psi_new());
		list.add(hkl_pseudo_axis_engine_q_new());
		break;
	case Hkl.GeometryType.EULERIAN6C:
		list.add(hkl_pseudo_axis_engine_e6c_hkl_new());
		list.add(hkl_pseudo_axis_engine_e6c_psi_new());
		list.add(hkl_pseudo_axis_engine_q2_new());
		break;
	case Hkl.GeometryType.KAPPA6C:
		//self->geometries->multiply = hkl_geometry_list_multiply_k6c_real;
		list.add(hkl_pseudo_axis_engine_k6c_hkl_new());
		list.add(hkl_pseudo_axis_engine_eulerians_new());
		list.add(hkl_pseudo_axis_engine_k6c_psi_new());
		list.add(hkl_pseudo_axis_engine_q2_new());
		break;
	}
*/
	return list;
}
