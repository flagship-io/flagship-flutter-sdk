import 'dart:convert';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/visitor/visitor_delegate.dart';

class FSFlagCollection {
  final VisitorDelegate _visitorDelegate;

  Map<String, Flag> _flags = {};

  // Constructor
  FSFlagCollection(this._visitorDelegate, this._flags);

  // Iterator
  Iterator<MapEntry<String, Flag>> makeIterator() {
    return _flags.entries.iterator;
  }

  // Subscript (using operator overloading)
  Flag operator [](String key) {
    return _flags[key] ?? Flag(key, null);
  }

  void operator []=(String key, Flag newValue) {
    _flags[key] = newValue;
  }

  // Filtering
  FSFlagCollection filter(bool Function(String, Flag) isIncluded) {
    var filteredFlags =
        _flags.entries.where((entry) => isIncluded(entry.key, entry.value));
    var newFlags = {for (var entry in filteredFlags) entry.key: entry.value};
    return FSFlagCollection(this._visitorDelegate, newFlags);
  }

  void forEach(void action(String key, Flag value)) {
    this._flags.forEach(action);
  }

  // Keys
  Iterable<String> keys() {
    return _flags.keys;
  }

  // Metadatas
  List<FlagMetadata> metadatas() {
    return _flags.values.map((value) => value.metadata()).toList();
  }

  // Convert to JSON
  String toJson() {
    List<Map<String, dynamic>> arrayOfJson = [];
    _flags.forEach((key, value) {
      ExtraMetadata? item = _getExtraMetadata(value);
      if (item != null) {
        arrayOfJson.add(item.tojson());
      }
    });
    if (arrayOfJson.isNotEmpty) {
      return jsonEncode(arrayOfJson);
    }
    return "";
  }

  // Expose all
  void exposeAll() {
    _flags.forEach((key, value) {
      value.visitorExposed();
    });
  }

  // Count
  int get count => _flags.length;

  // Is empty
  bool get isEmpty => _flags.isEmpty;

  ExtraMetadata? _getExtraMetadata(Flag flag) {
    Modification? modif = this._visitorDelegate.getFlagModification(flag.key);
    if (modif != null) {
      // Define the encoded map
      var encodedMap = jsonEncode({"v": modif.value});
      // Return the extra meta data
      return ExtraMetadata(
          flag.key, FlagshipTools.stringToHex(encodedMap), flag.metadata());
    }
    return null;
  }
}

class ExtraMetadata {
  String key = "";
  String hex = "";
  FlagMetadata metadata;

  ExtraMetadata(this.key, this.hex, this.metadata);

  Map<String, dynamic> tojson() {
    Map<String, dynamic> ret = {};
    // Add value
    ret.addEntries({"key": this.key}.entries);
    // Add key
    ret.addEntries({"hex": this.hex}.entries);
    // Add Entrie for metedata
    ret.addEntries(this.metadata.toJson().entries);
    return ret;
  }
}
