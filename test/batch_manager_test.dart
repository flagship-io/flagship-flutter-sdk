import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/hits/Page.dart';
import 'package:flagship/hits/event.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/hits/item.dart';
import 'package:flagship/hits/screen.dart';
import 'package:flagship/hits/transaction.dart';
import 'package:flagship/tracking/Batching/batch_manager.dart';
import 'package:flagship/tracking/Batching/pool_queue.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flutter_test/flutter_test.dart';

bool called = false;

void sendBatchTest(List<Hit> listToSend) {
  print("send batch ---------");
  called = true;
}

void main() {
  test("batch Manager", () async {
    called = false;
    IHitCacheImplementation fsCacheHitTest = DefaultCacheHitImp();

    TrackingManagerConfig configTrackingTest = TrackingManagerConfig(
        batchIntervals: 20,
        poolMaxSize: 50,
        batchStrategy: BatchCachingStrategy.BATCH_CONTINUOUS_CACHING);

    FlagshipPoolQueue testPool =
        FlagshipPoolQueue(configTrackingTest.poolMaxSize);
    for (int i = 0; i < 10; i++) {
      Event testEvent = Event(
          action: "testPool" + "$i", category: EventCategory.Action_Tracking);
      testEvent.visitorId = "user_" + "$i";
      testPool.addNewTrackElement(testEvent);

      // Create transac
      Transaction testTransac = Transaction(
          transactionId: "user_" + "$i", affiliation: "testAffiliation");
      testTransac.visitorId = "user_" + "$i";
      testPool.addNewTrackElement(testTransac);

      // create Pageview
      Page testPage = Page(location: "testPage");
      testPage.visitorId = "user_" + "$i";
      testPool.addNewTrackElement(testPage);

      // Create Item
      Item testItem = Item(
          transactionId: "user_" + "$i", name: "testItem", code: "testCode");
      testItem.visitorId = "user_" + "$i";
      testPool.addNewTrackElement(testItem);

      // Create Screen
      Screen testScreen = Screen(location: "testScreen");
      testScreen.visitorId = "user_" + "$i";
      testPool.addNewTrackElement(testScreen);
    }

    // Create batch object
    BatchManager testBatch = BatchManager(
        testPool, sendBatchTest, configTrackingTest, fsCacheHitTest);
    // trigger the batch
    testBatch.batchFromQueue();
    expect(testBatch.fsPool.fsQueue.length, 0);
    expect(called, true);
  });

  test("batch Manager with timer", () async {
    called = false;
    IHitCacheImplementation fsCacheHitTest = DefaultCacheHitImp();

    TrackingManagerConfig configTrackingTest = TrackingManagerConfig(
        batchIntervals: 2,
        poolMaxSize: 50,
        batchStrategy: BatchCachingStrategy.BATCH_CONTINUOUS_CACHING);

    FlagshipPoolQueue testPool =
        FlagshipPoolQueue(configTrackingTest.poolMaxSize);
    for (int i = 0; i < 50; i++) {
      Event testEvent = Event(
          action: "testPool" + "$i", category: EventCategory.Action_Tracking);
      testEvent.visitorId = "user_" + "$i";
      testPool.addNewTrackElement(testEvent);
    }

    // Create batch object
    BatchManager testBatch = BatchManager(
        testPool, sendBatchTest, configTrackingTest, fsCacheHitTest);

    await Future.delayed(const Duration(seconds: 2), () {});
    expect(testBatch.fsPool.fsQueue.length, 0);
    expect(called, true);
  });

  test("batch Manager with limite size", () async {
    called = false;
    IHitCacheImplementation fsCacheHitTest = DefaultCacheHitImp();

    TrackingManagerConfig configTrackingTest = TrackingManagerConfig(
        batchIntervals: 60,
        poolMaxSize: 30,
        batchStrategy: BatchCachingStrategy.BATCH_CONTINUOUS_CACHING);

    FlagshipPoolQueue testPool =
        FlagshipPoolQueue(configTrackingTest.poolMaxSize);

    BatchManager testBatch = BatchManager(
        testPool, sendBatchTest, configTrackingTest, fsCacheHitTest);

    for (int i = 0; i < 50; i++) {
      Event testEvent = Event(
          action: "testPool" + "$i", category: EventCategory.Action_Tracking);
      testEvent.visitorId = "user_" + "$i";
      testPool.addNewTrackElement(testEvent);

      if (i == 29) {
        expect(testBatch.fsPool.fsQueue.length, 0);
        expect(called, true);
      }
    }
    expect(testBatch.fsPool.fsQueue.length, 20);
  });
}
