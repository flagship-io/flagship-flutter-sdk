import 'dart:async';
import 'dart:convert';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:http/http.dart' as http;
import 'package:flagship/api/service.dart';

const TIMEOUT_REQUEST = 60000; // 60 seconds

class TrackingManager {
  /// api key
  late String apiKey;

  /// service
  Service service = Service(http.Client());

// Cache manager
  final IHitCacheImplementation? fsCacheHit;

// Config for the tracking manager
  final TrackingManagerConfig configTracking;

// Delegate hits
  TrackingManagerDelegate? hitDelegate;

// Delegate activate
  TrackingManagerDelegate? activateDelegate;

  TrackingManager(this.service, this.configTracking, this.fsCacheHit) {
    this.apiKey = Flagship.sharedInstance().apiKey ?? "";
  }

  Future<void> sendHit(BaseHit pHit) async {
    if (pHit.isValid() == true) {
      // Create url
      String urlString = Endpoints.EVENT;
      try {
        var response = await service.sendHttpRequest(
            RequestType.Post,
            urlString,
            Endpoints.getFSHeader(this.apiKey),
            jsonEncode(pHit.bodyTrack),
            timeoutMs: TIMEOUT_REQUEST);
        switch (response.statusCode) {
          case 200:
          case 204:
          case 201:
            Flagship.logger(Level.INFO, HIT_SUCCESS);
            break;
          default:
            Flagship.logger(Level.ERROR, HIT_FAILED);
        }
      } catch (error) {
        Flagship.logger(Level.EXCEPTIONS,
            EXCEPTION.replaceFirst("%s", "$error") + urlString);
        Flagship.logger(Level.ERROR, HIT_FAILED);
      }
    } else {
      Flagship.logger(Level.ERROR, "Hit not valid");
    }
  }

  // Send Activate
  Future<void> sendActivate(Activate activateHit) async {
    // Create url
    String urlString = Endpoints.DECISION_API + Endpoints.ACTIVATION;
    var response = await service.sendHttpRequest(RequestType.Post, urlString,
        Endpoints.getFSHeader(this.apiKey), jsonEncode(activateHit.toJson()),
        timeoutMs: TIMEOUT_REQUEST);
    switch (response.statusCode) {
      case 200:
      case 204:
        Flagship.logger(Level.INFO, ACTIVATE_SUCCESS);
        break;
      default:
        Flagship.logger(Level.ERROR, ACTIVATE_FAILED);
    }
  }

  // Called when close flagship
  close() {}
  // Called to flush the pool queue
  flushAllTracking() {}
  // Called to add a list to the pools
  // Each hit is checked before adding to the respective pool
  addTrackingElementsToPool(List<Hit> listOfTracking) {}
}

mixin TrackingManagerDelegate {
  // On Sucess Sendig Batch
  onSendBatchWithSucess(
      List<Hit> listOfSendedHits, BatchCachingStrategy strategy);

  // On Failed Sending Batch
  onFailedToSendBatch(List<Hit> listOfHitToSend);
}
