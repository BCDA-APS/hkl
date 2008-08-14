public class Hkl.List<T>
{
	public uint length;
	T[] list;

	public List()
	{
		this.length = 0U;
		this.list = new T[N];
	}

	public weak T add(T# item)
	{
		if (this.length == this.list.length)
			this.list.resize((int)(this.list.length + N));
		this.list[this.length++] = item;
		return item;
	}

	public bool del(uint idx) requires (idx < this.length)
	{
		uint i=idx;
		this.list[idx];
		for(; i< this.length - 1; ++i)
			this.list[i] = this.list[i+1];
		this.length--;
		return true;
	}

	public void clear()
	{
		this.length = 0;
		this.list = new T[N];
	}

	public weak T get(uint idx) requires (idx < this.length)
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
