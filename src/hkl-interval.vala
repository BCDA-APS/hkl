public struct Hkl.Interval {
	public double min;
	public double max;

	/** compare two intervals */
	public bool cmp(Interval interval)
	{
		bool min_ko = true;
		bool max_ko = true;

		if (this.min.is_infinity() == interval.min.is_infinity()) {
			min_ko = false;
		} else if (Math.fabs(this.min - interval.min) < EPSILON)
			min_ko = false;

		if (this.max.is_infinity() == interval.max.is_infinity()) {
			max_ko = false;
		} else if (Math.fabs(this.max - interval.max) < EPSILON)
			max_ko = false;

		if ((min_ko == false) && (max_ko == false))
			return false;
		else
			return true;

	}

	/** add two intervals */
	public void add_interval(Interval interval)
	{
		this.min += interval.min;
		this.max += interval.max;
	}

	/** add to an interval a double */
	public void add_double(double d)
	{
		this.min += d;
		this.max += d;
	}


	public void minus_interval(Interval interval)
	{
		this.min -= interval.max;
		this.max -= interval.min;
	}


	public void minus_double(double d)
	{
		this.min -= d;
		this.max -= d;
	}

	public void times_interval(Interval interval)
	{
		double min;
		double max;
		double m1 = this.min * interval.min;
		double m2 = this.min * interval.max;
		double m3 = this.max * interval.min;
		double m4 = this.max * interval.max;

		min = m1;
		if (m2 < min)
			min = m2;
		if (m3 < min)
			min = m3;
		if (m4 < min)
			min = m4;

		max = m1;
		if (m2 > max)
			max = m2;
		if (m3 > max)
			max = m3;
		if (m4 > max)
			max = m4;

		this.min = min;
		this.max = max;
	}

	public void times_double(double d)
	{
		double min;
		double max;
		if (d < 0) {
			min = this.max * d;
			max = this.min * d;
		} else {
			min = this.min * d;
			max = this.max * d;
		}
		this.min = min;
		this.max = max;
	}

	public void divides_double(double d)
	{
		double min = this.min / d;
		double max = this.max / d;
		if (min > max)
		{
			double tmp = min;
			min = max;
			max = tmp;
		}
		this.min = min;
		this.max = max;
	}

	public bool contain_zero()
	{
		return this.min <= 0 && this.max >= 0;
	}

	public void cos()
	{
		double min;
		double max;
		double cmin = Math.cos(this.min);
		double cmax = Math.cos(this.max);

		if (this.max - this.min >= 2 * Math.PI) {
			min = -1;
			max = 1;
		} else {
			int quad_min;
			int quad_max;

			quad_min = (int)Math.floor(this.min / Math.PI * 2.) % 4;
			if (quad_min < 0)
				quad_min += 4;

			quad_max = (int)Math.floor(this.max / Math.PI * 2.) % 4;
			if (quad_max < 0)
				quad_max += 4;

			switch (quad_max) {
				case 0:
					switch (quad_min) {
						case 0:
							min = cmax;
							max = cmin;
							break;
						case 1:
							min = -1;
							max = 1;
							break;
						case 2:
							min = cmin;
							max = 1;
							break;
						case 3:
							if (cmin < cmax) {
								min = cmin;
								max = 1;
							} else {
								min = cmax;
								max = 1;
							}
							break;
					}
					break;
				case 1:
					switch (quad_min) {
						case 0:
							min = cmax;
							max = cmin;
							break;
						case 1:
							min = -1;
							max = 1;
							break;
						case 2:
							if (cmin < cmax) {
								min = cmin;
								max = 1;
							} else {
								min = cmax;
								max = 1;
							}
							break;
						case 3:
							min = cmax;
							max = 1;
							break;
					}
					break;
				case 2:
					switch (quad_min) {
						case 0:
							min = -1;
							max = cmin;
							break;
						case 1:
							if (cmin < cmax) {
								min = -1;
								max = cmax;
							} else {
								min = -1;
								max = cmin;
							}
							break;
						case 2:
							if (cmin < cmax) {
								min = cmin;
								max = cmax;
							} else {
								min = -1;
								max = 1;
							}
							break;
						case 3:
							min = -1;
							max = 1;
							break;
					}
					break;
				case 3:
					switch (quad_min) {
						case 0:
							if (cmin < cmax) {
								min = -1;
								max = cmax;
							} else {
								min = -1;
								max = cmin;
							}
							break;
						case 1:
							min = -1;
							max = cmax;
							break;
						case 2:
							min = cmin;
							max = cmax;
							break;
						case 3:
							if (cmin < cmax) {
								min = cmin;
								max = cmax;
							} else {
								min = -1;
								max = 1;
							}
							break;
					}
					break;
			}
		}
		this.min = min;
		this.max = max;
	}

	public void acos()
	{
		double tmp = this.min;
		this.min = Math.acos(this.max);
		this.max = Math.acos(tmp);
	}


	public void sin()
	{
		double min;
		double max;
		double smin = Math.sin(this.min);
		double smax = Math.sin(this.max);

		/* if there is at least one period in b, then a = [-1, 1] */
		if ( this.max - this.min >= 2. * Math.PI) {
			min = -1.;
			max = 1.;
		} else {
			int quad_min;
			int quad_max;

			quad_min = (int)Math.floor(this.min / Math.PI * 2.) % 4;
			if (quad_min < 0)
				quad_min += 4;

			quad_max = (int)Math.floor(this.max / Math.PI * 2.) % 4;
			if (quad_max < 0)
				quad_max += 4;

			switch (quad_max) {
				case 0:
					switch (quad_min) {
						case 0:
							if (smin < smax) {
								min = smin;
								max = smax;
							} else {
								min = -1.;
								max = 1.;
							}
							break;
						case 3:
							min = smin;
							max = smax;
							break;
						case 1:
							if (smin > smax) {
								min = -1.;
								max = smin;
							} else {
								min = -1.;
								max = smax;
							}
							break;
						case 2:
							min = -1.;
							max = smax;
							break;
					}
					break;
				case 1:
					switch (quad_min) {
						case 0:
							if (smin < smax) {
								min = smin;
								max = 1.;
							} else {
								min = smax;
								max = 1;
							}
							break;
						case 1:
							if (smin < smax) {
								min = -1.;
								max = 1.;
							} else {
								min = smax;
								max = smin;
							}
							break;
						case 2:
							min = -1.;
							max = 1.;
							break;
						case 3:
							min = smin;
							max = 1.;
							break;
					}
					break;
				case 2:
					switch (quad_min) {
						case 0:
							min = smax;
							max = 1.;
							break;
						case 1:
						case 2:
							if (smin < smax) {
								min = -1.;
								max = 1.;
							} else {
								min = smax;
								max = smin;
							}
							break;
						case 3:
							if (smin < smax) {
								min = smin;
								max = 1.;
							} else {
								min = smax;
								max = 1.;
							}
							break;
					}
					break;
				case 3:
					switch (quad_min) {
						case 0:
							min = -1.;
							max = 1.;
							break;
						case 1:
							min = -1.;
							max = smin;
							break;
						case 2:
							if (smin < smax) {
								min = -1.;
								max = smax;
							} else {
								min = -1.;
								max = smin;
							}
							break;
						case 3:
							if (smin < smax) {
								min = smin;
								max = smax;
							} else {
								min = -1.;
								max = 1.;
							}
							break;
					}
					break;
			}
		}
		this.min = min;
		this.max = max;
	}

	public void asin()
	{
		this.min = Math.asin(this.min);
		this.max = Math.asin(this.max);
	}

	public void tan()
	{
		int quadrant_down = (int)Math.floor(this.min / Math.PI * 2.);
		int quadrant_up = (int)Math.floor(this.max / Math.PI * 2.);

		/* if there is at least one period in b or if b contains a Pi/2 + k*Pi, */
		/* then a = ]-oo, +oo[ */
		if ( ((quadrant_up - quadrant_down) >= 2)
				|| ((quadrant_down % 2 == 0) && (quadrant_up % 2 != 0)) ) {
			this.min = -double.INFINITY;
			this.max = double.INFINITY;
		} else {
			this.min = Math.tan(this.min);
			this.max = Math.tan(this.max);
		}
	}

	public void atan()
	{
		this.min = Math.atan(this.min);
		this.max = Math.atan(this.max);
	}
}
