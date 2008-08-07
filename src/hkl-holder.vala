public class Hkl.Holder {
	weak List<Axis> axes;
	List<weak Axis> private_axes;
	public Quaternion q;

	public Holder(List<Axis> axes)
	{
		this.axes = axes;
		this.private_axes = new List<weak Axis>();
		q.set(1., 0., 0., 0.);
	}

	public Holder.copy(Holder src, List<Axis> axes)
	{
		this.axes = axes;
		this.private_axes = new List<weak Axis>();

		/* populate the private_axes from the axes */
		uint i = 0U;
		for(; i<src.private_axes.size(); ++i) {
			weak Axis axis = src.private_axes.get(i);
			int idx = src.axes.index_of(axis);
			axis = this.axes.get(idx);
			axis = this.private_axes.add(axis);
		}

		/* now copy the quaternion */
		this.q = src.q;
	}

	public weak Axis add_rotation_axis(string name,
			double x, double y, double z)
	{
		Vector axis_v = {x, y, z};
		weak Axis axis = this.add_rotation(name, axis_v);

		/* axis already in the holder ? */
		if (!this.private_axes.contains(axis))
			axis = this.private_axes.add(axis);
		return axis;
	}

	public uint length()
	{
		return this.private_axes.size();
	}

	public weak Axis get_axis(int idx)
	{
		return this.private_axes.get(idx);
	}

	public void update()
	{
		if (this.is_dirty()) {
			uint i;
			this.q.set(1., 0., 0., 0.);
			for(; i<this.private_axes.size(); ++i) {
				Quaternion q;
				weak Axis axis = this.private_axes.get(i);
				axis.get_quaternion(q);
				this.q.times_quaternion(q);
			}
		}
	}

	/* 
	 * Try to add a axis to the axes list,
	 * if a identical axis is present in the list return it
	 * else add it to the list.
	 */
	weak Axis add_rotation(string name, Vector axis_v)
	{
		uint i;
		// check if an axis with the same name is in the axis list.
		for(; i<this.axes.size(); ++i) {
			weak Axis axis = this.axes.get(i);
			if (axis.name == name)
				return axis;
		}
		return this.axes.add(new Axis(name, axis_v));
	}

	bool is_dirty()
	{
		uint i;
		for(; i<this.private_axes.size(); ++i) {
			weak Axis axis = this.private_axes.get(i);
			if (axis.config.dirty)
				return true;
		}
		return false;
	}

}
