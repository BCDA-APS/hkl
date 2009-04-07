public struct Hkl.Parameter {
	public weak string name;
	public Interval range;
	public double value;
	public weak Hkl.Unit unit;
	public weak Hkl.Unit punit;
	public bool not_to_fit;
	public bool changed;

	/* becarefull only static name */
	public Parameter(string name, double min, double value, double max,
			 bool not_to_fit, bool changed,
			 Hkl.Unit unit, Hkl.Unit punit)
	{
		this.set(name, min, value, max, not_to_fit, changed, unit, punit);
	}

	public void set(string name, double min, double value, double max,
			bool not_to_fit, bool changed,
			Hkl.Unit unit, Hkl.Unit punit)
	{
		this.name = name;
		this.range.min = min;
		this.range.max = max;
		this.value = value;
		this.unit = unit;
		this.punit = punit;
		this.not_to_fit = not_to_fit;
		this.changed = changed;
	}

	public void randomize()
	{
		if (!this.not_to_fit)
			this.value = Random.double_range(this.range.min, this.range.max);
	}
}
