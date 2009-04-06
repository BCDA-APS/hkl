public struct Hkl.Detector
{
	public uint idx;

	public Detector(uint idx)
	{
		this.idx = idx;
	}

	public void compute_kf(Geometry g, out Vector kf) requires (this.idx < g.holders.length)
	{
		g.update();

		weak Holder holder = g.holders[this.idx];
		kf.set(TAU / g.source.wave_length, 0.0, 0.0);
		kf.rotated_quaternion(holder.q);
	}
}
