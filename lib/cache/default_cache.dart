import 'dart:convert';
import 'package:flagship/Storage/storage_managment.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';

//////////////////
///    HITS  /////
//////////////////
class DefaultCacheHitImp with IHitCacheImplementation {
  final DataBaseManagment dbMgt = DataBaseManagment();
  @override
  void cacheHits(Map<String, Map<String, Object>> hits) async {
    Flagship.logger(
        Level.ALL, "Cache Hits from Default Cache Hit Implementation : \n");
    Flagship.logger(Level.ALL, JsonEncoder().convert(hits).toString(),
        isJsonString: true);
    // await dbMgt.openDb();
    hits.forEach((key, value) {
      dbMgt.insertHitMap({'id': key, 'data_hit': jsonEncode(value)});
    });
  }

  @override
  void flushHits(List<String> hitIds) async {
    print("Flush Hits from Default cache Implementation $hitIds");
    hitIds.forEach((element) {
      dbMgt.deleteHitWithId(element, 'table_hits').whenComplete(() {
        Flagship.logger(
            Level.DEBUG, "The hit with an id = $element is removed from cache");
      });
    });
  }

  @override
  Future<List<Map>> lookupHits() async {
    Flagship.logger(
        Level.DEBUG, "lookupHits Hit from Default cache Implementation");
    await dbMgt.openDb();
    return dbMgt.readHits("table_hits");
  }

  @override
  void flushAllHits() {
    Flagship.logger(
        Level.DEBUG, "Flush all hits from default cache Implementation");
    // Delete the file where we store the hits
    dbMgt.deleteAllRecord('table_hits');
  }
}

//////////////////
/// VISITOR  /////
//////////////////

class DefaultCacheVisitorImp with IVisitorCacheImplementation {
  final DataBaseManagment dbMgt = DataBaseManagment();

  DefaultCacheVisitorImp();

  @override
  void cacheVisitor(String visitorId, String jsonString) async {
    Flagship.logger(
        Level.DEBUG, "cacheVisitor from default cache Implementation");
    dbMgt.insertVisitorData({"id": visitorId, "visitor": jsonString});
  }

  @override
  void flushVisitor(String visitorId) {
    Flagship.logger(
        Level.DEBUG, "flushVisitor from default cache Implementation");
    dbMgt.deleteVisitorWithId(visitorId, 'table_visitors');
  }

  @override
  Future<String> lookupVisitor(String visitoId) async {
    Flagship.logger(
        Level.DEBUG, "lookupVisitor from default cache Implementation ");
    await dbMgt.openDb();
    return dbMgt.readVisitor(visitoId, 'table_visitors');
  }
}
