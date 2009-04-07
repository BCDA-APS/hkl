public enum Hkl.UnitType{
	ANGLE_DEG,
	ANGLE_RAD,
	LENGTH_NM
}

const Hkl.Unit hkl_unit_angle_deg = {Hkl.UnitType.ANGLE_DEG, "Degree", "°"};
const Hkl.Unit hkl_unit_angle_rad = {Hkl.UnitType.ANGLE_RAD, "Radian", ""};
const Hkl.Unit hkl_unit_length_nm = {Hkl.UnitType.LENGTH_NM, "Nano Meter", "nm"};

public struct Hkl.Unit {
	Hkl.UnitType type;
	weak string name;
	weak string repr;

	public double factor(Hkl.Unit unit)
	{
		double factor = 1.0;

		switch(this.type){
			case Hkl.UnitType.ANGLE_DEG:
				switch(unit.type){
					case Hkl.UnitType.ANGLE_DEG:
						break; 
					case Hkl.UnitType.ANGLE_RAD:
						factor = Hkl.DEGTORAD;
						break;
					case Hkl.UnitType.LENGTH_NM:
						factor = double.NAN;
						break;
				}
				break;
			case Hkl.UnitType.ANGLE_RAD:
				switch(unit.type){
					case Hkl.UnitType.ANGLE_DEG:
						factor = Hkl.RADTODEG;
						break; 
					case Hkl.UnitType.ANGLE_RAD:
						break;
					case Hkl.UnitType.LENGTH_NM:
						factor = double.NAN;
						break;
				}
				break;
			case Hkl.UnitType.LENGTH_NM:
				switch(unit.type){
					case Hkl.UnitType.ANGLE_DEG:
						factor = double.NAN;
						break; 
					case Hkl.UnitType.ANGLE_RAD:
						factor = double.NAN;
						break;
					case Hkl.UnitType.LENGTH_NM:
						break;
				}
				break;
		}
		return factor;
	}
}
