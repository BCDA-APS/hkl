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
	Gsl.MultirootFunction[] functions = {f1};
	string[] names = {"omega", "chi", "phi", "tth"};

	Hkl.PseudoAxisEngineAutoFunc func = {"bissector", functions, names};

	return func;
}

public Hkl.PseudoAxisEngineAutoFunc E4CV_constant_omega_func(Hkl.PseudoAxisEngine *engine)
{
	Gsl.MultirootFunction f1 = {E4CV_constant_omega, 4, engine};
	Gsl.MultirootFunction[] functions = {f1};
	string[] names = {"omega", "chi", "phi", "tth"};
	var p1 = new Hkl.Parameter("omega", -Math.PI, 0.0, Math.PI,
			false, false, hkl_unit_angle_rad, hkl_unit_angle_deg);
	Hkl.Parameter[] parameters = {p1};

	Hkl.PseudoAxisEngineAutoFunc func = {"constant_omega", functions, names, parameters};

	return func;
}

public Hkl.PseudoAxisEngineAutoFunc E4CV_constant_chi_func(Hkl.PseudoAxisEngine *engine)
{
	Gsl.MultirootFunction f1 = {E4CV_constant_chi, 4, engine};
	Gsl.MultirootFunction[] functions = {f1};
	string[] names = {"omega", "chi", "phi", "tth"};
	var p1 = new Hkl.Parameter("chi", -Math.PI, 0.0, Math.PI,
			false, false, hkl_unit_angle_rad, hkl_unit_angle_deg);
	Hkl.Parameter[] parameters = {p1};

	Hkl.PseudoAxisEngineAutoFunc func = {"constant_chi", functions, names, parameters};

	return func;
}

public Hkl.PseudoAxisEngineAutoFunc E4CV_constant_phi_func(Hkl.PseudoAxisEngine *engine)
{
	Gsl.MultirootFunction f1 = {E4CV_constant_phi, 4, engine};
	Gsl.MultirootFunction[] functions = {f1};
	string[] names = {"omega", "chi", "phi", "tth"};
	var p1 = new Hkl.Parameter("phi", -Math.PI, 0.0, Math.PI,
			false, false, hkl_unit_angle_rad, hkl_unit_angle_deg);
	Hkl.Parameter[] parameters = {p1};

	Hkl.PseudoAxisEngineAutoFunc func = {"constant_phi", functions, names, parameters};

	return func;
}
