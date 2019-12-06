package;
import TdType;
import TdType.*;

/**
 * ...
 * @author YellowAfterlife
 */
class TdTypeTools {
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
				TdEither(a, b);
				//throw 'Can\'t unify $a with $b';
			};
		}
	}
}