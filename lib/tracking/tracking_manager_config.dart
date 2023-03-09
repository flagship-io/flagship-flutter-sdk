import 'dart:math';

import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';

const int DEFAULT_BATCH_LENGTH = 10; // Exctract 20 hits from the loop

const int DEFAULT_TIME_INTERVAL = 5; // On each 5 seconds will launch the batch.

enum BatchCachingStrategy {
  BATCH_CONTINUOUS_CACHING, // Cache on continous when hit occurs

  BATCH_PERIODIC_CACHING, // Cache when batch is launched

  NO_BATCHING_CONTINUOUS_CACHING_STRATEGY // Hidden option with no caching and no batching
}

class TrackingManagerConfig {
  // Define the time intervals the SDK will use to send tracking batches.
  int batchIntervals;
  // Define the maximum number of tracking hit that each batch can contain.
  int poolMaxSize;

  // indicate the strategy to adopt for the cache manager
  final BatchCachingStrategy batchStrategy;

  TrackingManagerConfig(
      {this.batchIntervals = DEFAULT_TIME_INTERVAL,
      this.poolMaxSize = DEFAULT_BATCH_LENGTH,
      this.batchStrategy = BatchCachingStrategy.BATCH_CONTINUOUS_CACHING}) {
    // batchIntervals  should not be greater than 14400 (4h) and less than 1s  otherwise default value should be used
    if (batchIntervals > 14400 || batchIntervals < 1) {
      Flagship.logger(Level.INFO,
          "batchIntervals should not be greater than 14400 (4h) and less than 1s. w'll use a default value: $DEFAULT_TIME_INTERVAL");
      this.batchIntervals = DEFAULT_TIME_INTERVAL;
    }

    // poolMaxSize should not be less than 5 otherwise default value should be used
    if (this.poolMaxSize < 5) {
      Flagship.logger(Level.INFO,
          "poolMaxSize should not be less than 5. w'll use a default value: $DEFAULT_BATCH_LENGTH");
      this.poolMaxSize = DEFAULT_BATCH_LENGTH;
    }
  }
}
