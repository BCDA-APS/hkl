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
public class Hkl.Axis : Hkl.Parameter {
	public Vector axis_v;
	public Quaternion q;

	void update()
	{
		if(this.changed)
			this.q.from_angle_and_axe(this.value, this.axis_v);		
	}
	
	/*
	 * given a current position of angle a min and max interval find the closest
	 * equivalent angle + n delta_angle in a given direction.
	 * CAUSION angle MUST be in [min, max] otherwise...
	 */
	static void find_angle(double current, ref double angle, ref double distance,
			       double min, double max, double delta_angle)
	{
		double new_angle = angle;
		double new_distance = distance;
		
		while(new_angle >= min && new_angle <= max) {
			new_distance = Math.fabs(new_angle - current);
			if (new_distance <= distance) {
				angle = new_angle;
				distance = new_distance;
			}
			new_angle += delta_angle;
		}
	}

	/*
	 * check if the angle or its equivalent is in between [min, max]
	 */
	bool is_value_compatible_with_range()
	{
		double c = Math.cos(this.value);
		Interval c_r = this.range;

		c_r.cos();

		if (c_r.min <= c && c <= c_r.max) {
			double s = Math.sin(this.value);
			Interval s_r = this.range;

			s_r.sin();

			if (s_r.min <= s && s <= s_r.max)
				return true;
		}
		return false; 
	}


	/* becareful the name must be a static string */
	public Axis(string name, Vector axis_v)
	{
		base(name, -Math.PI, 0.0, Math.PI,
				false, false,
				hkl_unit_angle_rad, hkl_unit_angle_deg);
		this.axis_v = axis_v;
		this.q = Quaternion(1.0, 0.0, 0.0, 0.0);
	}

	public Axis.copy(Axis axis)
	{
		base.copy(this);
		this.axis_v = axis.axis_v;
		this.q = axis.q;
	}

	public double get_value_closest(Axis axis)
	{
	        double angle = this.value;

		if(this.is_value_compatible_with_range()){
			if(this.range.length() >= 2*Math.PI){
				int k;
				double current = axis.value;
				double distance = Math.fabs(current - angle);
				double delta = 2.0 * Math.PI;
				double min = this.range.min;
				double max = this.range.max;

				// three cases
				if (angle > max) {
					k = (int)(Math.floor((max - angle) / delta));
					angle += k * delta;
					find_angle(current, ref angle, ref distance, min, max, -delta);
				} else if (angle < min) {
					k = (int) (Math.ceil((min - angle) / delta));
					angle += k * delta;
					find_angle(current, ref angle, ref distance, min, max, delta);
				} else {
					find_angle(current, ref angle, ref distance, min, max, -delta);
					find_angle(current, ref angle, ref distance, min, max, delta);
				}
			}
		}else
			angle = double.NAN;
		return angle;	
	}

	public double get_value_closest_unit(Axis axis)
	{
		double factor = this.unit.factor(this.punit);
		return factor * this.get_value_closest(axis);
	}


	public override void set_value(double value)
	{
		base.set_value(value);
		this.update();
	}

	public override void set_value_unit(double value)
	{
		base.set_value_unit(value);
		this.update();
	}

	public override void randomize()
	{
		base.randomize();
		this.update();
	}

	/* to optimize */
	public void get_quaternion(out Quaternion q)
	{
		q.from_angle_and_axe(this.value, this.axis_v);
	}

	[CCode (instance_pos=-1)]
	public new void fprintf(FileStream f)
	{
		base.fprintf(f);
		this.axis_v.fprintf(f);
		this.q.fprintf(f);
	}
}
