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

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD)) - Math.PI / 2.0;
	omega = Gsl.Trig.angle_restrict_symm(omega);
	f.set(3, tth - 2.0 *omega);

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

	omega = komega + Math.atan(Math.tan(kappa/2.0)*Math.cos(50 * Hkl.DEGTORAD)) + Math.PI / 2.0;
	omega = Gsl.Trig.angle_restrict_symm(omega);
	f.set(3, tth - 2.0 *omega);

	return  Gsl.Status.SUCCESS;
}

public Hkl.PseudoAxisEngineAutoFunc K4CV_bissector_func(Hkl.PseudoAxisEngine *engine)
{
	Gsl.MultirootFunction f1 = {K4CV_bissector_1, 4, engine};
	Gsl.MultirootFunction f2 = {K4CV_bissector_2, 4, engine};

	Hkl.PseudoAxisEngineAutoFunc func = {"bissector", {f1, f2}, {"komega", "kappa", "kphi", "tth"}};

	return func;
}
