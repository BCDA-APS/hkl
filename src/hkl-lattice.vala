/*
public static Hkl.Lattice default = {
		{"a", {0.0, 11.54}, 1.54, 11.54, false},
		{"b", {0.0, 11.54}, 1.54, 11.54, false},
		{"c", {0.0, 11.54}, 1.54, 11.54, false},
		{"alpha", {-Math.PI, Math.PI}, 90*DEGTORAD, false},
		{"beta", {-Math.PI, Math.PI}, 90*DEGTORAD, false},
		{"gamma", {-Math.PI, Math.PI}, 90*DEGTORAD, false}
}; 
*/

public struct Hkl.Lattice
{
	public Parameter a;
	public Parameter b;
	public Parameter c;
	public Parameter alpha;
	public Parameter beta;
	public Parameter gamma;

	/* private */

	bool check_lattice_param(double a, double b, double c,
			double alpha, double beta, double gamma)
	{
		double D = 1.0 - Math.cos(alpha)*Math.cos(alpha)
			- Math.cos(beta)*Math.cos(beta)
			- Math.cos(gamma)*Math.cos(gamma)
			+ 2.0*Math.cos(alpha)*Math.cos(beta)*Math.cos(gamma);

		if (D < 0.0)
			return false;
		else
			return true;
	}

	public Lattice(double a, double b, double c, double alpha, double beta, double gamma)
	{
		if(this.check_lattice_param(a, b, c, alpha, beta, gamma)) {
			this.a.set("a", 0.0, a, a+10.0, false);
			this.b.set("b", 0.0, b, b+10.0, false);
			this.c.set("c", 0.0, c, c+10.0, false);
			this.alpha.set("alpha", -Math.PI, alpha, Math.PI, false);
			this.beta.set("beta", -Math.PI, beta, Math.PI, false);
			this.gamma.set("gamma", -Math.PI, gamma, Math.PI, false);
		}
	}

	public Lattice.default()
	{
		this.a.set("a", 0.0, 1.54, 11.54, false);
		this.b.set("b", 0.0, 1.54, 11.54, false);
		this.c.set("c", 0.0, 1.54, 11.54, false);
		this.alpha.set("alpha", -Math.PI, 90*DEGTORAD, Math.PI, false);
		this.beta.set("beta", -Math.PI, 90*DEGTORAD, Math.PI, false);
		this.gamma.set("gamma", -Math.PI, 90*DEGTORAD, Math.PI, false);
	}

	public void set(double a, double b, double c,
			double alpha, double beta, double gamma)
	{
		if(this.check_lattice_param(a, b, c, alpha, beta, gamma)) {
			this.a.value = a;
			this.b.value = b;
			this.c.value = c;
			this.alpha.value = alpha;
			this.beta.value = beta;
			this.gamma.value = gamma;
		}
	}

	/* 
	 * Get the B matrix from the l parameters return true if everything
	 * goes fine. false if a problem occure.
	 */
	public bool compute_B(Matrix B)
	{
		double c_alpha = Math.cos(this.alpha.value);
		double c_beta = Math.cos(this.beta.value);
		double c_gamma = Math.cos(this.gamma.value);
		double D = 1 - c_alpha*c_alpha - c_beta*c_beta - c_gamma*c_gamma
			+ 2*c_alpha*c_beta*c_gamma;

		if (D > 0.0)
			D = Math.sqrt(D);
		else
			return false;

		double s_alpha = Math.sin(this.alpha.value);
		double s_beta = Math.sin(this.beta.value);
		double s_gamma = Math.sin(this.gamma.value);

		double b11 = TAU / (this.b.value * s_alpha);
		double b22 = TAU / this.c.value;
		double tmp = b22 / s_alpha;

		B.m11 = TAU * s_alpha / (this.a.value * D);
		B.m12 = b11 / D * (c_alpha*c_beta - c_gamma);
		B.m13 = tmp / D * (c_gamma*c_alpha - c_beta);

		B.m21 = 0.0;
		B.m22 = b11;
		B.m23 = tmp / (s_beta*s_gamma) * (c_beta*c_gamma - c_alpha);

		B.m31 = 0.0;
		B.m32 = 0.0;
		B.m33 = b22;

		return true;
	}

