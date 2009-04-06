public struct Hkl.AxisConfig {
	public Interval range;
	public double value;
	public bool dirty;
}

public class Hkl.Axis {
	public weak string name;
	public Vector axis_v;
	public AxisConfig config;

	/* becareful the name must be a static string */
	public Axis(string name, Vector axis_v) {
		this.name = name;
		this.axis_v = axis_v;
		this.config.range.min = -Math.PI;
		this.config.range.max = Math.PI;
		this.config.value = 0.0;
		this.config.dirty = true;
	}

	public Axis.copy(Axis src)
	{
		this.name = src.name;
		this.axis_v = src.axis_v;
		this.config = src.config;
	}

	public void get_config(out AxisConfig config)
	{
		config = this.config;
	}

	public void set_config(AxisConfig config) {
		this.config = config;
		this.config.dirty = true;
	}

	public void get_quaternion(out Quaternion q) {
		q.from_angle_and_axe(this.config.value, this.axis_v);
	}

	public void clear_dirty() {
		this.config.dirty = false;
	}
}
