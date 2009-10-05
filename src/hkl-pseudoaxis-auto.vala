/* as vala do not support delegates array for now lets do this */
public struct Hkl.PseudoAxisEngineAutoFunc
{
	public weak string name;
	public Gsl.MultirootFunction[] f;
	public string[] axes;
	public Parameter[] parameters;
}

public class Hkl.PseudoAxisEngineAuto : Hkl.PseudoAxisEngine
{
	public PseudoAxisEngineAuto(string name, string[] names)
	{
		base(name, names);
	}

	public bool solve_function(Gsl.MultirootFunction f)
	{
		int i;
		size_t len = this.axes.length;
		double[] x0 = new double[len];
		bool[] degenerated = new bool[len];
		int[] op_len = new int[len];
		bool res;
		Gsl.Vector _x; /* use to compute sectors in perm_r (avoid copy) */ 
		Gsl.Vector _f; /* use to test sectors in perm_r (avoid copy) */ 

		_x = new Gsl.Vector(len);
		_f = new Gsl.Vector(len);
		res = this.find_first_geometry(f, degenerated);
		if (res) {
			uint[] p = new uint[len];
			/* use first solution as starting point for permutations */
			for(i=0; i<len; ++i){
				x0[i] = this.axes[i].value;
				if (degenerated[i])
					op_len[i] = 1;
				else
					op_len[i] = 4;
			}
			for (i=0; i<op_len[0]; ++i)
				perm_r(op_len, p, 0, i, f, x0, _x, _f);
		}
		return res;
	}

	/** 
	 * @brief this private method try to find the first solution
	 * 
	 * @param self the current HklPseudoAxeEngine.
	 * @param f The function to use for the computation.
	 * 
	 * If a solution was found it also check for degenerated axes.
	 * A degenerated axes is an Axes with no effect on the function.
	 * @see find_degenerated
	 * @return HKL_SUCCESS (0) or HKL_FAIL (-1). 
	 */
	bool find_first_geometry(Gsl.MultirootFunction f,
			bool[] degenerated)
	{
		Gsl.MultirootFsolverType* T;
		Gsl.MultirootFsolver s;
		Gsl.Vector x;
		size_t len = this.axes.length;
		double *x_data;
		double[] x_data0 = new double[len];
		size_t iter = 0;
		int status = 0;
		bool res = false;
		size_t i;

		// get the starting point from the geometry
		// must be put in the auto_set method
		x = new Gsl.Vector(len);
		x_data = x.ptr(0);
		for(i=0; i<len; ++i)
			x_data[i] = this.axes[i].value;

		// keep a copy of the first axes positions to deal with degenerated axes
		GLib.Memory.copy(x_data0, x_data, len * sizeof(double));

		// Initialize method 
		T = (Gsl.MultirootFsolverType*)Gsl.MultirootFsolverTypes.hybrid;
		s = new Gsl.MultirootFsolver(T, len);
		s.set(&f, x);

		// iterate to find the solution
		do {
			++iter;
			status = s.iterate();
			if (status > 0 || iter % 1000 == 0) {
				// Restart from another point.
				for(i=0; i<len; ++i)
					x_data[i] = GLib.Random.double_range(0, GLib.Math.PI);
				s.set(&f, x);
				status = s.iterate();
			}
			status = Gsl.MultirootTest.residual(s.f, EPSILON);
		} while (status == Gsl.Status.CONTINUE && iter < 1000);

		if (status != Gsl.Status.CONTINUE) {		
			// this.find_degenerated_axes(f, s.x, s.f, degenerated);

			// set the geometry from the gsl_vector
			// in a futur version the geometry must contain a gsl_vector
			// to avoid this.
			x_data = s.x.ptr(0);
			for(i=0; i<len; ++i)
				if (degenerated[i])
					this.axes[i].set_value(x_data0[i]);
				else
					this.axes[i].set_value(x_data[i]);
			this.geometry.update();

			res = true;
		}
		return res;
	}

}

public static int RUBh_minus_Q(Gsl.Vector x, void *params, Gsl.Vector f)
{
	Hkl.Vector ki, dQ;
	Hkl.Vector Hkl = Hkl.Vector(0.0, 0.0, 0.0);

	Hkl.PseudoAxisEngineAuto *engine = params;
	weak Hkl.PseudoAxis H = engine->pseudoAxes[0];
	weak Hkl.PseudoAxis K = engine->pseudoAxes[1];
	weak Hkl.PseudoAxis L = engine->pseudoAxes[2];

	// update the axes from x;
	uint idx=0U;
	double *values = x.ptr(0);
	foreach(weak Hkl.Axis axis in engine->axes)
		axis.set_value(values[idx++]);
	engine->geometry.update();
	Hkl.set(H.value, K.value, L.value);

	// R * UB * h = Q
	// for now the 0 holder is the sample holder.
	weak Hkl.Holder holder = engine->geometry.holders[0];
	engine->sample.UB.times_vector(ref Hkl);
	Hkl.rotated_quaternion(holder.q);

	// kf - ki = Q
	engine->geometry.source.compute_ki(out ki);
	engine->detector.compute_kf(engine->geometry, out dQ);
	dQ.minus_vector(ki);


	dQ.minus_vector(Hkl);

	f.set(0, dQ.data[0]);
	f.set(1, dQ.data[1]);
	f.set(2, dQ.data[2]);

	return Gsl.Status.SUCCESS;
}

/** 
 * @brief given a vector of angles change the sector of thoses angles
 * 
 * @param x The vector of angles to change.
 * @param sector the sector vector operation.
 *
 * 0 -> no change
 * 1 -> pi - angle
 * 2 -> pi + angle
 * 3 -> -angle
 */
static void change_sector(double *x, double[] x0, uint[] sector)
{
	uint i;
	for(i=0U; i<sector.length; ++i) {
		double value = x0[i];
		switch (sector[i]) {
			case 0:
				break;
			case 1:
				value = Math.PI - value;
				break;
			case 2:
				value = Math.PI + value;
				break;
			case 3:
				value = -value;
				break;
		}
		x[i] = value;
	}
}

/** 
 * @brief Test if an angle combination is compatible with q function.
 * 
 * @param x The vector of angles to test.
 * @param function The gsl_multiroot_function used for the test.
 * @param f a gsl_vector use to compute the result (optimization)
 */
static bool test_sector(Gsl.Vector x,
		Gsl.MultirootFunction function,
		Gsl.Vector f)
{
	size_t i;
	double *f_data = f.ptr(0);

	function.f(x, function.params, f);

	for(i=0; i<f.size; ++i)
		if (Math.fabs(f_data[i]) > Hkl.EPSILON)
			return false;

	return true;
}

static void perm_r(int[] op_len, uint[] p, int axes_idx,
		int op, Gsl.MultirootFunction f, double[] x0,
		Gsl.Vector _x, Gsl.Vector _f)
{
	int i;
	double *x_data = _x.ptr(0);
	Hkl.PseudoAxisEngine *engine = f.params;

	p[axes_idx++] = op;
	if (axes_idx == p.length) {
		change_sector(x_data, x0, p);
		if (test_sector(_x, f, _f))
			engine->add_geometry(_x);
	} else
		for (i=0; i<op_len[axes_idx]; ++i)
			perm_r(op_len, p, axes_idx, i, f, x0, _x, _f);
}
