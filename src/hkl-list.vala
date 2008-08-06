public class Hkl.List<T>
{
	uint length;
	T[] list;

	public List()
	{
		this.length = 0;
		/* for now a hack reserve enought space*/
		this.list = new T[100];
	}

	public void add(T# item) requires (this.length < this.list.length)
	{
		this.list[this.length++] = item;
	}

	public uint size()
	{
		return this.length;
	}

	public weak T get(uint idx) requires (idx <this.length)
	{
		return this.list[idx]; 
	}

	public int index_of(T item)
	{
		int i;
		for(i=0; i<this.length; ++i)
			if (this.list[i] == item)
				return i;
		return -1;
	}

	public bool contains(T item)
	{
		if (this.index_of(item) < 0)
			return false;
		else
			return true;
	}
}
