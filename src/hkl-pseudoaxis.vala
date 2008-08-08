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


public struct Hkl.PseudoAxisEngineFunc
{
	public Gsl.MultirootFunction f;
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
	public uint[] related_axes_idx;
	public List<PseudoAxis> pseudoAxes;

	public abstract bool to_geometry();
	public abstract bool to_pseudoAxes();
	public abstract bool equiv_geometries();

	public bool init(string name, string[] names, Geometry g,
			string[] axes)
	{
		uint i;
		this.name = name;
		this.is_initialized = 0;
		this.is_readable = 0;
		this.is_writable = 0;
		this.geometry = new Geometry.copy(g);
		this.related_axes_idx = new uint[axes.length];
		for(i=0U; i<axes.length; ++i) {
			weak Axis axis = this.geometry.get_axis_by_name(axes[i]);
			int idx = this.geometry.axes.index_of(axis);
			if (idx >=0)
				this.related_axes_idx[i] = idx;
			else
				return false;
		}

		this.pseudoAxes = new List<PseudoAxis>();
		foreach(weak string s in names)
			this.pseudoAxes.add(new PseudoAxis(s, this));

		return true;
	}

	public void set(PseudoAxisEngineFunc f, Detector det, Sample sample)
	{
		this.detector = det;
		this.sample = sample;
		this.function = f;
	}
}
