public struct Hkl.Parameter {
	public weak string name;
	public Interval range;
	public double value;
	public bool to_fit;

	/* becarefull only static name */
	public Parameter(string name, double min, double value, double max, bool to_fit)
	{
		this.set(name, min, value, max, to_fit);
	}

	public void set(string name, double min, double value, double max, bool to_fit)
	{
		this.name = name;
		this.range.min = min;
		this.range.max = max;
		this.value = value;
		this.to_fit = to_fit;
	}

	public void randomize()
	{
		if (this.to_fit)
			this.value = Random.double_range(this.range.min, this.range.max);
	}
}
