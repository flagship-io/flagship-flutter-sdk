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
  onCacheHits(Map<String, Map<String, Object>> hits) {}

  // On sucess sending hits batch
  @override
  onSendBatchWithSucess(List<Hit> listOfSendedHits) {
    hitDelegate?.onSendBatchWithSucess(
        listOfSendedHits, BatchCachingStrategy.BATCH_PERIODIC_CACHING);
  }

  // On sucess sending activate batch
  @override
  onSendActivateBatchWithSucess(List<Hit> listOfSendedHits) {
    activateDelegate?.onSendBatchWithSucess(
        listOfSendedHits, BatchCachingStrategy.BATCH_PERIODIC_CACHING);
  }
}
