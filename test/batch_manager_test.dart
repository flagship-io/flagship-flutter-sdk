import 'package:flagship/cache/cache_manager.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/hits/event.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/batch_manager.dart';
import 'package:flagship/tracking/pool_queue.dart';
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
    for (int i = 0; i < 50; i++) {
      Event testEvent = Event(
          action: "testPool" + "$i", category: EventCategory.Action_Tracking);
      testEvent.visitorId = "user_" + "$i";
      testPool.addTrackElement(testEvent);
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
      testPool.addTrackElement(testEvent);
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
      testPool.addTrackElement(testEvent);

      if (i == 29) {
        expect(testBatch.fsPool.fsQueue.length, 0);
        expect(called, true);
      }
    }
    expect(testBatch.fsPool.fsQueue.length, 20);
  });
}
