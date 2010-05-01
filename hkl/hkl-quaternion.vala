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
public struct Hkl.Quaternion
{
	public double a;
	public double b;
	public double c;
	public double d;

	public Quaternion(double a, double b, double c, double d)
	{
		this.set(a, b, c, d);
	}

	public Quaternion.from_vector(Vector v)
	{
		this.set(0.0, v.x, v.y, v.z);
	}

	public Quaternion.from_angle_and_axis(double angle, Vector v)
	{
		double c = Math.cos(angle / 2.0);
		double s = Math.sin(angle / 2.0) / v.norm2();

		this.set(c, s*v.x, s*v.y, s*v.z);
	}

	public void set(double a, double b, double c, double d)
	{
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream file)
	{
		file.printf("<%f, %f, %f, %f>", this.a, this.b, this.c, this.d);
	}


	/**compare two hkl_quaternions */
	public bool cmp(Quaternion q)
	{
		if ((Math.fabs(this.a - q.a) > EPSILON)
				|| (Math.fabs(this.b - q.b) > EPSILON)
				|| (Math.fabs(this.c - q.c) > EPSILON)
				|| (Math.fabs(this.d - q.d) > EPSILON))
			return true;
		else
			return false;
	}

	public void minus_quaternion(Quaternion q)
	{
		this.a -= q.a;
		this.b -= q.b;
		this.c -= q.c;
		this.d -= q.d;
	}

	public void times_quaternion(Quaternion q)
	{
		Quaternion tmp = this;
		weak Quaternion *Q;

		if (&q == &this)
			Q = &tmp;
		else
			Q = &q;

		this.a = tmp.a * Q->a - tmp.b * Q->b - tmp.c * Q->c - tmp.d * Q->d;
		this.b = tmp.a * Q->b + tmp.b * Q->a + tmp.c * Q->d - tmp.d * Q->c;
		this.c = tmp.a * Q->c - tmp.b * Q->d + tmp.c * Q->a + tmp.d * Q->b;
		this.d = tmp.a * Q->d + tmp.b * Q->c - tmp.c * Q->b + tmp.d * Q->a;
	}

	public double norm2()
	{
		return Math.sqrt(this.a * this.a + this.b * this.b
				+ this.c * this .c + this.d * this.d);
	}

	public void conjugate()
	{
		this.b = -this.b;
		this.c = -this.c;
		this.d = -this.d;
	}

	/**
	 *@brief Compute the rotation matrix of a Quaternion.
	 *\return The rotation matrix of a Quaternion.
	 *\todo optimize
	 *
	 *compute the rotation matrix corresponding to the unitary quaternion.
	 *\f$ q = a + b \cdot i + c \cdot j + d \cdot k \f$
	 *
	 *\f$
	 *\left(
	 *  \begin{array}{ccc}
	 *    a^2+b^2-c^2-d^2 & 2bc-2ad         & 2ac+2bd\\
	 *    2ad+2bc         & a^2-b^2+c^2-d^2 & 2cd-2ab\\
	 *    2bd-2ac         & 2ab+2cd         & a^2-b^2-c^2+d^2
	 *  \end{array}
	 *\right)
	 *\f$
	 */
	public void to_matrix(out Matrix m) requires (Math.fabs(this.norm2() - 1.0) < EPSILON)
	{
		m.m11 = this.a*this.a + this.b*this.b - this.c*this.c - this.d*this.d;
		m.m12 = 2 * (this.b*this.c - this.a*this.d);
		m.m13 = 2 * (this.a*this.c + this.b*this.d);

		m.m21 = 2 * (this.a*this.d + this.b*this.c);
		m.m22 = this.a*this.a - this.b*this.b + this.c*this.c - this.d*this.d;
		m.m23 = 2 * (this.c*this.d - this.a*this.b);

		m.m31 = 2 * (this.b*this.d - this.a*this.c);
		m.m32 = 2 * (this.a*this.b + this.c*this.d);
		m.m33 = this.a*this.a - this.b*this.b - this.c*this.c + this.d*this.d;
	}

	/**
	 *compute the axe and angle of the unitary quaternion angle [-pi, pi]
	 *if q is the (1, 0, 0, 0) quaternion return the (0,0,0) axe and a 0 angle
	 */
	public void to_angle_and_axe(out double angle, out Vector v) requires ( Math.fabs(this.norm2() - 1.0) < EPSILON)
	{
		double angle_2;
		double cos_angle_2;
		double sin_angle_2;

		// compute the angle
		cos_angle_2 = this.a;
		angle_2 = Math.acos(cos_angle_2);
		angle = 2 * angle_2;
		// we want an angle between -pi, pi
		if (angle > Math.PI)
			angle -= 2.0 * Math.PI;

		// compute the axe
		sin_angle_2 = Math.sin(angle_2);
		if (Math.fabs(sin_angle_2) > EPSILON) {
			// compute the axe using the vector part of the unitary quaterninon
			v.x = this.b / sin_angle_2;
			v.y = this.c / sin_angle_2;
			v.z = this.d / sin_angle_2;
		} else {
			angle = 0.0;
			v.x = v.y = v.z = 0.0;
		}
	}
}
