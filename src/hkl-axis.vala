public class Hkl.Axis : Hkl.Parameter {
	public Vector axis_v;
	public Quaternion q;

	/* becareful the name must be a static string */
	public Axis(string name, Vector axis_v)
	{
		base(name, -Math.PI, 0.0, Math.PI,
				false, false,
				hkl_unit_angle_rad, hkl_unit_angle_deg);
		this.axis_v = axis_v;
		this.q = Quaternion(1.0, 0.0, 0.0, 0.0);
	}

	public Axis.copy(Axis axis)
	{
		base.copy(this);
		this.axis_v = axis.axis_v;
		this.q = axis.q;
	}

	public override void set_value(double value)
	{
		base.set_value(value);
		this.q.from_angle_and_axe(this.value, this.axis_v);
	}

	public override void set_value_unit(double value)
	{
		base.set_value_unit(value);
		this.q.from_angle_and_axe(this.value, this.axis_v);
	}

	public override void randomize()
	{
		base.randomize();
		this.q.from_angle_and_axe(this.value, this.axis_v);
		this.changed = true;
	}
}
