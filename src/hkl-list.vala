public class Hkl.List<T>
{
	GLib.List<T> list;

	public void add(T# item)
	{
		this.list.append(item);
	}

	public uint size()
	{
		return this.list.length();
	}

	public weak T get(uint idx) requires (idx <this.list.length())
	{
		return this.list.nth_data(idx); 
	}

	public int index_of(T item)
	{
		return this.list.index(item);
	}

	public bool contains(T item)
	{
		if (this.list.index(item) < 0)
			return false;
		else
			return true;
	}
}
