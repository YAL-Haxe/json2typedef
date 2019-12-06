package;
import TdType.*;

/**
 * ...
 * @author YellowAfterlife
 */
class TdPrinter {
	static var useVar:Bool = false;
	static var allFloat:Bool = false;
	static function rec(type:TdType, indent:Int):String {
		return switch (type) {
			case TdNull, TdUnknown: "Any";
			case TdInt: allFloat ? "Float" : "Int";
			case TdFloat: "Float";
			case TdBool: "Bool";
			case TdString: "String";
			case TdOpt(t): "Null<" + rec(t, indent) + ">";
			case TdArray(t): "Array<" + rec(t, indent) + ">";
			case TdObject(d): {
				var ni = indent + 1;
				var r = "{";
				var sep = false;
				for (fd in d.fieldList) {
					if (sep) r += ","; else sep = true;
					r += "\n";
					for (_ in 0 ... ni) r += "\t";
					if (d.fieldOpt[fd]) r += "?";
					if (useVar) r += "var ";
					r += fd + ":" + rec(d.fieldTypes[fd], ni);
				}
				if (sep) {
					r += "\n";
					for (_ in 0 ... indent) r += "\t";
				}
				r + "}";
			};
			case TdEither(a, b): "EitherType<" + rec(a, indent) + ", " + rec(b, indent) + ">";
		}
	}
	public static function print(type:TdType, opt:TdPrinterOptions) {
		useVar = opt.useVar;
		allFloat = opt.allFloat;
		var result = rec(type, 0);
		var indentSize = opt.indentSize;
		if (indentSize != null && indentSize > 0) {
			result = ~/\t/g.replace(result, StringTools.lpad("", " ", indentSize));
		}
		return result;
	}
}
typedef TdPrinterOptions = {
	useVar:Bool,
	allFloat:Bool,
	indentSize:Int,
}