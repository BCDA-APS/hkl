public class Hkl.Geometry
{
	public Source source;
	public Axis[] axes;
	public Holder[] holders;

	public Geometry()
	{
		this.source.set(1.54, 1., 0., 0.);
	}

	public Geometry.TwoCV()
	{
		this.source.set(1.54, 1., 0., 0.);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("omega", 0., -1., 0.);

		h = this.add_holder();
		h.add_rotation_axis("tth", 0., -1., 0.);
	}

	public Geometry.E4CV()
	{
		this.source.set(1.54, 1., 0., 0.);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("omega", 0., -1., 0.);
		h.add_rotation_axis("chi", 1., 0., 0.);
		h.add_rotation_axis("phi", 0., -1., 0.);

		h = this.add_holder();
		h.add_rotation_axis("tth", 0., -1., 0.);
	}

	public Geometry.K4CV(double alpha)
	{
		this.source.set(1.54, 1., 0., 0.);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("komega", 0., -1., 0.);
		h.add_rotation_axis("kappa", 0., -Math.cos(alpha), -Math.sin(alpha));
		h.add_rotation_axis("kphi", 0., -1., 0.);

		h = this.add_holder();
		h.add_rotation_axis("tth", 0., -1., 0.);
	}

	public Geometry.E6C()
	{
		this.source.set(1.54, 1., 0., 0.);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("mu", 0., 0., 1.);
		h.add_rotation_axis("omega", 0., -1., 0.);
		h.add_rotation_axis("chi", 1., 0., 0.);
		h.add_rotation_axis("phi", 0., -1., 0.);

		h = this.add_holder();
		h.add_rotation_axis("gamma", 0., 0., 1.);
		h.add_rotation_axis("delta", 0., -1., 0.);
	}

	public Geometry.K6C(double alpha)
	{
		this.source.set(1.54, 1., 0., 0.);

		weak Holder h = this.add_holder();
		h.add_rotation_axis("mu", 0., 0., 1.);
		h.add_rotation_axis("komega", 0., -1., 0.);
		h.add_rotation_axis("kappa", 0., -Math.cos(alpha), -Math.sin(alpha));
		h.add_rotation_axis("kphi", 0., -1., 0.);

		h = this.add_holder();
		h.add_rotation_axis("gamma", 0., 0., 1.);
		h.add_rotation_axis("delta", 0., -1., 0.);
	}

	public Geometry.copy(Geometry src)
	{
		this.source = src.source;
		this.axes = new Axis[src.axes.length];
		this.holders = new Holder[src.holders.length];
		// make a deep copy of the axes
		uint idx=0U;
		foreach(weak Axis axis in src.axes)
			this.axes[idx++] = new Axis.copy(axis);

		// make a deep copy of the holders
		idx = 0U;
		foreach(weak Holder holder in src.holders)
			this.holders[idx++] = new Holder.copy(holder, this);
	}

	public weak Holder add_holder()
	{
		int length = this.holders.length;
		this.holders.resize(length + 1);
		return this.holders[length] = new Holder(this);
	}

	public weak Axis? get_axis_by_name(string name)
	{
		foreach(weak Axis axis in this.axes)
			if (axis.name == name)
				return axis;
		return null;
	}

	public void update()
	{
		foreach(weak Holder holder in this.holders)
			holder.update();

		foreach(weak Axis axis in this.axes)
			axis.clear_dirty();
	}

	public void fprintf(FileStream stream)
	{
		foreach(weak Axis axis in this.axes)
			stream.printf(" %s : %f", axis.name, axis.config.value);
	}
}
