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

public class Hkl.Holder {
	public weak Geometry geometry;
	public int[] idx;
	public Quaternion q;

	public Holder(Geometry geometry)
	{
		this.geometry = geometry;
		q.set(1.0, 0.0, 0.0, 0.0);
	}

	public Holder.copy(Holder src, Geometry geometry)
	{
		this.geometry = geometry;
		this.idx = src.idx;
		this.q = src.q;
	}

	public void update()
	{
		this.q.set(1.0, 0.0, 0.0, 0.0);
		foreach(uint idx in this.idx)
			this.q.times_quaternion(this.geometry.axes[idx].q);
	}

	public weak Axis? add_rotation_axis(string name,
					    double x, double y, double z)
	{
		Vector axis_v = Vector(x, y, z);

		int idx = this.geometry.add_rotation(name, axis_v);

		/* check that the axis is not already in the holder */
		foreach(uint idxx in this.idx)
			if (idx == idxx)
				return null;

		int len = this.idx.length;
		this.idx.resize(len + 1);
		this.idx[len] = idx;

		return this.geometry.axes[idx];
	}
}

public enum Hkl.GeometryType
{
	TWOC_VERTICAL,
	EULERIAN4C_VERTICAL,
	KAPPA4C_VERTICAL,
	EULERIAN6C,
	KAPPA6C,
}

public Hkl.Geometry hkl_geometry_factory_new(Hkl.GeometryType type, double[] parameters)
{
	Hkl.Geometry geom;

	switch(type) {
		case Hkl.GeometryType.TWOC_VERTICAL:
			geom = new Hkl.Geometry.TwoCV();
			break;
		case Hkl.GeometryType.EULERIAN4C_VERTICAL:
			geom = new Hkl.Geometry.E4CV();
			break;
		case Hkl.GeometryType.KAPPA4C_VERTICAL:
			geom = new Hkl.Geometry.K4CV(parameters[0]);
			break;
		case Hkl.GeometryType.EULERIAN6C:
			geom = new Hkl.Geometry.E6C();
			break;
		case Hkl.GeometryType.KAPPA6C:
			geom = new Hkl.Geometry.K6C(parameters[0]);
			break;
		default:
			geom = new Hkl.Geometry.E4CV();
			break;
	}

	return geom;
}


public class Hkl.Geometry
{
	public string name;
	public Source source;
	public Axis[] axes;
	public Holder[] holders;

	public Geometry()
	{
		this.source.set(1.054, 1.0, 0.0, 0.0);
	}

	public Geometry.TwoCV()
	{
		this.name = "TwoCV";
		this.source.set(1.054, 1.0, 0.0, 0.0);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("omega", 0.0, -1.0, 0.0);

		h = this.add_holder();
		h.add_rotation_axis("tth", 0.0, -1.0, 0.0);
	}

	public Geometry.E4CV()
	{
		this.name = "E4CV";
		this.source.set(1.54, 1.0, 0.0, 0.0);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("omega", 0.0, -1.0, 0.0);
		h.add_rotation_axis("chi", 1.0, 0.0, 0.0);
		h.add_rotation_axis("phi", 0.0, -1.0, 0.0);

		h = this.add_holder();
		h.add_rotation_axis("tth", 0.0, -1.0, 0.0);
	}

	public Geometry.K4CV(double alpha)
	{
		this.name = "K4CV";
		this.source.set(1.54, 1.0, 0.0, 0.0);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("komega", 0.0, -1.0, 0.0);
		h.add_rotation_axis("kappa", 0.0, -Math.cos(alpha), -Math.sin(alpha));
		h.add_rotation_axis("kphi", 0.0, -1.0, 0.0);

		h = this.add_holder();
		h.add_rotation_axis("tth", 0.0, -1.0, 0.0);
	}

	public Geometry.E6C()
	{
		this.name = "E6C";
		this.source.set(1.54, 1.0, 0.0, 0.0);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("mu", 0.0, 0.0, 1.0);
		h.add_rotation_axis("omega", 0.0, -1.0, 0.0);
		h.add_rotation_axis("chi", 1.0, 0.0, 0.0);
		h.add_rotation_axis("phi", 0.0, -1.0, 0.0);

		h = this.add_holder();
		h.add_rotation_axis("gamma", 0.0, 0.0, 1.0);
		h.add_rotation_axis("delta", 0.0, -1.0, 0.0);
	}

	public Geometry.K6C(double alpha)
	{
		this.name = "K6C";
		this.source.set(1.54, 1.0, 0.0, 0.0);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("mu", 0.0, 0.0, 1.0);
		h.add_rotation_axis("komega", 0.0, -1.0, 0.0);
		h.add_rotation_axis("kappa", 0.0, -Math.cos(alpha), -Math.sin(alpha));
		h.add_rotation_axis("kphi", 0.0, -1.0, 0.0);

		h = this.add_holder();
		h.add_rotation_axis("gamma", 0.0, 0.0, 1.0);
		h.add_rotation_axis("delta", 0.0, -1.0, 0.0);
	}

	public Geometry.copy(Geometry src)
	{
		this.name = src.name;
		this.source = src.source;
		this.axes = new Axis[src.axes.length];
		this.holders = new Holder[src.holders.length];
		// make a deep copy of the axes
		uint idx=0U;
		foreach(weak Axis axis in src.axes)
			this.axes[idx++] = new Axis.copy(axis);

		// make a deep copy of the holders
		idx = 0U;
		foreach(weak Holder holder in src.holders)
			this.holders[idx++].copy(holder, this);
	}

