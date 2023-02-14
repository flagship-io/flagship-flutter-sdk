import 'package:flagship/hits/event.dart';
import 'package:flagship/tracking/Batching/pool_queue.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

FlagshipPoolQueue poolTest = FlagshipPoolQueue(80);

class MockFlagshipPoolQueueDelegate extends Mock
    implements FlagshipPoolQueueDelegate {
  @override
  void onPoolSizeMaxReached() {
    poolTest.fsQueue.clear();
  }
}

void main() {
  test("pool_queue", () async {
    poolTest.delegate = MockFlagshipPoolQueueDelegate();

    // create 100 hits
    for (int i = 0; i < 100; i++) {
      Event testEvent = Event(
          action: "testPool" + "$i", category: EventCategory.Action_Tracking);
      testEvent.visitorId = "user_" + "$i";
      poolTest.addNewTrackElement(testEvent);
      // check the creattion id after adding the hit in the pool
      expect(testEvent.id.contains(testEvent.visitorId), true);
    }
    // check the size limiation
    expect(poolTest.fsQueue.length, 20);

    var extractedList = poolTest.extractXElementFromQueue(20);

    // Check the axtraction length
    expect(extractedList.length, 20);

    // Check the empty
    expect(poolTest.isEmpty(), true);
  });

  test("removeWithvisitorId", () {
    // create 100 hits
    for (int i = 0; i < 20; i++) {
      Event testEvent = Event(
          action: "testPool" + "$i", category: EventCategory.Action_Tracking);
      testEvent.visitorId = "user_" + "$i";
      testEvent.anonymousId = null;
      poolTest.addNewTrackElement(testEvent);
      // check the creattion id after adding the hit in the pool
      expect(testEvent.id.contains(testEvent.visitorId), true);
    }

    var listWithVisitorId = poolTest.extractHitsWithVisitorId("user_10");

    // check length for the returned result
    expect(listWithVisitorId.length, 1);

    var hitElement = listWithVisitorId.first;

    // Check the visitor id for the extract
    expect(hitElement.visitorId, "user_10");
    // Check the pool length
    expect(poolTest.fsQueue.length, 20);
    poolTest.removeHitsForVisitorId("user_10");
    // Check the pool length
    expect(poolTest.fsQueue.length, 19);
  });

  test("flushPool", () {
    poolTest.flushAllTrackFromQueue();
    for (int i = 0; i < 100; i++) {
      Event testEvent = Event(
          action: "testPool" + "$i", category: EventCategory.Action_Tracking);
      testEvent.visitorId = "user_" + "$i";
      poolTest.addNewTrackElement(testEvent);
      // check the creattion id after adding the hit in the pool
      expect(testEvent.id.contains(testEvent.visitorId), true);
    }
    poolTest.flushAllTrackFromQueue();
    expect(poolTest.fsQueue.length, 0);
  });

  test("flushPoolWithConsent", () {
    poolTest.flushAllTrackFromQueue();
    for (int i = 0; i < 50; i++) {
      Event testEvent = Event(
          action: "testPool" + "$i", category: EventCategory.Action_Tracking);
      testEvent.visitorId = "userTest";
      poolTest.addNewTrackElement(testEvent);
    }

    // Create the consent one
    Consent consent = Consent(hasConsented: false);
    consent.visitorId = "userTest";
    poolTest.addNewTrackElement(consent);
    poolTest.flushTrackAndKeepConsent("userTest");
    expect(poolTest.fsQueue.length, 1);
    poolTest.flushAllTrackFromQueue();
    expect(poolTest.fsQueue.length, 0);
  });
}
