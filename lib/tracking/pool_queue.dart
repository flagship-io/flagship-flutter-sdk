import 'dart:collection';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';

/// Queue for the hits
class FlagshipPoolQueue {
  // Queue for basehit
  Queue<Hit> fsQueue = Queue();

  FlagshipPoolQueueDelegate? delegate;

  final sizelimitation;

  FlagshipPoolQueue(this.sizelimitation) {
    /// Remove later
    // for (int i = 0; i < 100; i++) {
    //   Event fakeEvent = Event(action: "fake_+$i", category: EventCategory.Action_Tracking);
    //   fakeEvent.id = FlagshipTools.generateUuidv4();
    //   fsQueue.add(fakeEvent);
    // }
  }

  void addTrackElement(Hit newHit) {
    // Set id for the hit
    switch (newHit.type) {
      case HitCategory.CONSENT:
        newHit.id = newHit.visitorId + "_GRPD:" + FlagshipTools.generateUuidv4();
        break;
      default:
        newHit.id = newHit.visitorId + ":" + FlagshipTools.generateUuidv4();
    }
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
  void addListOfElementsToTheBottom(List<Hit> list) {
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

  /// Clear all the hit in the queue
  void flushTrackQueue({bool flushingConsentHits = false}) {
    if (flushingConsentHits == true) {
      Flagship.logger(Level.DEBUG, "Remove hits from the pool excpet the consent tracking");
      fsQueue.removeWhere((element) => !element.id.contains("GRPD"));
    } else {
      Flagship.logger(Level.DEBUG, "Remove all hits from the pool");
      fsQueue.clear();
    }
  }

  /// Extract the hits // Hits must be deleted from the pool (expect the Consent type ones).
  void removeHitsForVisitorId(String visitorId) {
    fsQueue.removeWhere((element) {
      return (element.visitorId == visitorId && element.type != HitCategory.CONSENT);
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

  bool isEmpty() {
    return fsQueue.isEmpty;
  }
}

mixin FlagshipPoolQueueDelegate {
  void onPoolSizeMaxReached();
}
