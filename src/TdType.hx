package;

/**
 * @author YellowAfterlife
 */
enum TdType {
	TdUnknown; // [] -> TdArray<TdUnknown>
	TdNull;
	TdInt;
	TdFloat;
	TdBool;
	TdOpt(t:TdType); // Null<T>, for Bool|Int|Float
	TdString;
	TdGUID;
	TdArray(t:TdType);
	TdObject(d:TdObjectData);
	TdEither(a:TdType, b:TdType);
}
