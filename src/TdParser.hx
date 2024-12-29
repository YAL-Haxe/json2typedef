package;
//import TdType.*;
import TdType;

/**
 * Sorry for bastardizing the Haxe Standard Library JSON parser... again
 * @author YellowAfterlife
 */
class TdParser {
	static public inline function parse(str : String) : TdType {
		return new TdParser(str).doParse();
	}
	
	#if js
	static var rxGUID = {
		var h = '[0-9a-fA-F]';
		new js.lib.RegExp('^$h{8}-$h{4}-$h{4}-$h{4}-$h{12}' + "$");
	}
	static inline function isGUID(s:String) {
		return rxGUID.test(s);
	}
	#else
	static var rxGUID = {
		var h = '[0-9a-fA-F]';
		new EReg('^$h{8}-$h{4}-$h{4}-$h{4}-$h{12}' + "$");
	};
	static inline function isGUID(s:String) {
		return rxGUID.match(s);
	}
	#end

	var str : String;
	var pos : Int;
	var out : StringBuf;
	var indent : Int;

	function new( str : String ) {
		this.str = str;
		this.pos = 0;
	}

	function doParse() : TdType {
		out = new StringBuf();
		indent = 0;
		var result = parseRec();
		var c;
		var oneComma = true;
		while( !StringTools.isEof(c = nextChar()) ) {
			switch( c ) {
				case ' '.code, '\r'.code, '\n'.code, '\t'.code:
					// allow trailing whitespace
				case ",".code if (oneComma):
					oneComma = false;
				default:
					invalidChar("trailing data");
			}
		}
		return result;
	}

	function parseRec() : TdType {
		while( true ) {
			var c = nextChar();
			switch( c ) {
			case ' '.code, '\r'.code, '\n'.code, '\t'.code:
				// loop
			case '{'.code:
				var field = null, comma : Null<Bool> = null;
				var rd = new TdObjectData();
				while( true ) {
					var c = nextChar();
					switch( c ) {
					case ' '.code, '\r'.code, '\n'.code, '\t'.code:
						// loop
					case '}'.code:
						// if( field != null || comma == false ) invalidChar(); // +y: allowed
						return TdObject(rd);
					case ':'.code:
						if( field == null )
							invalidChar("object: expected field");
						rd.set(field, parseRec());
						field = null;
						comma = true;
					case ','.code:
						if( comma ) comma = false else invalidChar("object: extra comma");
					case '"'.code:
						if( field != null || comma ) invalidChar("object: double key?");
						field = parseString();
					default:
						invalidChar("object (field:" + field + ", comma:" + comma + ")");
					}
				}
			case '['.code:
				var arr = [], comma : Null<Bool> = null;
				var result = TdUnknown;
				while( true ) {
					var c = nextChar();
					switch( c ) {
					case ' '.code, '\r'.code, '\n'.code, '\t'.code:
						// loop
					case ']'.code:
						// if( comma == false ) invalidChar(); // +y: allowed
						return TdArray(result);
					case ','.code:
						if( comma ) comma = false else invalidChar("array: extra comma");
					default:
						if( comma ) invalidChar("array: want comma");
						pos--;
						result = TdTypeTools.unify(result, parseRec());
						comma = true;
					}
				}
			case 't'.code:
				var save = pos;
				if( nextChar() != 'r'.code || nextChar() != 'u'.code || nextChar() != 'e'.code ) {
					pos = save;
					invalidChar("ident: not true!");
				}
				return TdBool;
			case 'f'.code:
				var save = pos;
				if( nextChar() != 'a'.code || nextChar() != 'l'.code || nextChar() != 's'.code || nextChar() != 'e'.code ) {
					pos = save;
					invalidChar("ident: not false!");
				}
				return TdBool;
			case 'n'.code:
				var save = pos;
				if( nextChar() != 'u'.code || nextChar() != 'l'.code || nextChar() != 'l'.code ) {
					pos = save;
					invalidChar("ident: not null!");
				}
				return TdNull;
			case '"'.code:
				var s = parseString();
				return isGUID(s) ? TdGUID : TdString;
			case '0'.code, '1'.code,'2'.code,'3'.code,'4'.code,'5'.code,'6'.code,'7'.code,'8'.code,'9'.code,'-'.code:
				return parseNumber(c);
			default:
				invalidChar("value?");
			}
		}
	}

