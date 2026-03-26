import 'package:flagship/model/flag.dart';

// This class represent the Flag object, manupulating this object allow to do
// - Getting the flag vlaue
// - Getting the metadata
// - Expose the flag
// - Check if the flag exist

class ExposedFlag<T> implements IFlag {
  // key of the flag
  final String _key;
  // Default value
  final T _defaultValue;
  // Value of the flag
  final T _value;
  // Metadata
  final FlagMetadata _metadata;
  // If flag is already activated
  bool alreadyActivatedCampaign = false;

  ExposedFlag(this._key, this._value, this._defaultValue, this._metadata,
      {bool alreadyActivatedCampaign = false});

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
      "key": this.key,
      "value": this.value,
      "defaultValue": this.defaultValue,
      "metadata": this.metadata().toJson(),
      "alreadyActivatedCampaign": this.alreadyActivatedCampaign
    };
  }
}
