public struct Hkl.Source
{
	public double wave_length;
	public Vector direction;

	public void set(double wave_length, double x, double y, double z) requires (wave_length > EPSILON && Math.sqrt(x*x + y*y + z*z) > EPSILON)
	{
		double norm = Math.sqrt(x*x + y*y + z*z);

		this.wave_length = wave_length;
		this.direction.set(x, y, z);
		this.direction.div_double(norm);
	}

	/** compare two sources */
	public bool cmp(Source s)
	{
		if (Math.fabs(this.wave_length - s.wave_length) < EPSILON
				&& this.direction.is_colinear(s.direction))
			return false;
		else
			return true;
	}

	/** compute the ki Vector */
	public void get_ki(ref Vector ki)
	{
		double k = TAU / this.wave_length;
		ki = this.direction;
		ki.times_double(k);
	}
}
