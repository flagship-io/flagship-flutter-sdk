import 'dart:collection';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';

// Queue for the hits
class FlagshipPoolQueue {
  // Queue for basehit
  Queue<Hit> fsQueue = Queue();

  FlagshipPoolQueueDelegate? delegate;

  final sizelimitation;

  FlagshipPoolQueue(this.sizelimitation);

  void addTrackElement(Hit newHit) {
    // Set id for the hit
    newHit.id = newHit.visitorId + "_" + FlagshipTools.generateUuidv4();
    // Add hit to queue
    fsQueue.add(newHit);
    // check the limitation
    if (fsQueue.length == sizelimitation) {
      Flagship.logger(Level.DEBUG,
          "The size max for the pool hit is reached, no need to wait for interval time to send the batch ......");
      this.delegate?.onPoolSizeMaxReached();
    }
  }

// Add elements to the bottom
  void addListOfElements(List<Hit> list) {
    list.forEach((element) {
      fsQueue.add(element);
    });
  }

  // remove track elements
  void removeTrackElement(String id) {
    fsQueue.removeWhere((element) {
      return (element.id == id);
    });
  }

  // Clear all the hit in the queue
  List<String> flushTrackQueue({bool flushingConsentHits = false}) {
    List<String> ret = [];
    if (flushingConsentHits == true) {
      Flagship.logger(
          Level.DEBUG, "Remove hits from the pool excpet the consent tracking");
      fsQueue.removeWhere((element) {
        if (element.type != HitCategory.CONSENT) {
          ret.add(element.id);
          return true;
        }
        return false;
      });
    } else {
      Flagship.logger(Level.DEBUG, "Remove all hits from the pool");
      fsQueue.clear();
    }
    return ret;
  }

  /// Extract the hits // Hits must be deleted from the pool (expect the Consent type ones).
  void removeHitsForVisitorId(String visitorId) {
    fsQueue.removeWhere((element) {
      return ((element.visitorId == visitorId ||
              element.anonymousId == visitorId) &&
          element.type != HitCategory.CONSENT);
    });
  }

  /// Extract the X first elements
  List<Hit> extractXElementFromQueue(int xElem) {
    List<Hit> result = [];
    for (int i = 0; i < xElem && fsQueue.isNotEmpty; i++) {
      result.add(fsQueue.removeFirst());
    }
    return result;
  }

  /// Extract the hits relative to visitor
  List<Hit> extractHitsWithVisitorId(String visitorId) {
    return fsQueue.where((element) {
      return (element.visitorId == visitorId);
    }).toList();
  }

  // Get the ids for all the  hits in the actual pool

  List<String> getAllIds() {
    List<String> result = [];
    fsQueue.forEach((element) {
      result.add(element.id);
    });
    return result;
  }

  bool isEmpty() {
    return fsQueue.isEmpty;
  }

  // Convert a list of hits to Map<id, hit.body>
  // id represent the id for the hit
  // hit body represent all hit's information
  Map<String, Map<String, Object>> hitsFromListToMap(List<Hit> list) {
    Map<String, Map<String, Object>> result = {};
    list.forEach((element) {
      result.addEntries({element.id: element.bodyTrack}.entries);
    });
    return result;
  }

  // Convert a list of map(hit) to list of hits

  List<BaseHit> listHitsFromMap(List<Map> listOfMap) {
    List<BaseHit> result = [];

    listOfMap.forEach((element) {});

    return result;
  }
}

mixin FlagshipPoolQueueDelegate {
  void onPoolSizeMaxReached();
}
