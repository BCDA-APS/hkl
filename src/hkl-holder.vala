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
public struct Hkl.Holder {
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

	public weak Axis? add_rotation_axis(string name,
			double x, double y, double z)
	{
		Vector axis_v = {x, y, z};
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

	public void update()
	{
		this.q.set(1.0, 0.0, 0.0, 0.0);
		foreach(uint idx in this.idx)
			this.q.times_quaternion(this.geometry.axes[idx].q);
	}
}
