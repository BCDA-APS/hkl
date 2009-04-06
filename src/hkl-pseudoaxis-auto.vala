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
	public Gsl.MultirootFsolver solver;
	public Gsl.Vector x;
	public weak PseudoAxisEngineAutoFunc function;
	public PseudoAxisEngineAutoFunc[] functions;

	public PseudoAxisEngineAuto(string name, string[] names, Geometry g)
	{
		base.init(name, names, g);
	}

	/* waiting for vala to let me declare a constructor outside */
	public PseudoAxisEngineAuto.HKL_E4CV(Geometry g)
	{
		string[] pseudo_names = {"h", "k", "l"};
		base.init("hkl", pseudo_names, g);
		this.functions = new PseudoAxisEngineAutoFunc[4];
		this.functions[0] = E4CV_bissector_func(this);
		this.functions[1] = E4CV_constant_omega_func(this);
		this.functions[2] = E4CV_constant_chi_func(this);
		this.functions[3] = E4CV_constant_phi_func(this);
	}

	public override bool set_by_name(string name, Detector det, Sample sample)
	{
		uint idx=0U;
		foreach(weak PseudoAxisEngineAutoFunc func in this.functions) {
			if (func.name == name)
				return this.set(idx, det, sample);
			idx++;
		}
		return false;
	}

	public override bool set(uint idx, Detector det, Sample sample) requires (idx < this.functions.length)
	{
		this.detector = det;
		this.sample = sample;

		this.function = this.functions[idx];
		this.axes = new Axis[this.function.axes.length];
		uint i=0U;
		foreach(weak string s in this.function.axes)
			this.axes[i++] = this.geometry.get_axis_by_name(s);
		this.solver = new Gsl.MultirootFsolver(Gsl.MultirootFsolverTypes.hybrids, this.function.axes.length);
		this.x = new Gsl.Vector(this.function.axes.length);
		return true;
	}

	public override bool compute_geometries()
	{
		//first clear the geometries.
		this.geometries.clear();
		bool res = false;
		foreach(weak Gsl.MultirootFunction f in this.function.f) {
			res |= this.solve(f);
			this.compute_equivalent_geometries(f);
		}
		return res;
	}

	public override bool compute_pseudoAxes(Geometry geom)
	{
		Matrix RUB;
		Vector hkl, ki, Q;

		// update the geometry internals
		geom.update();

		// R * UB
		// for now the 0 holder is the sample holder.
		weak Holder holder = geom.holders[0];
		holder.q.to_matrix(out RUB);
		RUB.times_matrix(this.sample.UB);

		// kf - ki = Q
		geom.source.compute_ki(out ki);
		this.detector.compute_kf(geom, out Q);
		Q.minus_vector(ki);
		RUB.solve(out hkl, Q);

		// update the pseudoAxes current and consign parts
		this.pseudoAxes[0].config.value = hkl.x;
		this.pseudoAxes[1].config.value = hkl.y;
		this.pseudoAxes[2].config.value = hkl.z;

		return true;
	}

	bool solve(Gsl.MultirootFunction f)
	{
		int status = 0;
		weak Gsl.MultirootFsolver solver = this.solver;
		double *x = this.x.ptr(0);

		// get the starting point from the geometry
		// must be put in the auto_set method
		uint idx=0U;
		foreach(weak Axis axis in this.axes)
			x[idx++] = axis.config.value;

		// Initialize method 
		solver.set(&f, this.x);

		// iterate to find the solution
		uint iter = 0U;
		do {
			++iter;
			status = solver.iterate();
			if (status != 0 || iter % 1000 == 0) {
				// Restart from another point.
				for(idx=0U; idx<this.axes.length; ++idx)
					x[idx] = Random.double_range(0.0, Math.PI);
				solver.set(&f, this.x);
				status = solver.iterate();
			}
			status = Gsl.MultirootTest.residual (solver.f, EPSILON);
		} while (status == Gsl.Status.CONTINUE && iter < 1000);
		if (status == Gsl.Status.CONTINUE){
			return false;
		}

		// set the geometry from the gsl_vector
		// in a futur version the geometry must contain a gsl_vector
		// to avoid this.
		idx = 0U;
		x = solver.x.ptr(0);
		foreach(weak Axis axis in this.axes) {
			AxisConfig config;
			axis.get_config(out config);
			config.value = Gsl.Trig.angle_restrict_pos(x[idx++]);
			axis.set_config(config);
		}
		this.x.memcpy(solver.x);
		this.geometry.update();

		return true;
	}

	bool compute_equivalent_geometries(Gsl.MultirootFunction f)
	{
		uint n = this.axes.length;
		var perm = new uint[n];
		var geom = new Gsl.Vector(n);
		geom.memcpy(this.x);
		for (uint i=0U; i<n; ++i)
			perm_r(n, 4, perm, 0, i, f, geom);
		return true;
	}

}

