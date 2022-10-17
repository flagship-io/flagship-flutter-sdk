import 'dart:collection';

import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/event.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/flagship_tools.dart';

/// Queue for the hits
class FlagshipPoolQueue {
  // Queue for basehit
  Queue<Hit> fsQueue = Queue();

  FlagshipPoolQueue() {
    /// Remove later
    // for (int i = 0; i < 100; i++) {
    //   Event fakeEvent = Event(action: "fake_+$i", category: EventCategory.Action_Tracking);
    //   fakeEvent.id = FlagshipTools.generateUuidv4();
    //   fsQueue.add(fakeEvent);
    // }
  }

  void addTrackElement(Hit newHit) {
    // Set id for the hit
    newHit.id = newHit.visitorId + ":" + FlagshipTools.generateUuidv4();
    fsQueue.add(newHit);
  }

// Add elements to the bottom
  void addListOfElementsToTheBottom(List<Hit> list) {
    list.forEach((element) {
      fsQueue.addLast(element);
    });
  }

  // remove track elements
  void removeTrackElement(String id) {
    fsQueue.removeWhere((element) {
      return (element.id == id);
    });
  }

  /// Clear all the hit in the queue
  void flushTrackQueue() {
    fsQueue.clear();
  }

  /// Extract the hits // Hits must be deleted from the pool (expect the Consent type ones).
  void removeHitsForVisitorId(String visitorId) {
    fsQueue.removeWhere((element) {
      return (element.visitorId == visitorId && element.type != Type.CONSENT);
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