	public unowned Holder add_holder()
	{
		int length = this.holders.length;
		this.holders.resize(length + 1);
		this.holders[length] = new Holder(this);
		return this.holders[length];
	}

	public void update()
	{
		bool ko = false;

		foreach(weak Axis axis in this.axes)
			if(axis.changed){
				ko = true;
				break;
			}

		if(ko){
			foreach(weak Holder holder in this.holders)
				holder.update();

			foreach(weak Axis axis in this.axes)
				axis.changed = false;
		}
	}

	public weak Axis? get_axis_by_name(string name)
	{
		foreach(weak Axis axis in this.axes)
			if (axis.name == name)
				return axis;
		return null;
	}

	public void randomize()
	{
		foreach(weak Axis axis in this.axes)
			axis.randomize();
		this.update();
	}

	public bool set_values_v(double[] values) requires (values.length == this.axes.length)
	{
		uint idx=0;

		foreach(weak Axis axis in this.axes)
			axis.set_value(values[idx++]);
		this.update();
		return true;
	}

	public double distance(Geometry geometry)
	{
		double distance = 0.0;
		int i=0;

		foreach(weak Axis axis in this.axes)
			distance += Math.fabs(axis.value - geometry.axes[i++].value);

		return distance;
	}

	public double distance_orthodromic(Geometry geometry)
	{
		double distance = 0.0;
		int i=0;

		foreach(weak Axis axis in this.axes){
			double d = Math.fabs(Gsl.Trig.angle_restrict_symm(axis.value) - Gsl.Trig.angle_restrict_symm(geometry.axes[i++].value));
			if (d > Math.PI)
				d = 2.0 * Math.PI - d;
			distance += d;
		}

		return distance;
	}

	public bool closest_from_geometry_with_range(Geometry geometry)
	{
		size_t i;
		size_t len = this.axes.length;
		double[len] values = new double[len];
		bool ko = false;

		for(i=0;i<len;++i){
			values[i] = this.axes[i].get_value_closest(geometry.axes[i]);
			if(values[i].is_nan()){
				ko = true;
				break;
			}
		}
		if(!ko){
			for(i=0;i<len;++i)
				this.axes[i].set_value(values[i]);
			this.update();
		}
		return ko;
	}


	[CCode (instance_pos=-1)]
	public void fprintf(FileStream stream)
	{
		foreach(weak Axis axis in this.axes)
			stream.printf(" %s : %f", axis.name, axis.get_value_unit());
	}

	/* only used by Holder */
	public int add_rotation(string name, Hkl.Vector axis_v)
	{
		int i = 0;

		// check if an axis with the same name is on the axis list
		foreach(weak Axis axis in this.axes){
			if(axis.name == name){
				if (axis.axis_v.cmp(axis_v))
					return -1;
				else
					return i;
			}
			++i;
		}

		int len = this.axes.length;
		this.axes.resize(len + 1);
		this.axes[len] = new Axis(name, axis_v);

		return len;
	}

}

public class Hkl.GeometryList
{
	public Geometry[] geometries;

	public void add(Geometry geometry)
	{
		bool ok = true;
		foreach(weak Geometry geom in this.geometries)
			if(geometry.distance_orthodromic(geom) < EPSILON){
				ok = false;
				break;
			}
		if(ok){
			int len = this.geometries.length;
			this.geometries.resize(len + 1);
			this.geometries[len] = new Geometry.copy(geometry);
		}
	}

	public void clear()
	{
		this.geometries.resize(0);
	}

	public void sort(Geometry geometry)
	{
		int len = this.geometries.length;
		double[] distances = new double[len];
		int[] idx = new int[len];
		int i, x;
		int j, p;

		// compute the distances once for all
		for(i=0; i<len; ++i){
			distances[i] = geometry.distance(this.geometries[i]);
			idx[i] = i;
		}

		// insertion sorting
		for(i=1; i<len; ++i){
			x = idx[i];
			/* find the smallest idx p lower than i with distance[idx[p]] >= distance[x] */
			for(p=0; distances[idx[p]] < distances[x]; p++);
 
			/* move evythings in between p and i */
			for(j=i-1; j>=p; j--)
				idx[j+1] = idx[j];

			idx[p] = x; // insert the saved idx
		}

		// reorder the geometries.
		Geometry[] geometries = new Geometry[len];
		for(i=0; i<len; ++i)
			geometries[i] = this.geometries[idx[i]];
		this.geometries = geometries;
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
	{
		if(this.geometries.length > 0){
			foreach(weak Axis axis in this.geometries[0].axes)
				axis.fprintf(f);

			int i=0;
			foreach(weak Geometry geometry in this.geometries){
				f.printf("\n%d :", i++);
				foreach(weak Axis axis in geometry.axes){
					double value = axis.get_value_unit();
					if (axis.punit != null)
						f.printf(" % 9.6g %s", value, axis.punit.repr);
					else
						f.printf(" % 9.6g", value);

				}
				f.printf("\n   ");
				foreach(weak Axis axis in geometry.axes){
					double value = Gsl.Trig.angle_restrict_symm(axis.value) * axis.unit.factor(axis.punit);
					if (axis.punit != null)
						f.printf(" % 9.6g %s", value, axis.punit.repr);
					else
						f.printf(" % 9.6g", value);
				}
				f.printf("\n");
			}
		}
	}
}
