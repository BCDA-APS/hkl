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
public class Hkl.Parameter {
	public string name;
	public Interval range;
	public double value;
	public weak Unit? unit;
	public weak Unit? punit;
	public bool not_to_fit;
	public bool changed;

	public Parameter(string name, double min, double value, double max,
			 bool not_to_fit, bool changed,
			 Unit? unit, Unit? punit)
	{
		this.name = name;
		this.range.min = min;
		this.value = value;
		this.range.max = max;
		this.not_to_fit = not_to_fit;
		this.changed = changed;
		this.unit = unit;
		this.punit = punit;
	}

	public Parameter.copy(Parameter parameter)
	{
		this.name = parameter.name;
		this.range = parameter.range;
		this.value = parameter.value;
		this.not_to_fit = parameter.not_to_fit;
		this.changed = parameter.changed;
		this.unit = parameter.unit;
		this.punit = parameter.punit;
	}

	public double get_value()
	{
		return this.value;
	}

	public double get_value_unit()
	{
		double factor = this.unit.factor(this.punit);
		return factor * this.value;
	}

	public void set_value(double value)
	{
		this.value = value;
		this.changed = true;
	}

	public void set_value_unit(double value)
	{
		double factor = this.unit.factor(this.punit);
		this.value = value / factor;
		this.changed = true;
	}

	public void get_range_unit(out double min, out double max)
	{
		double factor = this.unit.factor(this.punit);
		min = factor * this.range.min;
		max = factor * this.range.max;
	}

	public void set_range(double min, double max)
	{
		this.range.min = min;
		this.range.max = max;
	}

	public void set_range_unit(double min, double max)
	{
		double factor = this.unit.factor(this.punit);
		this.range.min = min / factor;
		this.range.max = max / factor;
	}

	public virtual void randomize()
	{
		if (!this.not_to_fit){
			this.value = Random.double_range(this.range.min, this.range.max);
			this.changed = true;
		}
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
	{
		double factor = this.unit.factor(this.punit);
		if (this.punit != null)
			f.printf("\"%s\" : %f %s [%f : %f]",
					this.name,
					this.value * factor,
					this.punit.repr,
					this.range.min * factor,
					this.range.max * factor);
		else
			f.printf("\"%s\" : %f [%f : %f]",
					this.name,
					this.value * factor,
					this.range.min * factor,
					this.range.max * factor);
	}
}
