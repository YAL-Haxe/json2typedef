# json2typedef
Web version: https://yal.cc/r/19/json2typedef/

This small tool takes samples of JSON and generates Haxe typedef code for them.

Primarily intended for cases where you need to write a properly typed typedef but there's no schema for input JSON.

The tool will attempt to unify types when given multiple samples via arrays (e.g. `[4,null]` is `Null<Int>`).

## Limitations

- May get confused by overly complex expressions to unify.
- Fields must be valid Haxe identifiers (see https://github.com/HaxeFoundation/haxe/issues/5105).

## Credits & License

Tool by [YellowAfterlife](https://yal.cc).

Parser is based on Haxe's standard library JSON parser (MIT license).

Licensed under MIT.
