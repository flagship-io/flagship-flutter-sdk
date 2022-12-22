import 'dart:math';

import 'package:flagship/hits/hit.dart';
import 'package:intl/intl.dart';
import '../flagship.dart';
import 'logger/log_manager.dart';
import 'package:uuid/uuid.dart';

// length for the envId
const int LengthId = 20;
// pattern for envId
const String xidPattren = "[0-9a-v]{20}";

class FlagshipTools {
  static bool chekcXidEnvironment(String xid) {
    // create RegExp with pattern
    RegExp xidReg = RegExp(xidPattren);
    if (xid.length == LengthId && xidReg.hasMatch(xid)) {
      return true;
    } else {
      Flagship.logger(Level.INFO, "The environmentId : \(xid) is not valide ");
      return false;
    }
  }

  static generateFlagshipId() {
    int min = 10000;
    int max = 99999;
    // Set format
    final format = new DateFormat('yyyyMMddhhmss');
    // Return the uuid
    return format.format(DateTime.now()) +
        (min + Random().nextInt(max - min)).toString();
  }

  static generateUuidv4() {
    return Uuid().v4();
  }

  // Convert a list of hits to Map<id, hit.body>
  // id represent the id for the hit
  // hit body represent all hit's information
  static Map<String, Map<String, Object>> hitsToMap(List<BaseHit> listOfHits) {
    Map<String, Map<String, Object>> result = {};
    listOfHits.forEach((element) {
      result.addEntries({element.id: element.bodyTrack}.entries);
    });
    return result;
  }

  // Convert the list of Map to list of hit
  static List<BaseHit> converMapHitsToListHit(List<Map> list) {
    List<BaseHit> result = [];

    list.forEach((element) {
      Map subMap = element['data_hit'];
     switch (HsubMap['t']){

      case 'SCREENVIEW'
      break;
     }
      print(element['data_hit']);
    });
    return result;
  }
}
