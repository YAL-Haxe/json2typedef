package;
import TdType;
import TdType.*;

/**
 * ...
 * @author YellowAfterlife
 */
class TdTypeTools {
	public static function equals(a:TdType, b:TdType):Bool {
		if (a.getIndex() != b.getIndex()) return false;
		return switch ([a, b]) {
			case [TdUnknown, TdUnknown]: true;
			case [TdNull, TdNull]: true;
			case [TdInt, TdInt]: true;
			case [TdFloat, TdFloat]: true;
			case [TdBool, TdBool]: true;
			case [TdString, TdString]: true;
			case [TdOpt(pa), TdOpt(pb)]: equals(pa, pb);
			case [TdArray(pa), TdArray(pb)]: equals(pa, pb);
			case [TdObject(ad), TdObject(bd)]: {
				for (fd in ad.fieldList) {
					if (!bd.fieldTypes.exists(fd)) return false;
					if (!equals(ad.fieldTypes[fd], bd.fieldTypes[fd])) return false;
				}
				for (fd in bd.fieldList) {
					if (!ad.fieldTypes.exists(fd)) return false;
				}
				true;
			};
			case [TdEither(a1, a2), TdEither(b1, b2)]: {
				(equals(a1, b1) && equals(a2, b2)) || (equals(a1, b2) && equals(a2, b1));
			};
			default: throw 'Can\'t compare $a to $b';
		};
	}
	/** Returns whether a covers b */
	public static function includes(a:TdType, b:TdType):Bool {
		if (equals(a, b)) return true;
		return switch (a) {
			case TdEither(a1, a2): includes(a1, b) || includes(a2, b);
			default: false;
		}
	}
	public static function unify(a:TdType, b:TdType):TdType {
		// [TdSome, TdSome]?
		if (a.getIndex() == b.getIndex() && a.getParameters().length == 0) return a;
		
		// null goes first, for convenience
		switch (b) {
			case TdNull, TdOpt(_): {
				var t = a;
				a = b;
				b = t;
			};
			default:
		}
		
		//
		return switch ([a, b]) {
			case [TdUnknown, t], [t, TdUnknown]: t;
			
			// optional numeric
			case [TdNull, t = TdInt | TdFloat | TdBool]: TdOpt(t);
			
			// ints are valid floats
			case [TdInt, TdFloat], [TdFloat, TdInt]: TdFloat;
			case [TdOpt(TdInt), t = TdOpt(TdFloat)], [t = TdOpt(TdFloat), TdOpt(TdInt)]: t;
			
			// already nullable
			case [TdNull, t = TdString | TdOpt(_) | TdArray(_) | TdObject(_)]: t;
			
			// [?number, object] -> either<number, object>
			case [TdOpt(t), TdString | TdArray(_) | TdObject(_)]: {
				TdEither(t, b);
			};
			
			case [TdOpt(a), b = TdInt | TdFloat | TdBool]: {
				if (a.getIndex() != b.getIndex()) {
					TdOpt(unify(a, b));
				} else TdOpt(a); // [?Int, Int] -> Int
			};
			
			case [TdArray(ap), TdArray(bp)]: TdArray(unify(ap, bp));
			
			case [TdObject(ad), TdObject(bd)]: {
				var rd = new TdObjectData();
				for (fd in ad.fieldList) {
					if (bd.fieldTypes.exists(fd)) {
						rd.set(fd, unify(ad.fieldTypes[fd], bd.fieldTypes[fd]));
					} else rd.set(fd, ad.fieldTypes[fd], true);
				}
				for (fd in bd.fieldList) if (!ad.fieldTypes.exists(fd)) {
					rd.set(fd, bd.fieldTypes[fd], true);
				}
				TdObject(rd);
			};
			
			//
			default: {
				if (includes(a, b)) {
					a;
				} else if (includes(b, a)) {
					b;
				} else {
					TdEither(a, b);
				}
			};
		}
	}
}