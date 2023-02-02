import 'dart:convert';
import 'package:flagship/Storage/database_management.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';

//////////////////
///    HITS  /////
//////////////////
class DefaultCacheHitImp with IHitCacheImplementation {
  final DatabaseManagement dbMgt = DatabaseManagement();

  Future<void> _checkDatabase() async {
    if (dbMgt.isHDatabaseOpen == false) {
      Flagship.logger(Level.INFO, "initialize Database for cache hits");
      await dbMgt.openDb();
    }
  }

  @override
  void cacheHits(Map<String, Map<String, Object>> hits) async {
    Flagship.logger(
        Level.ALL, "Cache Hits from Default Cache Hit Implementation : \n");
    Flagship.logger(Level.ALL, JsonEncoder().convert(hits).toString(),
        isJsonString: true);
    await _checkDatabase();
    hits.forEach((key, value) {
      dbMgt.insertHitMap({'id': key, 'data_hit': jsonEncode(value)});
    });
  }

  @override
  void flushHits(List<String> hitIds) async {
    print("Flush Hits from Default cache Implementation $hitIds");
    await _checkDatabase();
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
    await _checkDatabase();
    return dbMgt.readHits("table_hits");
  }

  @override
  void flushAllHits() async {
    Flagship.logger(
        Level.DEBUG, "Flush all hits from default cache Implementation");
    await _checkDatabase();
    // Delete the file where we store the hits
    dbMgt.deleteAllRecord('table_hits');
  }
}

//////////////////
/// VISITOR  /////
//////////////////

class DefaultCacheVisitorImp with IVisitorCacheImplementation {
  final DatabaseManagement dbMgt = DatabaseManagement();

  DefaultCacheVisitorImp();

  Future<void> _checkDatabase() async {
    if (dbMgt.isVDatabaseOpen == false) {
      Flagship.logger(Level.INFO, "initialize Database for cache visitor");
      await dbMgt.openDb();
    }
  }

  @override
  void cacheVisitor(String visitorId, String jsonString) async {
    Flagship.logger(
        Level.DEBUG, "cacheVisitor from default cache Implementation");
    await _checkDatabase();
    dbMgt.insertVisitorData({"id": visitorId, "visitor": jsonString});
  }

  @override
  void flushVisitor(String visitorId) async {
    Flagship.logger(
        Level.DEBUG, "flushVisitor from default cache Implementation");
    await _checkDatabase();
    dbMgt.deleteVisitorWithId(visitorId, 'table_visitors');
  }

  @override
  Future<String> lookupVisitor(String visitoId) async {
    Flagship.logger(
        Level.DEBUG, "lookupVisitor from default cache Implementation ");
    await _checkDatabase();
    return dbMgt.readVisitor(visitoId, 'table_visitors');
  }
}
