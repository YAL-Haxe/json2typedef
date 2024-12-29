package;

import haxe.Http;
import js.Browser;
import js.Lib;
import js.html.Element;
import js.html.InputElement;
import js.html.TextAreaElement;

/**
 * ...
 * @author YellowAfterlife
 */
class Main {
	static inline function find<T:Element>(id:String):T {
		return cast Browser.document.getElementById(id);
	}
	static function main() {
		var input:TextAreaElement = find("input");
		var output:TextAreaElement = find("output");
		var useVar:InputElement = find("usevar");
		var tabSize:InputElement = find("tabsize");
		var allFloat:InputElement = find("allfloat");
		var isYY:InputElement = find("as-yy");
		function proc() {
			try {
				var t = TdParser.parse(input.value);
				output.value = TdPrinter.print(t, {
					useVar: useVar.checked,
					allFloat: allFloat.checked,
					indentSize: Std.parseInt(tabSize.value),
					isYY: isYY.checked,
				});
			} catch (x:Dynamic) {
				output.value = x;
			}
		}
		input.onchange = function(_) proc();
		for (el in [useVar, tabSize, allFloat]) {
			el.onchange = function(_) { proc(); return false; }
		}
		#if (debug && js)
		var req = new Http("test.json");
		req.onData = function(s:String) {
			input.value = s;
			proc();
		}
		req.request();
		#end
	}
	
}