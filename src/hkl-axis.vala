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

	public override void set_value(double value)
	{
		base.set_value(value);
		this.q.from_angle_and_axe(this.value, this.axis_v);
	}

	public override void set_value_unit(double value)
	{
		base.set_value_unit(value);
		this.q.from_angle_and_axe(this.value, this.axis_v);
	}

	public override void randomize()
	{
		base.randomize();
		this.q.from_angle_and_axe(this.value, this.axis_v);
		this.changed = true;
	}
}
