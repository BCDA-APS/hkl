public class Hkl.Holder {
	weak Geometry geometry;
	public Axis[] axes;
	public Quaternion q;

	public Holder(Geometry geometry)
	{
		this.geometry = geometry;
		q.set(1.0, 0.0, 0.0, 0.0);
	}

	public Holder.copy(Holder src, Geometry geometry)
	{
		this.geometry = geometry;
		this.axes = new Axis[src.axes.length];

		/* populate the private_axes from the axes */
		uint i = 0U;
		for(; i<src.axes.length; ++i) {
			weak Axis axis = src.axes[i];
			uint idx=0U;
			foreach(weak Axis axiss in src.geometry.axes) {
				if (axiss == axis)
					this.axes[i] = this.geometry.axes[idx];
				++idx;
			}
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
			this.q.set(1.0, 0.0, 0.0, 0.0);
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
		foreach(weak Axis axis in this.geometry.axes)
			if (axis.name == name)
				return axis;
		int length = this.geometry.axes.length;
		this.geometry.axes.resize(length + 1);
		return this.geometry.axes[length] = new Axis(name, axis_v);
	}

	bool is_dirty()
	{
		foreach(weak Axis axis in this.axes)
			if (axis.config.dirty)
				return true;
		return false;
	}

}
