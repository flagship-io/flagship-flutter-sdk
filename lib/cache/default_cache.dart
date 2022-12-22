import 'dart:convert';
import 'package:flagship/Storage/storage_managment.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';

//////////////////
///    HITS  /////
//////////////////
// Todo , refractor the opening db
class DefaultCacheHitImp with IHitCacheImplementation {
  final DataBaseManagment dbMgt = DataBaseManagment();

  DefaultCacheHitImp();

  @override
  void cacheHits(Map<String, Map<String, Object>> hits) async {
    Flagship.logger(
        Level.ALL, "Cache Hits from Default Cache Hit Implementation : \n");
    Flagship.logger(Level.ALL, JsonEncoder().convert(hits).toString(),
        isJsonString: true);
    await dbMgt.openDb(); // refracto this line
    hits.forEach((key, value) {
      dbMgt.insertHitMap({'id': key, 'data_hit': value});
    });
  }

  @override
  void flushHits(List<String> hitIds) async {
    print("Flush Hits from Default cache Implementation $hitIds");
    hitIds.forEach((element) {
      dbMgt.deleteHitWithId(element).whenComplete(() {
        print(
            " &&&&&&&&&& The hit with id = $element is removed from data base &&&&&&&&&&&&&&");
      });
    });
  }

  @override
  Future<List<Map>> lookupHits() async {
    print("lookupHits Hit from Default cache Implementation");
    return dbMgt.readHits("table_hits");
  }

  @override
  void flushAllHits() {
    print("Flush all hits from Default cache Implementation");
    // Delete the file where we store the hits
    dbMgt.deleteAllRecord();
  }
}

//////////////////
/// VISITOR  /////
//////////////////

class DefaultCacheVisitorImp with IVisitorCacheImplementation {
  const DefaultCacheVisitorImp();
  @override
  void cacheVisitor(String visitorId, String jsonString) {
    print("cacheVisitor from default cache visitor");
  }

  @override
  void flushVisitor(String visitorId) {
    print("flushVisitor from default cache");
  }

  @override
  String lookupVisitor(String visitoId) {
    print('lookupVisitor from default cache visitor');
    return {}.toString();
  }
}

// "/Users/adel/Library/Developer/CoreSimulator/Devices/3CC5A686-64FF-4091-B733-0548518FCB6B/data/Containers/Data/Application/74876BC8-1621-4EDA-916C-F6A10E46D125/Documents/flagship/cache/hits/visitorId"
