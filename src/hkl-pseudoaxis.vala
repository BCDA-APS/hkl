public class Hkl.PseudoAxis : Hkl.Parameter
{
	public weak PseudoAxisEngine engine;

	public PseudoAxis(string name, PseudoAxisEngine engine)
	{
		this.name = name;
		this.engine = engine;
	}
}

public abstract class Hkl.PseudoAxisEngine
{
	public weak string name;
	public int is_initialized;
	public int is_readable;
	public int is_writable;
	public Geometry geometry;
	public Detector detector;
	public weak Sample sample;
	public Axis[] axes;
	public PseudoAxis[] pseudoAxes;
	public List<Geometry> geometries;

	public abstract bool set(uint idx, Detector det, Sample sample);
	public abstract bool set_by_name(string name, Detector det, Sample sample);
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
}
