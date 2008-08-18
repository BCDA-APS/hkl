using Gsl;

public class Hkl.Sample {
	public weak string name;
	public Lattice lattice;
	public Matrix U;
	public Matrix UB;
	public List<Reflection> reflections;

	public class Reflection {
		public Geometry geometry;
		public Detector detector;
		public Vector hkl;
		public Vector _hkl;

		public Reflection(Geometry g, Detector det,
				double h, double k, double l)
		{
			Vector ki;

			g.update();

			this.geometry = new Geometry.copy(g);
			this.detector = det;
			this.hkl.x = h;
			this.hkl.y = k;
			this.hkl.z = l;

			// compute the _hkl using only the axes of the geometry
			weak Holder holder_d = g.holders[det.idx];
			weak Holder holder_s = g.holders[0];

			// compute Q from angles
			g.source.compute_ki(ki);
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
			this.detector = src.detector;
			this.hkl = src.hkl;
			this._hkl = src._hkl;
		}
	}

	/* private */

	/* return true if the calculation can not be acheave */
	bool compute_UB()
	{
		Matrix B;

		if (!this.lattice.compute_B(B))
			return false;

		this.UB = this.U;
		this.UB.times_matrix(B);

		return true;
	}

	static double mono_crystal_fitness(Gsl.Vector x, void *params)
	{
		uint i;
		Sample *sample = params;

		double euler_x = x.get(0);
		double euler_y = x.get(1);
		double euler_z = x.get(2);
		sample->lattice.a.value = x.get(3);
		sample->lattice.b.value = x.get(4);
		sample->lattice.c.value = x.get(5);
		sample->lattice.alpha.value = x.get(6);
		sample->lattice.beta.value = x.get(7);
		sample->lattice.gamma.value = x.get(8);
		sample->U.from_euler(euler_x, euler_y, euler_z);
		if (!sample->compute_UB())
			return double.NAN;

		double fitness = 0.;
		for(i=0U; i<sample->reflections.length; ++i) {
			weak Reflection reflection = sample->reflections.get(i);
			Vector UBh = reflection.hkl;
			sample->UB.times_vector(UBh);

			double tmp = UBh.x - reflection._hkl.x;
			fitness += tmp * tmp;

			tmp = UBh.y - reflection._hkl.y;
			fitness += tmp * tmp;

			tmp = UBh.z - reflection._hkl.z;
			fitness += tmp * tmp;
		}
		return fitness;
	}

	/* public */

	public Sample(string name)
	{
		this.name = name;
		this.lattice = Lattice.default();
		this.U.set(1., 0., 0., 0., 1., 0., 0., 0., 1.);
		this.UB.set(1., 0., 0., 0., 1., 0., 0., 0., 1.);
		this.compute_UB();
		this.reflections = new List<Reflection>();
	}

	public Sample.copy(Sample src)
	{
		uint i;

		this.name = src.name;
		this.lattice = src.lattice;
		this.U = src.U;
		this.UB = src.UB;
		/* make a deep copy of the reflections */
		this.reflections = new List<Reflection>();
		for(i=0; i<src.reflections.length; ++i) {
			weak Reflection reflection = src.reflections.get(i);
			reflection = this.reflections.add(new Reflection.copy(reflection));
		}
	}

	public weak Reflection? add_reflection(Geometry g, Detector det,
			double h, double k, double l)
	{
		if (Math.fabs(h) < EPSILON
			&& Math.fabs(k) < EPSILON
			&& Math.fabs(l) < EPSILON)
			return null;
		else
			return this.reflections.add(new Reflection(g, det, h, k, l));
	}

	public weak Reflection get_reflection(uint idx)
	{
		return this.reflections.get(idx);
	}

	public bool del_reflection(uint idx)
	{
		return this.reflections.del(idx);
	}

	public bool compute_UB_busing_levy(uint idx1, uint idx2)
	{
		if (idx1 < this.reflections.length 
				&& idx2 < this.reflections.length) {

			weak Reflection r1 = this.reflections.get(idx1);
			weak Reflection r2 = this.reflections.get(idx2);

			if (!r1.hkl.is_colinear(r2.hkl)) {
				Vector h1c = r1.hkl;
				Vector h2c = r2.hkl;
				Matrix B;
				Matrix Tc;

				// Compute matrix Tc from r1 and r2.
				this.lattice.compute_B(B);
				B.times_vector(h1c);
				B.times_vector(h2c);
				Tc.from_two_vector(h1c, h2c);
				Tc.transpose();

				// compute U
				this.U.from_two_vector(r1._hkl, r2._hkl);
				this.U.times_matrix(Tc);
			} else
				return true;
		} else
			return true;

		return false;
	}

	public void affine()
	{
		int status;

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
		ss.set(3, (double)this.lattice.a.to_fit);
		ss.set(4, (double)this.lattice.b.to_fit);
		ss.set(5, (double)this.lattice.c.to_fit);
		ss.set(6, (double)this.lattice.alpha.to_fit);
		ss.set(7, (double)this.lattice.beta.to_fit);
		ss.set(8, (double)this.lattice.gamma.to_fit);

		// Initialize method and iterate
		Gsl.Error.set_error_handler_off();
		Gsl.MultiminFunction minex_func;
		minex_func.n = 9;
		minex_func.f = mono_crystal_fitness;
		minex_func.params = this;
		var s = new Gsl.MultiminFminimizer(Gsl.MultiminFminimizerTypes.nmsimplex, 9);
		s.set(&minex_func, x, ss);
		uint iter = 0;
		do {
			++iter;
			status = s.iterate();
			if (status != 0)
				break;
			status = Gsl.MultiminTest.size(s.size, EPSILON / 2.);
		} while (status == Gsl.Status.CONTINUE && iter < 10000U);
		Gsl.Error.set_error_handler(null);
	}

}

