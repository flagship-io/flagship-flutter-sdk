import 'dart:collection';
import 'dart:convert';

import 'package:flagship/api/endpoints.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'service.dart';
import 'package:http/http.dart' as http;

const TIMEOUT_REQUEST = 60000; // 60 seconds

class TrackingManager {
  /// api key
  late String apiKey;

  /// service
  late Service _service;

  /// Pool tempo, place it later elswhere
  late FlagshipPoolQueue fsPool;

  TrackingManager() {
    this.apiKey = Flagship.sharedInstance().apiKey ?? "";
    _service = Service(http.Client());

    /// Temporary create a pool
    fsPool = FlagshipPoolQueue();

    /// Refractor later , find better way to get apikey
  }

  /// Header for request
  Map<String, String> get fsHeader {
    return {
      "x-api-key": this.apiKey,
      "x-sdk-client": "flutter",
      "x-sdk-version": FlagshipVersion,
      "Content-type": "application/json"
    };
  }

  // later add code error in the future
  Future<void> sendActivate(Activate activateHit) async {
    /// Create url
    String urlString = Endpoints.DECISION_API + Endpoints.ACTIVATION;
    var response = await _service.sendHttpRequest(
        RequestType.Post, urlString, fsHeader, jsonEncode(activateHit.toJson()),
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

  /// Send Hit
  Future<void> sendHit(BaseHit pHit) async {
    /// Add to pool
    fsPool.addTrackElement(pHit);

    /// Create url
    String urlString = Endpoints.ARIANE;
    try {
      var response = await _service.sendHttpRequest(RequestType.Post, urlString, fsHeader, jsonEncode(pHit.bodyTrack),
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
      Flagship.logger(Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$error") + urlString);
      Flagship.logger(Level.ERROR, HIT_FAILED);
    }
  }
}

/// Queue for the hits

class FlagshipPoolQueue {
  double maxSize = 500.0; // Sample

  Queue<BaseHit> fsQueue = Queue();

  void addTrackElement(BaseHit newHit) {
    if (this.fsQueue.length < maxSize) {
      // Set id for the hit
      newHit.id = newHit.visitorId + FlagshipTools.generateUuidv4();
      fsQueue.add(newHit);
    } else {
      print("The queue pool reach the max size ");
    }
  }

  void removeTrackElement(String id) {
    fsQueue.removeWhere((element) {
      return (element.id == id);
    });
  }

  /// Clear all the hit in the queue
  void flushTrackQueue() {
    fsQueue.clear();
  }

  /// Extract the hits
  void exctractHits() {}

  void validateHit() {}
}
