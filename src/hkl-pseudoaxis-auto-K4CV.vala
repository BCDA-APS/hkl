static int K4CV_bissector_1(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double komega, tth, kappa, kphi, omega;
	double *angles = x.ptr(0);

	for(uint i=0U; i<x.size; ++i)
		if (angles[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x, params, f);

	komega = Gsl.Trig.angle_restrict_symm(angles[0]);
	kappa = Gsl.Trig.angle_restrict_symm(angles[1]);
	kphi = Gsl.Trig.angle_restrict_symm(angles[2]);
	tth = Gsl.Trig.angle_restrict_symm(angles[3]);

	omega = komega + Math.atan(Math.tan(kappa/2.)*Math.cos(50 * Hkl.DEGTORAD)) - Math.PI / 2.;
	omega = Gsl.Trig.angle_restrict_symm(omega);
	f.set(3, tth - 2 *omega);

	return  Gsl.Status.SUCCESS;
}

static int K4CV_bissector_2(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double komega, tth, kappa, kphi, omega;
	double *angles = x.ptr(0);

	for(uint i=0U; i<x.size; ++i)
		if (angles[i].is_nan())
			return Gsl.Status.ENOMEM;

	RUBh_minus_Q(x, params, f);

	komega = Gsl.Trig.angle_restrict_symm(angles[0]);
	kappa = Gsl.Trig.angle_restrict_symm(angles[1]);
	kphi = Gsl.Trig.angle_restrict_symm(angles[2]);
	tth = Gsl.Trig.angle_restrict_symm(angles[3]);

	omega = komega + Math.atan(Math.tan(kappa/2.)*Math.cos(50 * Hkl.DEGTORAD)) + Math.PI / 2.;
	omega = Gsl.Trig.angle_restrict_symm(omega);
	f.set(3, tth - 2 *omega);

	return  Gsl.Status.SUCCESS;
}

public Hkl.PseudoAxisEngineAutoFunc K4CV_bissector_func(Hkl.PseudoAxisEngine *engine)
{
	Gsl.MultirootFunction f1 = {K4CV_bissector_1, 4, engine};
	Gsl.MultirootFunction f2 = {K4CV_bissector_2, 4, engine};

	Hkl.PseudoAxisEngineAutoFunc func;
	func.name = "bissector";
	func.f = new Gsl.MultirootFunction[2];
	func.f[0] = f1;
	func.f[1] = f2;
	func.axes = new string[4];
	func.axes[0] = "komega";
	func.axes[1] = "kappa";
	func.axes[2] = "kphi";
	func.axes[3] = "tth";
	func.parameters = new Hkl.Parameter[0];

	return func;
}
