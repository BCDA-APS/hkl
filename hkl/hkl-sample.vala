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
using Gsl;

public class Hkl.Sample {
	public string name;
	public Lattice lattice;
	public Matrix U;
	public Matrix UB;
	public Reflection[] reflections;

	public class Reflection {
		public Geometry geometry;
		public Detector detector;
		public Vector hkl;
		public Vector _hkl;
		public bool flag;

		public Reflection(Geometry g, Detector det, double h, double k, double l)
		{
			Vector ki;

			g.update();

			this.geometry = new Geometry.copy(g);
			this.detector = det;
			this.hkl.set(h, k, l);
			this.flag = true;

			// compute the _hkl using only the axes of the geometry
			weak Holder holder_d = g.holders[det.idx];
			weak Holder holder_s = g.holders[0];

			// compute Q from angles
			g.source.compute_ki(out ki);
			this._hkl = ki;
			this._hkl.rotated_quaternion(holder_d.q);
			this._hkl.minus_vector(ki);

			Quaternion q = holder_s.q;
			q.conjugate();
			this._hkl.rotated_quaternion(q);
		}

		public Reflection.copy(Reflection src)
		{
			this.geometry = new Geometry.copy(src.geometry);
			this.detector = new Detector.copy(src.detector);
			this.hkl = src.hkl;
			this._hkl = src._hkl;
			this.flag = src.flag;
		}

		public void set_hkl(double h, double k, double l) requires (Math.fabs(h) + Math.fabs(k) + Math.fabs(l) > EPSILON)
		{
			this.hkl.set(h, k, l);
		}

		public void set_flag(bool flag)
		{
			this.flag = flag;
		}
	}

	/* private */

	/* return true if the calculation can not be acheave */
	bool compute_UB()
	{
		Matrix B;

		if (this.lattice.get_B(out B))
			return true;

		this.UB = this.U;
		this.UB.times_matrix(B);

		return false;
	}

	static double mono_crystal_fitness([Immutable] Gsl.Vector x, void *params)
	{
		Sample *sample = params;
		double *x_data = x.data;

		double euler_x = x_data[0];
		double euler_y = x_data[1];
		double euler_z = x_data[2];
		sample->lattice.a.value = x_data[3];
		sample->lattice.b.value = x_data[4];
		sample->lattice.c.value = x_data[5];
		sample->lattice.alpha.value = x_data[6];
		sample->lattice.beta.value = x_data[7];
		sample->lattice.gamma.value = x_data[8];
		sample->U.set_from_eulers(euler_x, euler_y, euler_z);

		if (sample->compute_UB())
			return double.NAN;

		double fitness = 0.0;
		foreach(weak Reflection reflection in sample->reflections){
			Vector UBh = reflection.hkl;
			sample->UB.times_vector(ref UBh);
			UBh.minus_vector(reflection._hkl);
			fitness += UBh.x * UBh.x + UBh.y * UBh.y + UBh.z * UBh.z;
		}
		return fitness;
	}

	/* public */

