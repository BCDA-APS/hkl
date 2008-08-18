public class Hkl.PseudoAxisEngineAuto : Hkl.PseudoAxisEngine
{
	Gsl.MultirootFsolver solver;
	Gsl.Vector x;

	public PseudoAxisEngineAuto(string name, string[] names, Geometry g)
	{
		base.init(name, names, g);
	}

	public override bool set(PseudoAxisEngineFunc f, Detector det,
			Sample sample)
	{
		bool res = base.set(f, det, sample);
		this.solver = new Gsl.MultirootFsolver(Gsl.MultirootFsolverTypes.hybrids, f.axes.length);
		this.x = new Gsl.Vector(f.axes.length);
		return res;
	}

	public override bool compute_geometries()
	{
		//first clear the geometries.
		this.geometries.clear();
		bool res = false;
		foreach(weak Gsl.MultirootFunction f in this.function.f) {
			res |= this.solve(f);
			this.geometries.add(new Geometry.copy(this.geometry));
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
		holder.q.to_matrix(RUB);
		RUB.times_matrix(this.sample.UB);

		// kf - ki = Q
		geom.source.compute_ki(ki);
		this.detector.compute_kf(geom, Q);
		Q.minus_vector(ki);
		RUB.solve(hkl, Q);

		// update the pseudoAxes current and consign parts
		this.pseudoAxes[0].config.value = hkl.x;
		this.pseudoAxes[1].config.value = hkl.y;
		this.pseudoAxes[2].config.value = hkl.z;

		return true;
	}

	bool solve(Gsl.MultirootFunction f)
	{
		int status;
		uint i;
		uint  idx;
		double d;
		weak Gsl.MultirootFsolver solver = this.solver;
		weak Gsl.Vector x = this.x;

		// get the starting point from the geometry
		// must be put in the auto_set method
		uint n = this.related_axes_idx.length;
		for(i=0U; i<n; ++i) {
			weak Axis axis = this.geometry.get_axis(this.related_axes_idx[i]);
			x.set(i, axis.config.value);
		}

		// Initialize method 
		solver.set(&f, x);

		// iterate to find the solution
		uint iter = 0U;
		do {
			++iter;
			status = solver.iterate();
			if (status != 0 || iter % 1000 == 0) {
				// Restart from another point.
				for(i=0U; i<n; ++i) {
					d = Random.double_range(0., Math.PI);
					x.set(i, d);
				}
				solver.set(&f, x);
				status = solver.iterate();
			}
			status = Gsl.MultirootTest.residual (solver.f, EPSILON);
		} while (status == Gsl.Status.CONTINUE && iter < 10000);
		if (status == Gsl.Status.CONTINUE){
			stdout.printf("toto %u\n", iter);
			return (bool)Gsl.Status.ENOMEM;
		}

		// set the geometry from the gsl_vector
		// in a futur version the geometry must contain a gsl_vector
		// to avoid this.
		for(i=0; i<n; ++i) {
			AxisConfig config = {{0., 0.}, 0., false};
			weak Axis axis = this.geometry.get_axis(this.related_axes_idx[i]);
			axis.get_config(config);
			config.value = Gsl.Trig.angle_restrict_pos(solver.x.get(i));
			axis.set_config(config);
		}
		this.geometry.update();

		return true;
	}

	bool compute_equivalent_geometries(Gsl.MultirootFunction f)
	{
		uint i, j;

		uint n = this.related_axes_idx.length;
		uint p = this.geometries.length;
		for(i=0U; i<p; ++i) { 
			weak Geometry geom = this.geometries.get(i);

			var perm = new uint[n];
			for (j=0U; i<n; ++i)
				perm_r(n, 4, perm, 0, j, f, geom);
		}
		return true;
	}

}

public static int RUBh_minus_Q(Gsl.Vector x, void *params, Gsl.Vector f)
{
	Hkl.Vector Hkl, ki, dQ;
	uint i;

	Hkl.PseudoAxisEngineAuto *engine = params;
	weak Hkl.PseudoAxis H = engine->pseudoAxes[0];
	weak Hkl.PseudoAxis K = engine->pseudoAxes[1];
	weak Hkl.PseudoAxis L = engine->pseudoAxes[2];

	// update the workspace from x;
	for(i=0; i<engine->related_axes_idx.length ; ++i) {
		Hkl.AxisConfig config = {{0., 0.}, 0., false};

		uint idx = engine->related_axes_idx[i];
		weak Hkl.Axis axis = engine->geometry.get_axis(idx);
		axis.get_config(config);
		config.value = x.get(i);
		axis.set_config(config);
	}
	engine->geometry.update();
	Hkl.set(H.config.value, K.config.value, L.config.value);

	// R * UB * h = Q
	// for now the 0 holder is the sample holder.
	weak Hkl.Holder holder = engine->geometry.holders[0];
	engine->sample.UB.times_vector(Hkl);
	Hkl.rotated_quaternion(holder.q);

	// kf - ki = Q
	engine->geometry.source.compute_ki(ki);
	engine->detector.compute_kf(engine->geometry, dQ);
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
static void change_sector(Gsl.Vector x, uint[] sector)
{
	uint i;

	for(i=0U; i<x.size; ++i) {
		double value;

		value = x.get(i);
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
		x.set(i, value);
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

	var f = new Gsl.Vector(x.size);

	func.f(x, func.params, f);
	bool ko = false;
	for(i=0;i<f.size; ++i) {
		if (Math.fabs(f.get(i)) > Hkl.EPSILON) {
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
 * @brief given a ref geometry populate a vector for a specific engine.
 * 
 * @param x The vector to populate with the right axes values.
 * @param engine The engine use to take the right axes from geom.
 * @param geom The geom use to extract the angles into x.
 */
static void get_axes_as_gsl_vector(Gsl.Vector x,
		Hkl.PseudoAxisEngine *engine, Hkl.Geometry geom)
{
	uint i;

	for(i=0; i<x.size; ++i) {
		weak Hkl.Axis axis = geom.get_axis(engine->related_axes_idx[i]);
		x.set(i, axis.config.value);
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
		Gsl.MultirootFunction f, Hkl.Geometry geom)
{
	uint i;

	p[z++] = x;
	if (z == k) {
		var x = new Gsl.Vector(n);

		get_axes_as_gsl_vector(x, f.params, geom);
		change_sector(x, p);
		test_sector(x, f);
	} else
		for (i=0; i<n; ++i)
			perm_r(n, k, p, z, i, f, geom);
}
