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
public struct Hkl.Vector {
	public double x;
	public double y;
	public double z;

	public Vector(double x, double y, double z)
	{
		this.set(x, y, z);
	}

	public void set(double x, double y, double z)
	{
		this.x = x;
		this.y = y;
		this.z = z;
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
	{
		f.printf("|%f, %f, %f|", this.x, this.y, this.z);
	}

	public bool cmp(Vector v)
	{
		if (Math.fabs(this.x - v.x) > EPSILON)
			return true;
		if (Math.fabs(this.y - v.y) > EPSILON)
			return true;
		if (Math.fabs(this.z - v.z) > EPSILON)
			return true;
		return false;
	}

	public bool is_opposite(Vector v)
	{
		if ( (Math.fabs(this.x + v.x) > EPSILON)
				|| (Math.fabs(this.y + v.y) > EPSILON)
				|| (Math.fabs(this.z + v.z) > EPSILON)
		   )
			return false;
		else
			return true;
	}

	public void add_vector(Vector v)
	{
		this.x += v.x;
		this.y += v.y;
		this.z += v.z;
	}

	public void minus_vector(Vector v)
	{
		this.x -= v.x;
		this.y -= v.y;
		this.z -= v.z;
	}

	public void div_double(double d) requires ( d > EPSILON )
	{
		this.x /= d;
		this.y /= d;
		this.z /= d;
	}

	public void times_double(double d)
	{
		this.x *= d;
		this.y *= d;
		this.z *= d;
	}

	public void times_vector(Vector v)
	{
		this.x *= v.x;
		this.y *= v.y;
		this.z *= v.z;
	}

	public void times_matrix(Matrix m)
	{
		Vector tmp = this;
		this.x = tmp.x * m.m11 + tmp.y * m.m21 + tmp.z * m.m31;
		this.y = tmp.x * m.m12 + tmp.y * m.m22 + tmp.z * m.m32;
		this.z = tmp.x * m.m13 + tmp.y * m.m23 + tmp.z * m.m33;
	}

	public double sum()
	{
		return this.x + this.y + this.z;
	}

	public double scalar_product(Vector v)
	{
		return this.x * v.x + this.y * v.y + this.z * v.z;
	}

	public void vectorial_product(Vector v)
	{
		Vector tmp = this;
		this.x = tmp.y * v.z - tmp.z * v.y;
		this.y = tmp.z * v.x - tmp.x * v.z;
		this.z = tmp.x * v.y - tmp.y * v.x;
	}

	public double angle(Vector v)
	{
		double angle;
		double cos_angle;
		double norm = this.norm2() * v.norm2();

		cos_angle = this.scalar_product(v) / norm;

		// problem with round
		if (cos_angle >= 1.0)
			angle = 0.0;
		else
			if (cos_angle <= -1 )
				angle = Math.PI;
			else
				angle = Math.acos(cos_angle);
		return angle;
	}

	public double oriented_angle(Vector vector,
				     Vector ref)
	{
		double angle = this.angle(vector);
		Vector tmp = this;
		Vector ref_u = ref;

		tmp.vectorial_product(vector);
		tmp.normalize();
		ref_u.normalize();
		if (tmp.is_opposite(ref_u))
			angle = -angle;
		return angle;
	}

	public bool normalize()
	{
		bool res = false;

		double norm = this.norm2();
		if (norm > EPSILON){
			this.div_double(norm);
			res = true;
		}

		return res;
	}

	public bool is_colinear(Vector v)
	{
		Vector tmp = this;

		tmp.vectorial_product(v);
		return tmp.norm2() < EPSILON;
	}

	public void randomize()
	{
		this.x = Random.double_range(-1.0, 1.0);
		this.y = Random.double_range(-1.0, 1.0);
		this.z = Random.double_range(-1.0, 1.0);
	}


	public void randomize_vector(Vector v)
	{
		do
			this.randomize();
		while (!this.cmp(v));
	}

	public void randomize_vector_vector(Vector v, Vector v1)
	{
		do
			this.randomize();
		while (!this.cmp(v) || !this.cmp(v1));
	}

	public void rotated_around_vector(Vector axe, double angle)
	{
		double c = Math.cos(angle);
		double s = Math.sin(angle);
		Vector axe_n = axe;
		Vector tmp = this;

		axe_n.normalize();

		this.x = (c + (1 - c) * axe_n.x * axe_n.x) * tmp.x;
		this.x += ((1 - c) * axe_n.x * axe_n.y - axe_n.z * s) * tmp.y;
		this.x += ((1 - c) * axe_n.x * axe_n.z + axe_n.y * s) * tmp.z;

		this.y = ((1 - c) * axe_n.x * axe_n.y + axe_n.z * s) * tmp.x;
		this.y += (c + (1 - c) * axe_n.y * axe_n.y) * tmp.y;
		this.y += ((1 - c) * axe_n.y * axe_n.z - axe_n.x * s) * tmp.z;

		this.z = ((1 - c) * axe_n.x * axe_n.z - axe_n.y * s) * tmp.x;
		this.z += ((1 - c) * axe_n.y * axe_n.z + axe_n.x * s) * tmp.y;
		this.z += (c + (1 - c) * axe_n.z * axe_n.z) * tmp.z;
	}

	public double norm2()
	{
		return Math.sqrt(this.scalar_product(this));
	}


	public void rotated_quaternion(Quaternion qr)
	{
		Quaternion q;
		Quaternion tmp = {0};

		// compute qr * qv * *qr
		q = qr;
		tmp.from_vector(this);

		q.times_quaternion(tmp);
		tmp = qr;
		tmp.conjugate();
		q.times_quaternion(tmp);

		this.x = q.b;
		this.y = q.c;
		this.z = q.d;
	}

	/**
	 * @brief check if the hkl_vector is null
	 * @return true if all |elements| are below HKL_EPSILON, false otherwise
	 * @todo test
	 */
	public bool is_null()
	{
		bool res = true;
		if ((Math.fabs(this.x) > EPSILON)
		    || (Math.fabs(this.y) > EPSILON)
		    || (Math.fabs(this.z) > EPSILON))
			res = false;

		return res;
	}

	public void project_on_plan(Vector plan)
	{
		Vector tmp = plan;

		tmp.normalize();
		tmp.times_double(this.scalar_product(tmp));
		this.minus_vector(tmp);
	}

}

