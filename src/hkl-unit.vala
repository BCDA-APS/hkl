/* This file is part of the hkl library.
 *
 * The hkl library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * The hkl library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with the hkl library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Copyright (C) 2003-2009 Synchrotron SOLEIL
 *                         L'Orme des Merisiers Saint-Aubin
 *                         BP 48 91192 GIF-sur-YVETTE CEDEX
 *
 * Authors: Picca Frédéric-Emmanuel <picca@synchrotron-soleil.fr>
 */
public enum Hkl.UnitType{
	ANGLE_DEG,
	ANGLE_RAD,
	LENGTH_NM
}

public const Hkl.Unit hkl_unit_angle_deg = {Hkl.UnitType.ANGLE_DEG, "Degree", "°"};
public const Hkl.Unit hkl_unit_angle_rad = {Hkl.UnitType.ANGLE_RAD, "Radian", ""};
public const Hkl.Unit hkl_unit_length_nm = {Hkl.UnitType.LENGTH_NM, "Nano Meter", "nm"};

public struct Hkl.Unit {
	public Hkl.UnitType type;
	public weak string name;
	public weak string repr;

	public Unit(UnitType type, string name, string repr)
	{
		this.type = type;
		this.name = name;
		this.repr = repr;
	}

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