	public bool compute_reciprocal(Lattice reciprocal)
	{
		double c_alpha = Math.cos(this.alpha.value);
		double c_beta = Math.cos(this.beta.value);
		double c_gamma = Math.cos(this.gamma.value);
		double D = 1 - c_alpha*c_alpha - c_beta*c_beta - c_gamma*c_gamma + 2*c_alpha*c_beta*c_gamma;

		if (D > 0.0)
			D = Math.sqrt(D);
		else
			return false;

		double s_alpha = Math.sin(this.alpha.value);
		double s_beta = Math.sin(this.beta.value);
		double s_gamma = Math.sin(this.gamma.value);

		double s_beta_s_gamma = s_beta*s_gamma;
		double s_gamma_s_alpha = s_gamma*s_alpha;
		double s_alpha_s_beta = s_alpha*s_beta;

		double c_beta1 = (c_beta*c_gamma-c_alpha) / s_beta_s_gamma;
		double c_beta2 = (c_gamma*c_alpha-c_beta) / s_gamma_s_alpha;
		double c_beta3 = (c_alpha*c_beta-c_gamma) / s_alpha_s_beta;
		double s_beta1 = D / s_beta_s_gamma;
		double s_beta2 = D / s_gamma_s_alpha;
		double s_beta3 = D / s_alpha_s_beta;

		reciprocal.a.value = TAU * s_alpha / (this.a.value * D);
		reciprocal.b.value = TAU * s_beta / (this.b.value * D);
		reciprocal.c.value = TAU * s_gamma / (this.c.value * D);
		reciprocal.alpha.value = Math.atan2(s_beta1, c_beta1);
		reciprocal.beta.value = Math.atan2(s_beta2, c_beta2);
		reciprocal.gamma.value = Math.atan2(s_beta3, c_beta3);

		return true;
	}

	public void randomize()
	{
		Vector vector_x = {1.0, 0.0, 0.0};
		Vector a, b, c;
		Vector axe;

		// La valeur des angles alpha, beta et gamma ne sont pas indépendant.
		// Il faut donc gérer les différents cas.
		this.a.randomize();
		this.b.randomize();
		this.c.randomize();

		uint angles_to_randomize = (uint)this.alpha.to_fit + (uint)this.beta.to_fit + (uint)this.gamma.to_fit;
		switch (angles_to_randomize) {
			case 0:
				break;
			case 1:
				if (this.alpha.to_fit) {// alpha
					a = b = c = vector_x;

					// randomize b
					axe.randomize_vector(a);
					b.rotated_around_vector(axe, this.gamma.value);

					// randomize c
					axe.randomize_vector(a);
					c.rotated_around_vector(axe, this.beta.value);

					//compute the alpha angle.
					this.alpha.value = b.angle(c);
				} else if (this.beta.to_fit) {
					// beta
					a = b = vector_x;

					// randomize b
					axe.randomize_vector(a);
					b.rotated_around_vector(axe, this.gamma.value);

					// randomize c
					c = b;
					axe.randomize_vector(b);
					c.rotated_around_vector(axe, this.alpha.value);

					//compute beta
					this.beta.value = a.angle(c);
				} else {
					// gamma
					a = c = vector_x;

					// randomize c
					axe.randomize_vector(a);
					c.rotated_around_vector(axe, this.beta.value);

					// randomize b
					b = c;
					axe.randomize_vector(c);
					b.rotated_around_vector(axe, this.alpha.value);

					//compute gamma
					this.gamma.value = a.angle(b);
				}
				break;
			case 2:
				if (this.alpha.to_fit) {
					if (this.beta.to_fit) {// alpha + beta
						a = b = vector_x;

						// randomize b
						axe.randomize_vector(a);
						b.rotated_around_vector(axe, this.gamma.value);

						//randomize c
						c.randomize_vector_vector(a, b);

						this.alpha.value = b.angle(c);
						this.beta.value = a.angle(c);
					} else {
						// alpha + gamma
						a = c = vector_x;

						// randomize c
						axe.randomize_vector(a);
						c.rotated_around_vector(axe, this.beta.value);

						//randomize c
						b.randomize_vector_vector(a, c);

						this.alpha.value = b.angle(c);
						this.gamma.value = a.angle(b);
					}
				} else {
					// beta + gamma
					b = c = vector_x;

					// randomize c
					axe.randomize_vector(b);
					c.rotated_around_vector(axe, this.alpha.value);

					//randomize c
					a.randomize_vector_vector(b, c);

					this.beta.value = a.angle(c);
					this.gamma.value = a.angle(b);
				}
				break;
			case 3:
				a.randomize();
				b.randomize_vector(a);
				c.randomize_vector_vector(b, a);

				this.alpha.value = b.angle(c);
				this.beta.value = a.angle(c);
				this.gamma.value = a.angle(b);
				break;
		}
	}
}
