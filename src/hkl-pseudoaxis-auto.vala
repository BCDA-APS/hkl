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

/*******************************************/
/* Class use to solve numerical pseudoAxes */
/*******************************************/

public class Hkl.PseudoAxisEngineAuto : Hkl.PseudoAxisEngine
{
	public PseudoAxisEngineAuto(string name)
	{
		base(name);
	}

	public delegate int Function(Gsl.Vector x, void* params, Gsl.Vector f);

/** 
 * @brief Find all numerical solutions of a mode.
 * 
 * @param self the current HklPseudoAxisEngine
 * @param function The mode function
 * 
 * @return HKL_SUCCESS (0) or HKL_FAIL (-1)
 *
 * This method find a first solution with a numerical method from the
 * GSL library (the multi root solver hybrid). Then it multiplicates the
 * solutions from this starting point using cosinus/sinus properties.
 * It addes all valid solutions to the self->geometries.
 */
	public bool solve_function(Gsl.MultirootFunction f)
	{

		int i;
		int len = this.axes.length;
		double[] x0 = new double[len];
		bool[] degenerated = new bool[len];
		int[] op_len = new int[len];
		bool res;
		Gsl.Vector _x = new Gsl.Vector(len);/* use to compute sectors in perm_r (avoid copy) */
		Gsl.Vector _f = new Gsl.Vector(len);/* use to test sectors in perm_r (avoid copy) */
//		Gsl.MultirootFunction f = {(Gsl.MultirootF)function, len, this};

		res = this.find_first_geometry(ref f, degenerated);
		if (!res) {
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
	bool find_first_geometry(ref Gsl.MultirootFunction f,
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
		bool res = true;
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
			this.find_degenerated_axes(ref f, s.x, s.f, degenerated);

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

			res = false;
		}
		return res;
	}

/** 
 * @brief This private method find the degenerated axes.
 * 
 * @param func the gsl_multiroopt_function to test
 * @param x the starting point
 * @param f the result of the function evaluation.
 *
 * with this method we can see if an axis is degenerated or not.
 * A degenerated axis is an axis with no effect on the function evaluation.
 * In the Jacobian matrix all elements of a columnn is null.
 * Once we know this the axis is mark as degenerated and we do not need to
 * change is sector.
 */
	void find_degenerated_axes(ref Gsl.MultirootFunction func,
							   Gsl.Vector x, Gsl.Vector f,
							   bool[] degenerated)
	{
		size_t i, j;
		Gsl.Matrix J = new Gsl.Matrix(x.size, f.size);

		Gsl.multiroot_fdjacobian(&func, x, f, 1.4901161193847656e-08, J);
		for(j=0; j<x.size && !degenerated[j]; ++j) {
			for(i=0; i<f.size; ++i)
				if (Math.fabs(J.get(i, j)) > EPSILON)
					break;
			if (i == f.size)
				degenerated[j] = true;
		}

		/*
		  hkl_pseudoAxisEngine_fprintf(func->params, stdout);
		  fprintf(stdout, "\n");
		  for(i=0; i<x->size; ++i)
		  fprintf(stdout, " %d", degenerated[i]);
		  for(i=0;i<x->size;++i) {
		  fprintf(stdout, "\n   ");
		  for(j=0;j<f->size;++j)
		  fprintf(stdout, " %f", gsl_matrix_get(J, i, j));
		  }
		  fprintf(stdout, "\n");
		*/
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
	bool test_sector(Gsl.Vector x,
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

/** 
 * @brief compute the permutation and test its validity.
 * 
 * @param axes_len number of axes
 * @param op_len number of operation per axes. (4 for now)
 * @param p The vector containing the current permutation.
 * @param axes_idx The index of the axes we are permution.
 * @param op the current operation to set.
 * @param f The function for the validity test.
 * @param x0 The starting point of all geometry permutations.
 * @param _x a gsl_vector use to compute the sectors (optimization) 
 * @param _f a gsl_vector use during the sector test (optimization) 
 */
	void perm_r(int[] op_len, uint[] p, int axes_idx,
				int op, Gsl.MultirootFunction f, double[] x0,
				Gsl.Vector _x, Gsl.Vector _f)
	{
		int i;
		double *x_data = _x.ptr(0);
		Hkl.PseudoAxisEngine *engine = f.params;
		
		p[axes_idx++] = op;
		if (axes_idx == p.length) {
			this.change_sector(x_data, x0, p);
			if (this.test_sector(_x, f, _f))
				engine->add_geometry(_x);
		} else
			for (i=0; i<op_len[axes_idx]; ++i)
				perm_r(op_len, p, axes_idx, i, f, x0, _x, _f);
	}

}