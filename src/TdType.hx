package;

/**
 * @author YellowAfterlife
 */
enum TdType {
	TdUnknown; // [] -> TdArray<TdUnknown>
	TdNull;
	TdInt;
	TdFloat;
	TdString;
	TdBool;
	TdOpt(t:TdType); // Null<T>, for Bool|Int|Float
	TdArray(t:TdType);
	TdObject(d:TdObjectData);
	TdEither(a:TdType, b:TdType);
}
