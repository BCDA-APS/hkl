static int E4CV_bissector(Gsl.Vector x, void *params, Gsl.Vector f)
{
	double omega, tth;

	RUBh_minus_Q(x, params, f);

	omega = Gsl.Trig.angle_restrict_pos(x.get(0));
	tth = Gsl.Trig.angle_restrict_pos(x.get(3));

	f.set(3, tth - 2 * Math.fmod(omega, Math.PI));

	return  Gsl.Status.SUCCESS;
}

static int E4CV_constant_omega(Gsl.Vector x, void *params, Gsl.Vector f)
{
	Hkl.PseudoAxisEngineAuto *engine = params;
	double omega = x.get(0);
	double omega_c = engine->function.parameters[0].value;

	RUBh_minus_Q(x, params, f);
	f.set(3, omega - omega_c);
	return Gsl.Status.SUCCESS;
}

static int E4CV_constant_chi(Gsl.Vector x, void *params, Gsl.Vector f)
{
	Hkl.PseudoAxisEngineAuto *engine = params;
	double chi = x.get(1);
	double chi_c = engine->function.parameters[0].value;

	RUBh_minus_Q(x, params, f);
	f.set(3, chi - chi_c);
	return Gsl.Status.SUCCESS;
}

static int E4CV_constant_phi(Gsl.Vector x, void *params, Gsl.Vector f)
{
	Hkl.PseudoAxisEngineAuto *engine = params;
	double phi = x.get(2);
	double phi_c = engine->function.parameters[0].value;

	RUBh_minus_Q(x, params, f);
	f.set(3, phi - phi_c);
	return Gsl.Status.SUCCESS;
}

public Hkl.PseudoAxisEngineAutoFunc E4CV_bissector_func(Hkl.PseudoAxisEngine *engine)
{
	Gsl.MultirootFunction f1 = {E4CV_bissector, 4, engine};

	Hkl.PseudoAxisEngineAutoFunc func = {"bissector", {f1}, {"omega", "chi", "phi", "tth"}, {}};

	return func;
}

public Hkl.PseudoAxisEngineAutoFunc E4CV_constant_omega_func(Hkl.PseudoAxisEngine *engine)
{
	Gsl.MultirootFunction f1 = {E4CV_constant_omega, 4, engine};
	Hkl.Parameter p1 = {"omega", {-Math.PI, Math.PI}, 0.0, true};

	Hkl.PseudoAxisEngineAutoFunc func = {"constant_omega", {f1}, {"omega", "chi", "phi", "tth"}, {p1}};

	return func;
}

public Hkl.PseudoAxisEngineAutoFunc E4CV_constant_chi_func(Hkl.PseudoAxisEngine *engine)
{
	Gsl.MultirootFunction f1 = {E4CV_constant_chi, 4, engine};
	Hkl.Parameter p1 = {"chi", {-Math.PI, Math.PI}, 0.0, true};

	Hkl.PseudoAxisEngineAutoFunc func = {"constant_chi", {f1}, {"omega", "chi", "phi", "tth"}, {p1}};

	return func;
}

public Hkl.PseudoAxisEngineAutoFunc E4CV_constant_phi_func(Hkl.PseudoAxisEngine *engine)
{
	Gsl.MultirootFunction f1 = {E4CV_constant_phi, 4, engine};
	Hkl.Parameter p1 = {"phi", {-Math.PI, Math.PI}, 0.0, true};

	Hkl.PseudoAxisEngineAutoFunc func = {"constant_phi", {f1}, {"omega", "chi", "phi", "tth"}, {p1}};

	return func;
}
