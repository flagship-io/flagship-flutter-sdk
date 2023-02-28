import 'package:flagship/model/flag.dart';

// This class represent the Flag object, manupulating this object allow to do
// - Getting the flag vlaue
// - Getting the metadata
// - Expose the flag
// - Check if the flag exist

class ExposedFlag<T> implements IFlag {
  // key of the flah
  final String _key;
  // Default value
  final T _defaultValue;
  // Value of the flag
  final T _value;
  // Metadata
  final FlagMetadata _metadata;

  ExposedFlag(this._key, this._value, this._defaultValue, this._metadata);

  T get value {
    return _value;
  }

  @override
  get defaultValue => _defaultValue;

  @override
  String get key => _key;

  @override
  FlagMetadata metadata() => _metadata;

  // Json representation
  Map<String, dynamic> toJson() {
    return {
      "Key": this.key,
      "value": this.value,
      "defaultValue": this.defaultValue,
      "metadata": this.metadata().toJson()
    };
  }
}
