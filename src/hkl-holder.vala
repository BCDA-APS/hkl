public class Hkl.Holder {
	weak List<Axis> _axes;
	public Axis[] axes;
	public Quaternion q;

	public Holder(List<Axis> _axes)
	{
		this._axes = _axes;
		q.set(1., 0., 0., 0.);
	}

	public Holder.copy(Holder src, List<Axis> _axes)
	{
		this._axes = _axes;
		this.axes = new Axis[src.axes.length];

		/* populate the private_axes from the axes */
		uint i = 0U;
		for(; i<src.axes.length; ++i) {
			weak Axis axis = src.axes[i];
			int idx = src._axes.index_of(axis);
			axis = this.axes[i] = this._axes.get(idx);
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
		foreach(weak Axis p_axis in this.axes)
			if (axis == p_axis)
				return axis;
		int length = this.axes.length;
		this.axes.resize(length + 1);
		return this.axes[length] = axis;
	}

	public void update()
	{
		if (this.is_dirty()) {
			this.q.set(1., 0., 0., 0.);
			foreach(weak Axis axis in this.axes) {
				Quaternion q;
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
		for(; i<this._axes.length; ++i) {
			weak Axis axis = this._axes.get(i);
			if (axis.name == name)
				return axis;
		}
		return this._axes.add(new Axis(name, axis_v));
	}

	bool is_dirty()
	{
		foreach(weak Axis axis in this.axes)
			if (axis.config.dirty)
				return true;
		return false;
	}

}
