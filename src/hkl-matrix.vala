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
public struct Hkl.Matrix {
	public double m11;
	public double m12;
	public double m13;
	public double m21;
	public double m22;
	public double m23;
	public double m31;
	public double m32;
	public double m33;

	public void set(double m11, double m12, double m13,
			double m21, double m22, double m23,
			double m31, double m32, double m33)
	{
		this.m11 = m11;
		this.m12 = m12;
		this.m13 = m13;
		this.m21 = m21;
		this.m22 = m22;
		this.m23 = m23;
		this.m31 = m31;
		this.m32 = m32;
		this.m33 = m33;
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream file)
	{
		file.printf("|%f, %f, %f|\n", this.m11, this.m12, this.m13);
		file.printf("|%f, %f, %f|\n", this.m21, this.m22, this.m23);
		file.printf("|%f, %f, %f|\n", this.m31, this.m32, this.m33);
	}


	public bool cmp(Matrix m)
	{
		if ((Math.fabs(this.m11 - m.m11) > EPSILON)
				|| (Math.fabs(this.m12 - m.m12) > EPSILON)
				|| (Math.fabs(this.m13 - m.m13) > EPSILON)
				|| (Math.fabs(this.m21 - m.m21) > EPSILON)
				|| (Math.fabs(this.m22 - m.m22) > EPSILON)
				|| (Math.fabs(this.m23 - m.m23) > EPSILON)
				|| (Math.fabs(this.m31 - m.m31) > EPSILON)
				|| (Math.fabs(this.m32 - m.m32) > EPSILON)
				|| (Math.fabs(this.m33 - m.m33) > EPSILON)
		   )
			return true;
		else
			return false;
	}

	public void from_two_vector(Vector v1, Vector v2)
	{
		Vector x, y, z;

		x = v1;
		x.normalize();

		z = v1;
		z.vectorial_product(v2);
		z.normalize();

		y = z;
		y.vectorial_product(x);

		this.m11 = x.data[0]; this.m12 = y.data[0]; this.m13 = z.data[0];
		this.m21 = x.data[1]; this.m22 = y.data[1]; this.m23 = z.data[1];
		this.m31 = x.data[2]; this.m32 = y.data[2]; this.m33 = z.data[2];
	}

	public void from_euler(double euler_x, double euler_y, double euler_z)
	{
		double A = Math.cos(euler_x);
		double B = Math.sin(euler_x);
		double C = Math.cos(euler_y);
		double D = Math.sin(euler_y);
		double E = Math.cos(euler_z);
		double F = Math.sin(euler_z);
		double AD = A *D;
		double BD = B *D;

		this.m11 = C*E;
		this.m12 =-C*F;
		this.m13 = D;
		this.m21 = BD *E + A *F;
		this.m22 =-BD *F + A *E;
		this.m23 =-B *C;
		this.m31 =-AD *E + B *F;
		this.m32 = AD *F + B *E;
		this.m33 = A *C;
	}

	public void to_euler(out double euler_x, out double euler_y, out double euler_z)
	{
		double tx, ty;
		double C;

		euler_y = Math.asin( this.m13 );      /*Calculate Y-axis angle */
		C = Math.cos( euler_y );
		if (Math.fabs(C) > EPSILON) {
			/*Gimball lock? */
			tx       =  this.m33 / C; /*No, so get X-axis angle */
			ty       = -this.m23 / C;
			euler_x = Math.atan2( ty, tx );
			tx       =  this.m11 / C; /*Get Z-axis angle */
			ty       = -this.m12 / C;
			euler_z = Math.atan2( ty, tx );
		} else {
			/*Gimball lock has occurred */
			euler_x = 0.0;              /*Set X-axis angle to zero */
			tx       =  this.m22;    /*And calculate Z-axis angle */
			ty       =  this.m21;
			euler_z = Math.atan2( ty, tx );
		}
	}

	public void times_matrix(Matrix m)
	{
		Matrix tmp = this;
		Matrix *M1;
		if (&m == &this)
			M1 = &tmp;
		else
			M1 = &m;

		this.m11 = tmp.m11 * M1->m11 + tmp.m12 * M1->m21 + tmp.m13 * M1->m31;
		this.m12 = tmp.m11 * M1->m12 + tmp.m12 * M1->m22 + tmp.m13 * M1->m32;
		this.m13 = tmp.m11 * M1->m13 + tmp.m12 * M1->m23 + tmp.m13 * M1->m33;

		this.m21 = tmp.m21 * M1->m11 + tmp.m22 * M1->m21 + tmp.m23 * M1->m31;
		this.m22 = tmp.m21 * M1->m12 + tmp.m22 * M1->m22 + tmp.m23 * M1->m32;
		this.m23 = tmp.m21 * M1->m13 + tmp.m22 * M1->m23 + tmp.m23 * M1->m33;

		this.m31 = tmp.m31 * M1->m11 + tmp.m32 * M1->m21 + tmp.m33 * M1->m31;
		this.m32 = tmp.m31 * M1->m12 + tmp.m32 * M1->m22 + tmp.m33 * M1->m32;
		this.m33 = tmp.m31 * M1->m13 + tmp.m32 * M1->m23 + tmp.m33 * M1->m33;
	}

	public void times_vector(ref Vector v)
	{
		Vector tmp = v;

		v.data[0] = tmp.data[0] * this.m11 + tmp.data[1] * this.m12 + tmp.data[2] * this.m13;
		v.data[1] = tmp.data[0] * this.m21 + tmp.data[1] * this.m22 + tmp.data[2] * this.m23;
		v.data[2] = tmp.data[0] * this.m31 + tmp.data[1] * this.m32 + tmp.data[2] * this.m33;
	}

	public void transpose()
	{
		double tmp;

		tmp = this.m21; this.m21 = this.m12; this.m12 = tmp;
		tmp = this.m23; this.m23 = this.m32; this.m32 = tmp;
		tmp = this.m31; this.m31 = this.m13; this.m13 = tmp;
	}

	public double det()
	{
		double det;

		det  =  this.m11 * (this.m22 * this.m33 - this.m32 * this.m23);
		det += -this.m12 * (this.m21 * this.m33 - this.m31 * this.m23);
		det +=  this.m13 * (this.m21 * this.m32 - this.m31 * this.m22);

		return det;
	}

	public void solve(out Vector x, Vector b)
	{
		double det = this.det();

		if (Math.fabs(det) > EPSILON) {
			x.data[0] =   b.data[0] * (this.m22*this.m33 - this.m23*this.m32);
			x.data[0] += -b.data[1] * (this.m12*this.m33 - this.m13*this.m32);
			x.data[0] +=  b.data[2] * (this.m12*this.m23 - this.m13*this.m22);

			x.data[1] =  -b.data[0] * (this.m21*this.m33 - this.m23*this.m31);
			x.data[1] +=  b.data[1] * (this.m11*this.m33 - this.m13*this.m31);
			x.data[1] += -b.data[2] * (this.m11*this.m23 - this.m13*this.m21);

			x.data[2] =   b.data[0] * (this.m21*this.m32 - this.m22*this.m31);
			x.data[2] += -b.data[1] * (this.m11*this.m32 - this.m12*this.m31);
			x.data[2] +=  b.data[2] * (this.m11*this.m22 - this.m12*this.m21);

			x.div_double(det);
		}
	}
}