	function parseString() {
		var start = pos;
		var buf:StringBuf = null;
		#if target.unicode
		var prev = -1;
		inline function cancelSurrogate() {
			// invalid high surrogate (not followed by low surrogate)
			buf.addChar(0xFFFD);
			prev = -1;
		}
		#end
		while( true ) {
			var c = nextChar();
			if( c == '"'.code )
				break;
			if( c == '\\'.code ) {
				if (buf == null) {
					buf = new StringBuf();
				}
				buf.addSub(str,start, pos - start - 1);
				c = nextChar();
				#if target.unicode
				if( c != "u".code && prev != -1 ) cancelSurrogate();
				#end
				switch( c ) {
				case "r".code: buf.addChar("\r".code);
				case "n".code: buf.addChar("\n".code);
				case "t".code: buf.addChar("\t".code);
				case "b".code: buf.addChar(8);
				case "f".code: buf.addChar(12);
				case "/".code, '\\'.code, '"'.code: buf.addChar(c);
				case 'u'.code:
					var uc:Int = Std.parseInt("0x" + str.substr(pos, 4));
					pos += 4;
					#if !target.unicode
					if( uc <= 0x7F )
						buf.addChar(uc);
					else if( uc <= 0x7FF ) {
						buf.addChar(0xC0 | (uc >> 6));
						buf.addChar(0x80 | (uc & 63));
					} else if( uc <= 0xFFFF ) {
						buf.addChar(0xE0 | (uc >> 12));
						buf.addChar(0x80 | ((uc >> 6) & 63));
						buf.addChar(0x80 | (uc & 63));
					} else {
						buf.addChar(0xF0 | (uc >> 18));
						buf.addChar(0x80 | ((uc >> 12) & 63));
						buf.addChar(0x80 | ((uc >> 6) & 63));
						buf.addChar(0x80 | (uc & 63));
					}
					#else
					if( prev != -1 ) {
						if( uc < 0xDC00 || uc > 0xDFFF )
							cancelSurrogate();
						else {
							buf.addChar(((prev - 0xD800) << 10) + (uc - 0xDC00) + 0x10000);
							prev = -1;
						}
					} else if( uc >= 0xD800 && uc <= 0xDBFF )
						prev = uc;
					else
						buf.addChar(uc);
					#end
				default:
					throw "Invalid escape sequence \\" + String.fromCharCode(c) + " at position " + (pos - 1);
				}
				start = pos;
			}
			#if !(target.unicode)
			// ensure utf8 chars are not cut
			else if( c >= 0x80 ) {
				pos++;
				if( c >= 0xFC ) pos += 4;
				else if( c >= 0xF8 ) pos += 3;
				else if( c >= 0xF0 ) pos += 2;
				else if( c >= 0xE0 ) pos++;
			}
			#end
			else if( StringTools.isEof(c) )
				throw "Unclosed string";
		}
		#if target.unicode
		if( prev != -1 )
			cancelSurrogate();
		#end
		if (buf == null) {
			return str.substr(start, pos - start - 1);
		}
		else {
			buf.addSub(str,start, pos - start - 1);
			return buf.toString();
		}
	}

	#if (!debug) inline #end
	function parseNumber( c : Int ) : TdType {
		var start = pos - 1;
		var minus = c == '-'.code, digit = !minus, zero = c == '0'.code;
		var point = false, e = false, pm = false, end = false;
		while( true ) {
			c = nextChar();
			switch( c ) {
				case '0'.code :
					if (zero && !point) invalidNumber(start);
					if (minus) {
						minus = false; zero = true;
					}
					digit = true;
				case '1'.code,'2'.code,'3'.code,'4'.code,'5'.code,'6'.code,'7'.code,'8'.code,'9'.code :
					if (zero && !point) invalidNumber(start);
					if (minus) minus = false;
					digit = true; zero = false;
				case '.'.code :
					if (minus || point || e) invalidNumber(start);
					digit = false; point = true;
				case 'e'.code, 'E'.code :
					if (minus || zero || e) invalidNumber(start);
					digit = false; e = true;
				case '+'.code, '-'.code :
					if (!e || pm) invalidNumber(start);
					digit = false; pm = true;
				default :
					if (!digit) invalidNumber(start);
					pos--;
					end = true;
			}
			if (end) break;
		}
		return point ? TdFloat : TdInt;
	}

	inline function nextChar() {
		return StringTools.fastCodeAt(str,pos++);
	}

	function invalidChar(ctx:String) {
		pos--; // rewind
		throw "Invalid char "+StringTools.fastCodeAt(str,pos)+" at position "+pos+", "+ctx;
	}

	function invalidNumber( start : Int ) {
		throw "Invalid number at position "+start+": " + str.substr(start, pos - start);
	}
}