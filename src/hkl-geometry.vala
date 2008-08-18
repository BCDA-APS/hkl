public class Hkl.Geometry
{
	public Source source;
	public List<Axis> axes;
	public Holder[] holders;

	public Geometry()
	{
		this.source.set(1.54, 1., 0., 0.);
		this.axes = new List<Axis>();
	}

	public Geometry.copy(Geometry src)
	{
		this.source = src.source;
		uint i;
		this.axes = new List<Axis>();
		this.holders = new Holder[src.holders.length];
		// make a deep copy of the axes
		for(i=0U; i<src.axes.length; ++i) {
			weak Axis axis = src.axes.get(i);
			axis = this.axes.add(new Axis.copy(axis));
		}

		// make a deep copy of the holders
		uint idx = 0U;
		foreach(weak Holder holder in src.holders)
			this.holders[idx++] = new Holder.copy(holder, this.axes);
	}

	public weak Holder add_holder()
	{
		int length = this.holders.length;
		this.holders.resize(length + 1);
		return this.holders[length] = new Holder(this.axes);
	}

	public weak Axis get_axis(uint idx)
	{
		return this.axes.get(idx);
	}

	public weak Axis? get_axis_by_name(string name)
	{
		uint i;
		for(; i<this.axes.length; ++i) {
			weak Axis axis = this.axes.get(i);
			if (axis.name == name)
				return axis;
		}
		return null;
	}

	public void update()
	{
		foreach(weak Holder holder in this.holders)
			holder.update();

		uint i=0U;
		for(; i<this.axes.length; ++i) {
			weak Axis axis = this.axes.get(i);
			axis.clear_dirty();
		}
	}

	public void fprintf(FileStream stream)
	{
		uint i;
		for(i=0U; i<this.axes.length; ++i) {
			weak Axis axis = this.axes.get(i);
			stream.printf(" %s : %f", axis.name, axis.config.value);
		}
	}
}
