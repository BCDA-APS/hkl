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

	public unowned Axis? add_rotation_axis(string name,
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

public struct Hkl.GeometryConfig
{
	public string name;
	public Hkl.GeometryType type;
}

[CCode (array_null_terminated = true, array_length = false)]
static const Hkl.GeometryConfig hkl_geometry_factory_configs[] =
{
	{"TwoC", Hkl.GeometryType.TWOC_VERTICAL},
	{"E4CV", Hkl.GeometryType.EULERIAN4C_VERTICAL},
 	{"K4CV", Hkl.GeometryType.KAPPA4C_VERTICAL},
	{"E6C", Hkl.GeometryType.EULERIAN6C},
	{"K6C", Hkl.GeometryType.KAPPA6C},
	{"ZAXIS", Hkl.GeometryType.ZAXIS},
	{null}
};

public enum Hkl.GeometryType
{
	TWOC_VERTICAL,
	EULERIAN4C_VERTICAL,
	KAPPA4C_VERTICAL,
	EULERIAN6C,
	KAPPA6C,
	ZAXIS
}

public Hkl.GeometryConfig? hkl_geometry_factory_get_config_from_type(Hkl.GeometryType type)
{
	foreach(weak Hkl.GeometryConfig config in hkl_geometry_factory_configs){
		if (config.type == type)
				  return config;
	}
	return null;
}

public Hkl.Geometry hkl_geometry_factory_new(Hkl.GeometryConfig config, ...)
{
	Hkl.Geometry geom;
	var l = va_list();

	switch(config.type) {
	case Hkl.GeometryType.TWOC_VERTICAL:
		geom = new Hkl.Geometry.TwoCV(config);
		break;
	case Hkl.GeometryType.EULERIAN4C_VERTICAL:
		geom = new Hkl.Geometry.E4CV(config);
		break;
	case Hkl.GeometryType.KAPPA4C_VERTICAL:
		geom = new Hkl.Geometry.K4CV(config, l.arg());
		break;
	case Hkl.GeometryType.EULERIAN6C:
		geom = new Hkl.Geometry.E6C(config);
		break;
	case Hkl.GeometryType.KAPPA6C:
		geom = new Hkl.Geometry.K6C(config, l.arg());
		break;
	default:
		geom = new Hkl.Geometry.E4CV(config);
		break;
	}

	return geom;
}


public class Hkl.Geometry
{
	public GeometryConfig config;
	public Source source;
	public Axis[] axes;
	public Holder[] holders;

	public Geometry()
	{
		this.source.set(SOURCE_DEFAULT_WAVE_LENGTH, 1.0, 0.0, 0.0);
	}

	public Geometry.TwoCV(Hkl.GeometryConfig config)
	{
		this.config = config;
		this.source.set(1.054, 1.0, 0.0, 0.0);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("omega", 0.0, -1.0, 0.0);

		h = this.add_holder();
		h.add_rotation_axis("tth", 0.0, -1.0, 0.0);
	}

	public Geometry.E4CV(Hkl.GeometryConfig config)
	{
		this.config = config;
		this.source.set(1.54, 1.0, 0.0, 0.0);

		Holder h = this.add_holder();
		h.add_rotation_axis("omega", 0.0, -1.0, 0.0);
		h.add_rotation_axis("chi", 1.0, 0.0, 0.0);
		h.add_rotation_axis("phi", 0.0, -1.0, 0.0);

		h = this.add_holder();
		h.add_rotation_axis("tth", 0.0, -1.0, 0.0);
	}

	public Geometry.K4CV(Hkl.GeometryConfig config, double alpha)
	{
		this.config = config;
		this.source.set(1.54, 1.0, 0.0, 0.0);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("komega", 0.0, -1.0, 0.0);
		h.add_rotation_axis("kappa", 0.0, -Math.cos(alpha), -Math.sin(alpha));
		h.add_rotation_axis("kphi", 0.0, -1.0, 0.0);

		h = this.add_holder();
		h.add_rotation_axis("tth", 0.0, -1.0, 0.0);
	}

	public Geometry.E6C(Hkl.GeometryConfig config)
	{
		this.config.name = "E6C";
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

	public Geometry.K6C(Hkl.GeometryConfig config, double alpha)
	{
		this.config = config;
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
		this.config = src.config;
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
			this.holders[idx++] = new Holder.copy(holder, this);
	}

	public void init_geometry(Hkl.Geometry geometry)
	{
		uint idx = 0u;

		foreach(weak Axis axis in this.axes)
			axis.set_value(geometry.axes[idx++].get_value());
		this.update();
	}

	public unowned Holder? add_holder()
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

	public unowned Axis? get_axis_by_name(string name)
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

	public bool set_values_v(size_t len, ...) requires (len == this.axes.length)
	{
		var l = va_list();

		foreach(weak Axis axis in this.axes)
			axis.set_value(l.arg());
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

	public bool is_valid()
	{
		foreach(weak Axis axis in this.axes)
			if(!axis.is_valid())
				return false;
		return true;
	}

}

public class Hkl.GeometryListItem
{
	public Hkl.Geometry geometry;
}

public class Hkl.GeometryList
{
	public GeometryListItem[] items;
	public delegate void Multiply();
	
	virtual void _multiply(Hkl.Geometry geometry)
	{
	}

	public void multiply()
	{
		foreach(GeometryListItem item in this.items)
			this._multiply(item.geometry);
	}

	// look for a owne transfer to optimize the code.
	public void add(Geometry geometry)
	{
		bool ok = true;
		foreach(weak GeometryListItem item in this.items)
			if(geometry.distance_orthodromic(item.geometry) < EPSILON){
				ok = false;
				break;
			}
		if(ok){
			int len = this.items.length;
			this.items.resize(len + 1);
			this.items[len].geometry = new Geometry.copy(geometry);
		}
	}

	public void clear()
	{
		this.items.resize(0);
	}

	public void sort(Geometry geometry)
	{
		int len = this.items.length;
		double[] distances = new double[len];
		int[] idx = new int[len];
		int i, x;
		int j, p;

		// compute the distances once for all
		for(i=0; i<len; ++i){
			distances[i] = geometry.distance(this.items[i].geometry);
			idx[i] = i;
		}

		// insertion sorting
		for(i=1; i<len; ++i){
			x = idx[i];
			/* find the smallest idx p lower than i with distance[idx[p]] >= distance[x] */
			for(p=0; distances[idx[p]] < distances[x]; p++);
 
			/* move everythings in between p and i */
			for(j=i-1; j>=p; j--)
				idx[j+1] = idx[j];

			idx[p] = x; // insert the saved idx
		}

		// reorder the geometries.
		GeometryListItem[] items = new GeometryListItem[len];
		for(i=0; i<len; ++i)
			items[i] = this.items[idx[i]];
		this.items = items;
	}

	void perm_r(Hkl.Geometry reference, Hkl.Geometry geometry, bool[] perm, uint axis_idx)
	{
		if (axis_idx == geometry.axes.length){
			if(reference.distance(geometry) > EPSILON)
				this.add(new Hkl.Geometry.copy(geometry));
		}else{
			if(perm[axis_idx] == true){
				Hkl.Axis axis;
				double max;
				double value;
				double value0;

				axis = geometry.axes[axis_idx];
				max = axis.range.max;
				value = axis.get_value();
				value0 = value;
				do{
					this.perm_r(reference, geometry, perm, axis_idx + 1);
					value +=  2*Math.PI;
					if(value <= (max + EPSILON))
						axis.set_value(value);
				}while(value <= (max + EPSILON));
				axis.set_value(value0);
			} else
				this.perm_r(reference, geometry, perm, axis_idx + 1);
		}	
	}

	public void multiply_from_range()
	{
		foreach(weak GeometryListItem item in this.items){
			Hkl.Geometry geometry;

			geometry = new Hkl.Geometry.copy(item.geometry);
			bool[] perm = new bool[item.geometry.axes.length];

			// find axes to permute and the first solution of thoses axes;
			uint i=0u;
			foreach(weak Axis axis in geometry.axes){
				perm[i] = axis.is_value_compatible_with_range();
				if (perm[i++] == true)
					axis.set_value_smallest_in_range();
			}

			this.perm_r(item.geometry, geometry, perm, 0);
		}
	}

	public int len()
	{
		return this.items.length;
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
	{
		if(this.items.length > 0){
			foreach(weak Axis axis in this.items[0].geometry.axes)
				axis.fprintf(f);

			int i=0;
			foreach(weak GeometryListItem item in this.items){
				f.printf("\n%d :", i++);
				foreach(weak Axis axis in item.geometry.axes){
					double value = axis.get_value_unit();
					if (axis.punit != null)
						f.printf(" % 9.6g %s", value, axis.punit.repr);
					else
						f.printf(" % 9.6g", value);
				}
				f.printf("\n   ");
				foreach(weak Axis axis in item.geometry.axes){
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

	public void remove_invalid()
	{
		int i;

		for(i=0; i<this.items.length; ++i){
			if(!this.items[i].geometry.is_valid()){
				this.items.move(i+1, i, this.items.length-i);
			}
		}
	}
}

/* use only for the GeometryList */
static void kappa_2_kappap(double komega, double kappa, double kphi, double alpha,
			   out double komegap, out double kappap, out double kphip)
{
	double p;
	double omega;
	double phi;

	p = Math.atan(Math.tan(kappa/2.0) * Math.cos(alpha));
	omega = komega + p - Math.PI_2;
	phi = kphi + p + Math.PI_2;

	komegap = Gsl.Trig.angle_restrict_symm(2*omega - komega);
	kappap = -kappa;
	kphip = Gsl.Trig.angle_restrict_symm(2*phi - kphi);

}

public class Hkl.GeometryListKappa4C : Hkl.GeometryList
{
	public void _multiply(Hkl.Geometry geometry)
	{
		Hkl.Geometry copy;
		double komega, komegap;
		double kappa, kappap;
		double kphi, kphip;

		komega = geometry.axes[0].get_value();
		kappa = geometry.axes[1].get_value();
		kphi = geometry.axes[2].get_value();

		kappa_2_kappap(komega, kappa, kphi, 50 * DEGTORAD, out komegap, out kappap, out kphip);

		copy = new Hkl.Geometry.copy(geometry);
		copy.axes[0].set_value(komegap);
		copy.axes[1].set_value(kappap);
		copy.axes[2].set_value(kphip);
		copy.update();

		this.add(copy);
	}	
}

public class Hkl.GeometryListKappa6C : Hkl.GeometryList
{
	public void _multiply(Hkl.Geometry geometry)
	{
		Hkl.Geometry copy;
		double komega, komegap;
		double kappa, kappap;
		double kphi, kphip;

		komega = geometry.axes[1].get_value();
		kappa = geometry.axes[2].get_value();
		kphi = geometry.axes[3].get_value();

		kappa_2_kappap(komega, kappa, kphi, 50 * DEGTORAD, out komegap, out kappap, out kphip);

		copy = new Hkl.Geometry.copy(geometry);
		copy.axes[1].set_value(komegap);
		copy.axes[2].set_value(kappap);
		copy.axes[3].set_value(kphip);
		copy.update();

		this.add(copy);
	}	
}
