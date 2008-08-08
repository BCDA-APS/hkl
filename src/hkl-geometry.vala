public class Hkl.Geometry
{
	public Source source;
	public List<Axis> axes;
	public List<Holder> holders;

	public Geometry()
	{
		this.source.set(1.54, 1., 0., 0.);
		this.axes = new List<Axis>();
		this.holders = new List<Holder>();
	}

	public Geometry.copy(Geometry src)
	{
		this.source = src.source;
		uint i;
		this.axes = new List<Axis>();
		this.holders = new List<Holder>();
		// make a deep copy of the axes
		for(i=0U; i<src.axes.size(); ++i) {
			weak Axis axis = src.axes.get(i);
			axis = this.axes.add(new Axis.copy(axis));
		}

		// make a deep copy of the holders
		for(i=0U; i<src.holders.size(); ++i) {
			weak Holder holder = src.holders.get(i);
			holder = this.holders.add(new Holder.copy(holder, this.axes));
		}
	}

	public weak Holder add_holder()
	{
		return this.holders.add(new Holder(this.axes));
	}

	public weak Holder get_holder(uint idx)
	{
		return this.holders.get(idx);
	}

	public weak Axis get_axis(uint idx)
	{
		return this.axes.get(idx);
	}

	public weak Axis? get_axis_by_name(string name)
	{
		uint i;
		for(; i<this.axes.size(); ++i) {
			weak Axis axis = this.axes.get(i);
			if (axis.name == name)
				return axis;
		}
		return null;
	}

	public uint get_holders_size()
	{
		return this.holders.size();
	}

	public uint get_axes_size()
	{
		return this.axes.size();
	}

	public void update()
	{
		uint i;
		for(i=0U; i<this.holders.size(); ++i) {
			weak Holder holder = this.holders.get(i);
			holder.update();
		}

		for(i=0U; i<this.axes.size(); ++i) {
			weak Axis axis = this.axes.get(i);
			axis.clear_dirty();
		}
	}

	public void fprintf(FileStream stream)
	{
		uint i;
		for(i=0U; i<this.axes.size(); ++i) {
			weak Axis axis = this.axes.get(i);
			stream.printf(" %s : %f", axis.name, axis.config.value);
		}
	}
}
