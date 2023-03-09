import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/hit.dart';

class Batch extends BaseHit {
  final List<Hit> listOfHits;

  Batch(this.listOfHits) {
    super.visitorId = listOfHits.first.visitorId;
  }

  // Special hit for batch
  HitCategory type = HitCategory.BATCH;

  // Body to send through the batch script
  Map<String, Object> get bodyTrack {
    var batchEvent = new Map<String, Object>();
    batchEvent.addEntries({
      "t": "BATCH",
      "ds": "APP",
    }.entries);
    List<Map<String, Object>> ret = [];
    this.listOfHits.forEach((element) {
      ret.add(element.bodyTrack);
    });
    batchEvent.addEntries({"h": ret}.entries);
    return batchEvent;
  }

  @override
  bool isValid() {
    return true;
  }
}

/////////////////////////////////////
//
//       Batch for Activate
//
/////////////////////////////////////

class ActivateBatch {
  //final List<Hit> batch;
  final List<Hit> batch;
  String envId = "";

  ActivateBatch(this.batch) {
    envId = (batch.first as Activate).envId;
  }

  Map<String, Object> toJson() {
    List<Map<String, Object>> ret = [];
    batch.forEach((element) {
      // Remove the cid from the activate json
      var elem = (element as Activate).toJson();
      elem.remove("cid");
      ret.add(elem);
    });
    return {"cid": envId, "batch": ret};
  }
}