	public Sample(string name)
	{
		this.name = name;
		this.lattice = new Lattice.default();
		this.U.set(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
		this.UB.set(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
		this.compute_UB();
	}

	public Sample.copy(Sample src)
	{
		uint i;

		this.name = src.name;
		this.lattice = src.lattice;
		this.U = src.U;
		this.UB = src.UB;
		/* make a deep copy of the reflections */
		this.reflections = new Reflection[src.reflections.length];
		i=0;
		foreach(weak Reflection reflection in src.reflections){
			this.reflections[i++] = new Reflection.copy(reflection);
		}
	}

	public void set_name(string name)
		{
			this.name = name;
		}

	public bool set_lattice(double a, double b, double c,
				double alpha, double beta, double gamma)
	{
		bool status;
		
		status = this.lattice.set(a, b, c, alpha, beta, gamma);
		if (status)
			this.compute_UB();
		return status;
	}

	/* TODO test */
	public bool set_U_from_eulers(double x, double y, double z)
	{
		this.U.set_from_eulers(x, y, z);
		this.compute_UB();

		return true;
	}

	public void hkl_sample_get_UB(out Matrix UB)
	{
		this.compute_UB();
		UB = this.UB;
	}


	public weak Reflection? add_reflection(Geometry g, Detector det,
					       double h, double k, double l) requires (
						       Math.fabs(h) >= EPSILON
						       || Math.fabs(k) >= EPSILON
						       || Math.fabs(l) >= EPSILON)
	{
		int len = this.reflections.length;
		this.reflections.resize(len + 1);
		this.reflections[len] = new Reflection(g, det, h, k, l);
		return this.reflections[len];
	}

	public weak Reflection? get_ith_reflection(uint idx)
	{
		return this.reflections[idx];
	}

	public bool del_reflection(int idx)
	{
		this.reflections.move(idx+1, idx, this.reflections.length - idx - 1);
		this.reflections.resize(this.reflections.length - 1);
		return false;
	}

	public bool compute_UB_busing_levy(uint idx1, uint idx2)
	{
		if (idx1 < this.reflections.length 
				&& idx2 < this.reflections.length) {

			weak Reflection r1 = this.reflections[idx1];
			weak Reflection r2 = this.reflections[idx2];

			if (!r1.hkl.is_colinear(r2.hkl)) {
				Vector h1c = r1.hkl;
				Vector h2c = r2.hkl;
				Matrix B;
				Matrix Tc = {0};

				// Compute matrix Tc from r1 and r2.
				this.lattice.get_B(out B);
				B.times_vector(ref h1c);
				B.times_vector(ref h2c);
				Tc.set_from_two_vectors(h1c, h2c);
				Tc.transpose();

				// compute U
				this.U.set_from_two_vectors(r1._hkl, r2._hkl);
				this.U.times_matrix(Tc);
			} else
				return true;
		} else
			return true;

		return false;
	}

	public double affine()
	{
		int status = 0;

		// Starting point
		var x = new Gsl.Vector(9);
		x.set(0, 10 * DEGTORAD);
		x.set(1, 10 * DEGTORAD);
		x.set(2, 10 * DEGTORAD);
		x.set(3, this.lattice.a.value);
		x.set(4, this.lattice.b.value);
		x.set(5, this.lattice.c.value);
		x.set(6, this.lattice.alpha.value);
		x.set(7, this.lattice.beta.value);
		x.set(8, this.lattice.gamma.value);

		// Set initial step sizes to 1
		var ss = new Gsl.Vector(9);
		ss.set(0, 1 * DEGTORAD);
		ss.set(1, 1 * DEGTORAD);
		ss.set(2, 1 * DEGTORAD);
		ss.set(3, (double)!this.lattice.a.not_to_fit);
		ss.set(4, (double)!this.lattice.b.not_to_fit);
		ss.set(5, (double)!this.lattice.c.not_to_fit);
		ss.set(6, (double)!this.lattice.alpha.not_to_fit);
		ss.set(7, (double)!this.lattice.beta.not_to_fit);
		ss.set(8, (double)!this.lattice.gamma.not_to_fit);

		// Initialize method and iterate
		Gsl.Error.set_error_handler_off();
		Gsl.MultiminFunction minex_func = {mono_crystal_fitness, 9, this};
		var s = new Gsl.MultiminFminimizer(Gsl.MultiminFminimizerTypes.nmsimplex, 9);
		s.set(&minex_func, x, ss);
		uint iter = 0;
		do {
			++iter;
			status = s.iterate();
			if (status != 0)
				break;
			status = Gsl.MultiminTest.size(s.size, EPSILON / 2.0);
		} while (status == Gsl.Status.CONTINUE && iter < 10000U);
		Gsl.Error.set_error_handler(null);

		return s.size;
	}

	public double get_reflection_mesured_angle(int idx1, int idx2)
	{
		if (idx1 > this.reflections.length
		    || idx2 > this.reflections.length)
			return double.NAN;
		
		return this.reflections[idx1]._hkl.angle(this.reflections[idx2]._hkl);
	}

	public double get_reflection_theoretical_angle(int idx1, int idx2)
	{
		if (idx1 > this.reflections.length
		    || idx2 > this.reflections.length)
			return double.NAN;

		Vector hkl1;
		Vector hkl2;

		hkl1 = this.reflections[idx1].hkl;
		hkl2 = this.reflections[idx2].hkl;
		this.UB.times_vector(ref hkl1);
		this.UB.times_vector(ref hkl2);

		return hkl1.angle(hkl2);
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
		{
			f.printf("\nSample name: \"%s\"", this.name);

			f.printf("\nLattice parameters:");
			f.printf("\n ");
			this.lattice.a.fprintf(f);
			f.printf("\n ");
			this.lattice.b.fprintf(f);
			f.printf("\n ");
			this.lattice.c.fprintf(f);
			f.printf("\n ");
			this.lattice.alpha.fprintf(f);
			f.printf("\n ");
			this.lattice.beta.fprintf(f);
			f.printf("\n ");
			this.lattice.gamma.fprintf(f);
			f.printf("\nUB:\n");
			this.UB.fprintf(f);

			if(this.reflections.length > 0){
				f.printf("Reflections:");
				f.printf("\n");
				f.printf("i %-10.6s %-10.6s %-10.6s", "h", "k", "l");
				foreach(weak Axis axis in this.reflections[0].geometry.axes){
					f.printf(" %-10.6s", axis.name);
				}
				int i=0;
				foreach(weak Reflection reflection in this.reflections){
					f.printf("\n%d %-10.6f %-10.6f %-10.6f", i++, 
							 reflection.hkl.x, reflection.hkl.y, reflection.hkl.z);
					foreach(weak Axis axis in reflection.geometry.axes){
						f.printf(" %-10.6f", axis.get_value_unit());
					}
				}
			}
		}
}

public class Hkl.SampleList
{
	public Sample[] samples;
	weak Sample? current;

	public SampleList()
	{
		this.current = null;
	}

	public void clear()
		{
			this.samples.resize(0);
			this.current = null;
		}

	public int len()
		{
			return this.samples.length;
		}

	public Sample? append(Sample sample)
	{
		if (this.get_idx_from_name(sample.name) >= 0)
			return null;

		int len = this.samples.length;
		this.samples.resize(len + 1);
		this.samples[len] = sample;

		return sample;
	}

	public int get_idx_from_name(string name)
	{
		int i=0;
		foreach(weak Sample sample in this.samples){
			if (name == sample.name)
				return i;
			i++;
		}
		return -1;
	}

	public void del(Sample sample)
		{
			if (this.current == sample)
				this.current = null;
			Sample[] samples = new Sample[this.samples.length - 1];

			uint idx=0u;
			foreach(Sample sample_it in this.samples){
				if (sample_it == sample)
					idx + 1;
				else{
					samples[idx] = sample_it;
				}
			}
		}

	/* TODO test */
	public Sample get_ith(uint idx) requires (idx < this.samples.length)
		{
			return this.samples[idx];
		}

	/* TODO test */
	public Sample? get_by_name(string name)
		{
			int idx = this.get_idx_from_name(name);
			if (idx >= 0)
				return this.samples[idx];
			return null;
		}

	public int select_current(string name)
		{
			int	idx = this.get_idx_from_name(name);
			if (idx >= 0)
				this.current = this.samples[idx];

			return idx;
	}

	[CCode (instance_pos=-1)]
	public void fprintf(FileStream f)
		{
			foreach(weak Sample sample in this.samples){
				sample.fprintf(f);
			}
		}
}
