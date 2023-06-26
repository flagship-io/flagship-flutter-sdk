import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/event.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/hits/item.dart';
import 'package:flagship/hits/page.dart';
import 'package:flagship/hits/screen.dart';
import 'package:flagship/hits/transaction.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/model/visitor_cache/campaign_cache.dart';
import 'package:flagship/model/visitor_cache/data.dart';
import 'package:flagship/model/visitor_cache/visitor_cache.dart';
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
  static Map<String, Map<String, Object>> hitsToMap(List<Hit> listOfHits) {
    Map<String, Map<String, Object>> result = {};
    listOfHits.forEach((element) {
      result.addEntries({element.id: element.bodyTrack}.entries);
    });
    return result;
  }

  // Convert the list comming from DB to list of hit
  static List<BaseHit> converMapToListOfHits(List<Map> list) {
    List<BaseHit> result = [];
    list.forEach((element) {
      Map subMap = jsonDecode(element['data_hit']);
      switch (subMap['t']) {
        case 'SCREENVIEW':
          result.add(Screen.fromMap(element['id'], subMap));
          break;
        case 'PAGEVIEW':
          result.add(Page.fromMap(element['id'], subMap));
          break;
        case 'EVENT':
          result.add(Event.fromMap(element['id'], subMap));
          break;
        case 'TRANSACTION':
          result.add(Transaction.fromMap(element['id'], subMap));
          break;
        case 'ITEM':
          result.add(Item.fromMap(element['id'], subMap));
          break;
        case 'ACTIVATE':
          result.add(Activate.fromMap(element['id'], subMap));
          break;
        default:
          Flagship.logger(
              Level.ERROR, "Error on convert Map hit to object hits ");
          break;
      }
    });
    return result;
  }

  Future<List<Map>> readJsonFile(String filePath) async {
    var input = await File(filePath).readAsString();
    var map = jsonDecode(input);
    return map;
  }

  // Create a visitorCache from the response
  static VisitorCache createVisitorCache(
      {required String visitorId,
      required Map<String, dynamic> context,
      required bool consent,
      required String? anonymId,
      required Map<String, Modification> modifications}) {
    Data cachedData = Data(
        visitorId: visitorId,
        context: context,
        anonymousId: anonymId,
        consent: consent);

    VisitorCache cachedVisitor = VisitorCache(version: 1, data: cachedData);

    List<CampaignCache> listCampCache = [];
    modifications.forEach((key, modificationItem) {
      // should create a new campignCache
      CampaignCache newCampCache = listCampCache.firstWhere(
          (element) => (element.variationId == modificationItem.variationId),
          orElse: () {
        return CampaignCache.fromModification(modificationItem);
      });

      if (newCampCache.flags == null) {
        newCampCache.flags = Map.from({key: modificationItem.value});
        listCampCache.add(newCampCache);
      } else {
        newCampCache.updateFlags({key: modificationItem.value});
      }
      // Add the new campaign cache
    });
    cachedVisitor.data?.campaigns = listCampCache;
    return cachedVisitor;
  }
}
