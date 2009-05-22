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
public struct Hkl.Source
{
	public double wave_length;
	public Vector direction;

	public Source(double wave_length, double x, double y, double z) 
	{
		this.set(wave_length, x, y, z);
	}

	public void set(double wave_length, double x, double y, double z)
	{
		double norm = Math.sqrt(x*x + y*y + z*z);

		this.wave_length = wave_length;
		this.direction.set(x, y, z);
		this.direction.div_double(norm);		
	}

	/** compare two sources */
	public bool cmp(Source s)
	{
		if (Math.fabs(this.wave_length - s.wave_length) < EPSILON
				&& this.direction.is_colinear(s.direction))
			return false;
		else
			return true;
	}

	/** compute the ki Vector */
	public void compute_ki(out Vector ki)
	{
		double k = TAU / this.wave_length;
		ki = this.direction;
		ki.times_double(k);
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
	{
		f.printf("%f", this.wave_length);
	}
}
