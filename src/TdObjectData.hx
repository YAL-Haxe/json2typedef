package;

/**
 * ...
 * @author YellowAfterlife
 */
class TdObjectData {
	public var fieldList:Array<String> = [];
	public var fieldTypes:Map<String, TdType> = new Map();
	public var fieldOpt:Map<String, Bool> = new Map();
	public function new() {
		
	}
	public function set(field:String, type:TdType, opt:Bool = false) {
		if (!fieldTypes.exists(field)) fieldList.push(field);
		fieldTypes[field] = type;
		if (opt) fieldOpt[field] = true;
	}
}