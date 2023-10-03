import 'package:flagship/api/service.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/tracking/tracking_manager_continuous_strategies.dart';
import 'package:http/http.dart' as http;

class DataReportQueue {
  TrackingManageContinuousStrategy? troubleReportQueue;

  DataReportQueue() {
    Service reportService = Service(http.Client());
    TrackingManagerConfig configTracking = TrackingManagerConfig();
    troubleReportQueue = TrackingManageContinuousStrategy(
        reportService, configTracking, DefaultCacheHitImp());
  }
}
