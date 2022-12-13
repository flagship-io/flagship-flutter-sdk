import 'dart:convert';
import 'package:flagship/Storage/storage_managment.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';

//////////////////
///    HITS  /////
//////////////////

class DefaultCacheHitImp with IHitCacheImplementation {
  const DefaultCacheHitImp();

  @override
  void cacheHits(Map<String, Map<String, Object>> hits) {
    Flagship.logger(
        Level.ALL, "Cache Hits from Default Cache Hit Implementation : \n");
    Flagship.logger(Level.ALL, JsonEncoder().convert(hits).toString(),
        isJsonString: true);

    StorageManagment.storeJson(
        JsonEncoder().convert(hits).toString(), "visitorId.json");
  }

  @override
  void flushHits(List<String> hitIds) {
    print("Flush Hit from Default cache Implementation");
  }

  @override
  Map<String, JsonCodec> lookupHits() {
    print("lookupHits Hit from Default cache Implementation");
    return {};
  }

  @override
  void flushAllHits() {
    print("Flush all hits from Default cache Implementation");
  }
}

//////////////////
/// VISITOR  /////
//////////////////

class DefaultCacheVisitorImp with IVisitorCacheImplementation {
  const DefaultCacheVisitorImp();
  @override
  void cacheVisitor(String visitorId, JsonCodec data) {
    // TODO: implement cacheVisitor
  }

  @override
  void flushVisitor(String visitorId) {
    // TODO: implement flushVisitor
  }

  @override
  JsonCodec lookupVisitor(String visitoId) {
    // TODO: implement lookupVisitor
    throw UnimplementedError();
  }
}


// "/Users/adel/Library/Developer/CoreSimulator/Devices/3CC5A686-64FF-4091-B733-0548518FCB6B/data/Containers/Data/Application/74876BC8-1621-4EDA-916C-F6A10E46D125/Documents/flagship/cache/hits/visitorId"