import 'dart:collection';

import 'package:flagship/model/flag.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/visitor.dart';

extension on Visitor {}

class FSFlagCollection {
  Map<String, Flag> flags = {};

  // Constructor
  FSFlagCollection({required this.flags});

  // Iterator
  Iterator<MapEntry<String, Flag>> makeIterator() {
    return flags.entries.iterator;
  }

  // Subscript (using operator overloading)
  Flag operator [](String key) {
    return flags[key] ?? Flag(key, null);
  }

  void operator []=(String key, Flag newValue) {
    flags[key] = newValue;
  }

  // Filtering
  FSFlagCollection filter(bool Function(String, Flag) isIncluded) {
    var filteredFlags =
        flags.entries.where((entry) => isIncluded(entry.key, entry.value));
    var newFlags = {for (var entry in filteredFlags) entry.key: entry.value};
    return FSFlagCollection(flags: newFlags);
  }

  void forEach(void action(String key, Flag value)) {
    this.flags.forEach(action);
  }

  // Keys
  Iterable<String> keys() {
    return flags.keys;
  }

  // Metadatas
  List<FlagMetadata> metadatas() {
    return flags.values.map((value) => value.metadata()).toList();
  }

  // Convert to JSON
  String toJson() {
    // List<Map<String, Flag>> arrayOfJson = [];
    // flags.forEach((key, value) {
    //   String hexString = "";
    //   var modif = value.  ?.getStrategy().getFlagModification(value.key);
    //   if (modif != null) {
    //     Map<String, dynamic> hexDico = {"v": modif.value};
    //     hexString = jsonEncode(
    //         hexDico); // Assuming hexEncodedString() is not required here
    //     arrayOfJson
    //         .add(FSExtraMetadata(modif, value.key, hex: hexString).toJson());
    //   }
    // });
    // if (arrayOfJson.isNotEmpty) {
    //   return jsonEncode(arrayOfJson);
    // }
    return "";
  }

  // Expose all
  void exposeAll() {
    flags.forEach((key, value) {
      value.visitorExposed();
    });
  }

  // Count
  int get count => flags.length;

  // Is empty
  bool get isEmpty => flags.isEmpty;
}
