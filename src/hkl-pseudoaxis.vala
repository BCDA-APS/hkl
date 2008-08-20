public class Hkl.PseudoAxis
{
	public weak string name;
	public AxisConfig config;
	public weak PseudoAxisEngine engine;

	public PseudoAxis(string name, PseudoAxisEngine engine)
	{
		this.name = name;
		this.engine = engine;
	}
}

/* as vala do not support delegates array for now lets do this */
public struct Hkl.PseudoAxisEngineFunc
{
	public Gsl.MultirootFunction[] f;
	public string[] axes;
	public Parameter[] parameters;
}

public abstract class Hkl.PseudoAxisEngine
{
	public weak string name;
	public weak PseudoAxisEngineFunc function;
	public int is_initialized;
	public int is_readable;
	public int is_writable;
	public Geometry geometry;
	public Detector detector;
	public weak Sample sample;
	public Axis[] axes;
	public PseudoAxis[] pseudoAxes;
	public List<Geometry> geometries;

	public abstract bool compute_geometries();
	public abstract bool compute_pseudoAxes(Geometry g);

	public bool init(string name, string[] names, Geometry g)
	{
		this.name = name;
		this.is_initialized = 0;
		this.is_readable = 0;
		this.is_writable = 0;
		this.geometry = new Geometry.copy(g);
		this.pseudoAxes = new PseudoAxis[names.length];
		this.geometries = new List<Geometry>();
		uint idx=0U;
		foreach(weak string s in names)
			this.pseudoAxes[idx++] = new PseudoAxis(s, this);
		return true;
	}

	public virtual bool set(PseudoAxisEngineFunc f, Detector det, Sample sample)
	{
		this.detector = det;
		this.sample = sample;
		this.function = f;
		this.axes = new Axis[f.axes.length];
		uint idx=0U;
		foreach(weak string s in f.axes)
			this.axes[idx++] = this.geometry.get_axis_by_name(s);
		return true;
	}
}
