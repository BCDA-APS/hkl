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
	public double data[3];

	public Vector(double x, double y, double z)
	{
		this.set(x, y, z);
	}

	public void set(double x, double y, double z)
	{
		this.data[0] = x;
		this.data[1] = y;
		this.data[2] = z;
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
	{
		f.printf("|%f, %f, %f|", this.data[0], this.data[1], this.data[2]);
	}

	public bool cmp(Vector v)
	{
		for(int i=0; i<3; ++i)
			if (Math.fabs(this.data[i] - v.data[i]) > EPSILON)
				return true;
		return false;
	}

	public bool is_opposite(Vector v)
	{
		for(int i=0; i<3; ++i)
			if (Math.fabs(this.data[i] + v.data[i]) > EPSILON)
				return false;
		return true;
	}

	public void add_vector(Vector v)
	{
		this.data[0] += v.data[0];
		this.data[1] += v.data[1];
		this.data[2] += v.data[2];
	}

	public void minus_vector(Vector v)
	{
		this.data[0] -= v.data[0];
		this.data[1] -= v.data[1];
		this.data[2] -= v.data[2];
	}

	public void div_double(double d) requires ( d > EPSILON )
	{
		this.data[0] /= d;
		this.data[1] /= d;
		this.data[2] /= d;
	}

	public void times_double(double d)
	{
		this.data[0] *= d;
		this.data[1] *= d;
		this.data[2] *= d;
	}

	public void times_vector(Vector v)
	{
		this.data[0] *= v.data[0];
		this.data[1] *= v.data[1];
		this.data[2] *= v.data[2];
	}

	public void times_matrix(Matrix m)
	{
		Vector tmp = this;
		this.data[0] = tmp.data[0] * m.m11 + tmp.data[1] * m.m21 + tmp.data[2] * m.m31;
		this.data[1] = tmp.data[0] * m.m12 + tmp.data[1] * m.m22 + tmp.data[2] * m.m32;
		this.data[2] = tmp.data[0] * m.m13 + tmp.data[1] * m.m23 + tmp.data[2] * m.m33;
	}

	public double sum()
	{
		return this.data[0] + this.data[1] + this.data[2];
	}

	public double scalar_product(Vector v)
	{
		return this.data[0] * v.data[0] + this.data[1] * v.data[1] + this.data[2] * v.data[2];
	}

	public void vectorial_product(Vector v)
	{
		Vector tmp = this;
		this.data[0] = tmp.data[1] * v.data[2] - tmp.data[2] * v.data[1];
		this.data[1] = tmp.data[2] * v.data[0] - tmp.data[0] * v.data[2];
		this.data[2] = tmp.data[0] * v.data[1] - tmp.data[1] * v.data[0];
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
		this.data[0] = Random.double_range(-1.0, 1.0);
		this.data[1] = Random.double_range(-1.0, 1.0);
		this.data[2] = Random.double_range(-1.0, 1.0);
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

		this.data[0] = (c + (1 - c) * axe_n.data[0] * axe_n.data[0]) * tmp.data[0];
		this.data[0] += ((1 - c) * axe_n.data[0] * axe_n.data[1] - axe_n.data[2] * s) * tmp.data[1];
		this.data[0] += ((1 - c) * axe_n.data[0] * axe_n.data[2] + axe_n.data[1] * s) * tmp.data[2];

		this.data[1] = ((1 - c) * axe_n.data[0] * axe_n.data[1] + axe_n.data[2] * s) * tmp.data[0];
		this.data[1] += (c + (1 - c) * axe_n.data[1] * axe_n.data[1]) * tmp.data[1];
		this.data[1] += ((1 - c) * axe_n.data[1] * axe_n.data[2] - axe_n.data[0] * s) * tmp.data[2];

		this.data[2] = ((1 - c) * axe_n.data[0] * axe_n.data[2] - axe_n.data[1] * s) * tmp.data[0];
		this.data[2] += ((1 - c) * axe_n.data[1] * axe_n.data[2] + axe_n.data[0] * s) * tmp.data[1];
		this.data[2] += (c + (1 - c) * axe_n.data[2] * axe_n.data[2]) * tmp.data[2];
	}

	public double norm2()
	{
		return Math.sqrt(this.scalar_product(this));
	}


	public void rotated_quaternion(Quaternion qr)
	{
		Quaternion q;
		Quaternion tmp;

		// compute qr * qv * *qr
		q = qr;
		tmp = Quaternion.from_vector(this);

		q.times_quaternion(tmp);
		tmp = qr;
		tmp.conjugate();
		q.times_quaternion(tmp);

		this.data[0] = q.data[1];
		this.data[1] = q.data[2];
		this.data[2] = q.data[3];
	}

	/**
	 * @brief check if the hkl_vector is null
	 * @return true if all |elements| are below HKL_EPSILON, false otherwise
	 * @todo test
	 */
	public bool is_null()
	{
		bool res = true;
		if ((Math.fabs(this.data[0]) > EPSILON)
		    || (Math.fabs(this.data[1]) > EPSILON)
		    || (Math.fabs(this.data[2]) > EPSILON))
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

