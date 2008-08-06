public struct Hkl.AxisConfig {
	public Interval range;
	public double value;
	public bool dirty;
}

public class Hkl.Axis {
	public string name;
	public Vector axis_v;
	public AxisConfig config;

	public Axis(string name, Vector axis_v) {
		this.name = name;
		this.axis_v = axis_v;
		this.config.range.min = -Math.PI;
		this.config.range.max = Math.PI;
		this.config.value = 0.;
		this.config.dirty = true;
	}

	public Axis copy()
	{
		Axis copy = new Axis(this.name, this.axis_v);
		copy.config = this.config;
		return copy;
	}

	public void get_config(ref AxisConfig config)
	{
		config = this.config;
	}

	public void set_config(AxisConfig config) {
		this.config = config;
		this.config.dirty = true;
	}

	public void get_quaternion(Quaternion q) {
		q.from_angle_and_axe(this.config.value, this.axis_v);
	}

	public void clear_dirty() {
		this.config.dirty = false;
	}
}
