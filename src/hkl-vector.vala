public struct Hkl.Vector {
	public double x;
	public double y;
	public double z;

	public void set(double x, double y, double z)
	{
		this.x = x;
		this.y = y;
		this.z = z;
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

	public double norm2()
	{
		return Math.sqrt(this.scalar_product(this));
	}

	public void normalize()
	{
		this.div_double(this.norm2());
	}

	public double angle(Vector v)
	{
		double angle;
		double cos_angle;
		double norm = this.norm2() * v.norm2();

		cos_angle = this.scalar_product(v) / norm;

		// problem with round
		if (cos_angle >= 1.)
			angle = 0.;
		else
			if (cos_angle <= -1 )
				angle = Math.PI;
			else
				angle = Math.acos(cos_angle);
		return angle;
	}

	public bool is_colinear(Vector v)
	{
		Vector tmp = this;

		tmp.vectorial_product(v);
		return tmp.norm2() < EPSILON;
	}

	public void randomize()
	{
		this.x = Random.double_range(-1., 1.);
		this.y = Random.double_range(-1., 1.);
		this.z = Random.double_range(-1., 1.);
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

	public void rotated_quaternion(Quaternion qr)
	{
		Quaternion q;
		Quaternion tmp;

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

}

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

		this.m11 = x.x; this.m12 = y.x; this.m13 = z.x;
		this.m21 = x.y; this.m22 = y.y; this.m23 = z.y;
		this.m31 = x.z; this.m32 = y.z; this.m33 = z.z;
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
			euler_x = 0.;              /*Set X-axis angle to zero */
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

	public void times_vector(Vector v)
	{
		Vector tmp = v;

		v.x = tmp.x * this.m11 + tmp.y * this.m12 + tmp.z * this.m13;
		v.y = tmp.x * this.m21 + tmp.y * this.m22 + tmp.z * this.m23;
		v.z = tmp.x * this.m31 + tmp.y * this.m32 + tmp.z * this.m33;
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

	public void solve(Vector x, Vector b)
	{
		double det = this.det();

		if (Math.fabs(det) > EPSILON) {
			x.x =   b.x * (this.m22*this.m33 - this.m23*this.m32);
			x.x += -b.y * (this.m12*this.m33 - this.m13*this.m32);
			x.x +=  b.z * (this.m12*this.m23 - this.m13*this.m22);

			x.y =  -b.x * (this.m21*this.m33 - this.m23*this.m31);
			x.y +=  b.y * (this.m11*this.m33 - this.m13*this.m31);
			x.y += -b.z * (this.m11*this.m23 - this.m13*this.m21);

			x.z =   b.x * (this.m21*this.m32 - this.m22*this.m31);
			x.z += -b.y * (this.m11*this.m32 - this.m12*this.m31);
			x.z +=  b.z * (this.m11*this.m22 - this.m12*this.m21);

			x.div_double(det);
		}
	}
}

public struct Hkl.Quaternion
{
	public double a;
	public double b;
	public double c;
	public double d;

	public void set(double a, double b, double c, double d)
	{
		this.a = a;
		this.b = b;
		this.c = c;
		this.d = d;
	}

	public void from_vector(Vector v)
	{
		this.a = 0;
		this.b = v.x; this.c = v.y; this.d = v.z;
	}

	public void from_angle_and_axe(double angle, Vector v)
	{
		double c = Math.cos(angle / 2.);
		double s = Math.sin(angle / 2.) / v.norm2();

		this.a = c;
		this.b = s * v.x;
		this.c = s * v.y;
		this.d = s * v.z;
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
	public void to_smatrix(Matrix m) requires (Math.fabs(this.norm2() - 1.) < EPSILON)
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
	public void to_angle_and_axe(out double angle, out Vector v) requires ( Math.fabs(this.norm2() - 1.) < EPSILON)
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
			angle -= 2. * Math.PI;

		// compute the axe
		sin_angle_2 = Math.sin(angle_2);
		if (Math.fabs(sin_angle_2) > EPSILON) {
			// compute the axe using the vector part of the unitary quaterninon
			v.x = this.b / sin_angle_2;
			v.y = this.c / sin_angle_2;
			v.z = this.d / sin_angle_2;
		} else {
			angle = 0.;
			v.x = v.y = v.z = 0.;
		}
	}
}
