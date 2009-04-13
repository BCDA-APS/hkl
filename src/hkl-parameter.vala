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
	public weak string name;
	public Interval range;
	public double value;
	public Hkl.Unit? unit;
	public Hkl.Unit? punit;
	public bool not_to_fit;
	public bool changed;

	/* becarefull only static name */
	public Parameter(string name, double min, double value, double max,
			 bool not_to_fit, bool changed,
			 Hkl.Unit unit, Hkl.Unit punit)
	{
		this.set(name, min, value, max, not_to_fit, changed, unit, punit);
	}

	public Parameter.copy(Parameter parameter)
	{
		this.name = parameter.name;
		this.range = parameter.range;
		this.value = parameter.value;
		this.unit = parameter.unit;
		this.punit = parameter.punit;
		this.not_to_fit = parameter.not_to_fit;
		this.changed = parameter.changed;
	}
	public void set(string name, double min, double value, double max,
			bool not_to_fit, bool changed,
			Hkl.Unit unit, Hkl.Unit punit)
	{
		this.name = name;
		this.range.min = min;
		this.range.max = max;
		this.value = value;
		this.unit = unit;
		this.punit = punit;
		this.not_to_fit = not_to_fit;
		this.changed = changed;
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

	public virtual void set_value(double value)
	{
		this.value = value;
		this.changed = true;
	}

	public virtual void set_value_unit(double value)
	{
		double factor = this.unit.factor(this.punit);
		this.value = value / factor;
		this.changed = true;
	}

	public virtual void randomize()
	{
		if (!this.not_to_fit)
			this.value = Random.double_range(this.range.min, this.range.max);
	}

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