public static int RUBh_minus_Q(Gsl.Vector x, void *params, Gsl.Vector f)
{
	Hkl.Vector ki, dQ;
	Hkl.Vector Hkl = {0.0, 0.0, 0.0};

	Hkl.PseudoAxisEngineAuto *engine = params;
	weak Hkl.PseudoAxis H = engine->pseudoAxes[0];
	weak Hkl.PseudoAxis K = engine->pseudoAxes[1];
	weak Hkl.PseudoAxis L = engine->pseudoAxes[2];

	// update the axes from x;
	uint idx=0U;
	double *values = x.ptr(0);
	foreach(weak Hkl.Axis axis in engine->axes) {
		Hkl.AxisConfig config;
		axis.get_config(out config);
		config.value = values[idx++];
		axis.set_config(config);
	}
	engine->geometry.update();
	Hkl.set(H.config.value, K.config.value, L.config.value);

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

	f.set(0, dQ.x);
	f.set(1, dQ.y);
	f.set(2, dQ.z);

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
static void change_sector(double *x, uint[] sector)
{
	uint i;
	for(i=0U; i<sector.length; ++i) {
		double value;

		value = x[i];
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
 * @brief Test if an angle combination is compatible with a
 * pseudoAxisEngine
 * 
 * @param x The vector of angles to test.
 * @param engine The pseudoAxeEngine used for the test.
 */
static void test_sector(Gsl.Vector x, Gsl.MultirootFunction func)
{
	uint i;

	var F = new Gsl.Vector(x.size);
	double *f = F.ptr(0);

	func.f(x, func.params, F);
	bool ko = false;
	for(i=0;i<x.size; ++i) {
		if (Math.fabs(f[i]) > Hkl.EPSILON) {
			ko = true;
			break;
		}
	}
	if (!ko) {
		Hkl.PseudoAxisEngine *engine = func.params;
		engine->geometries.add(new Hkl.Geometry.copy(engine->geometry));
		/*
		   var J = new Gsl.Matrix(x.size, f.size);
		   Gsl.multiroot_fdjacobian(&function.f, x, f,
		   Hkl.SQRT_DBL_EPSILON, J);
		 */
		/*	
			fprintf(stdout, "\n");
			hkl_geometry_fprintf(stdout, engine->geom);
			fprintf(stdout, "\n ");
			for(i=0;i<x->size;++i)
			fprintf(stdout, " %d", gsl_vector_int_get(p, i));
			fprintf(stdout, "   ");
			for(i=0;i<x->size;++i)
			fprintf(stdout, " %f", gsl_vector_get(f, i));
			fprintf(stdout, "\n");
			for(i=0;i<state->n;++i) {
			fprintf(stdout, "\n   ");
			for(j=0;j<state->n;++j)
			fprintf(stdout, " %f", gsl_matrix_get(J, i, j));
			}
			fprintf(stdout, "\n");
		 */
	}
}

/* 
 * @brief compute the permutation and test its validity.
 * 
 * @param n number of axes
 * @param k number of operation per axes. (4 for now)
 * @param p The vector containing the current permutation.
 * @param z The index of the axes we are permution.
 * @param x the current operation to set.
 * @param engine The engine for the validity test.
 * @param geom The starting point of all geometry permutations.
 */
static void perm_r(uint n, int k,
		uint[] p, int z, uint x,
		Gsl.MultirootFunction f, Gsl.Vector geom)
{
	uint i;

	p[z++] = x;
	if (z == k) {
		Hkl.PseudoAxisEngineAuto *engine = f.params;
		engine->x.memcpy(geom);
		change_sector(engine->x.ptr(0), p);
		test_sector(engine->x, f);
	} else
		for (i=0; i<n; ++i)
			perm_r(n, k, p, z, i, f, geom);
}
