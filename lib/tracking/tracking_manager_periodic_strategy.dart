import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/tracking/tracking_manager_continuous_strategies.dart';

class TrackingManagerPeriodicStrategy extends TrackingManageContinuousStrategy {
  TrackingManagerPeriodicStrategy(Service service,
      TrackingManagerConfig configTracking, IHitCacheImplementation? fsCacheHit)
      : super(service, configTracking, fsCacheHit ?? DefaultCacheHitImp());

  @override
  void onCacheHit(Hit hitToBeCached) {}

  // On sucess sending hits batch
  @override
  onSendBatchWithSuccess(List<Hit> listOfSendedHits) {
    hitDelegate?.onSendBatchWithSuccess(
        listOfSendedHits, BatchCachingStrategy.BATCH_PERIODIC_CACHING);
  }

  // On sucess sending activate batch
  @override
  onSendActivateBatchWithSuccess(List<Hit> listOfSendedHits) {
    activateDelegate?.onSendBatchWithSuccess(
        listOfSendedHits, BatchCachingStrategy.BATCH_PERIODIC_CACHING);
  }
}
