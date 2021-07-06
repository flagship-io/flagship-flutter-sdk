import 'dart:convert';

import 'package:flagship/api/endpoints.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'service.dart';

class TrackingManager {
  late String apiKey;

  TrackingManager() {
    this.apiKey = Flagship.sharedInstance().apiKey ?? "";

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
    var response = await Service.sendHttpRequest(RequestType.Post, urlString,
        fsHeader, jsonEncode(activateHit.toJson()));
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
  Future<void> sendHit(Hit pHit) async {
    /// Create url
    String urlString = Endpoints.ARIANE;
    try {
      var response = await Service.sendHttpRequest(
          RequestType.Post, urlString, fsHeader, jsonEncode(pHit.bodyTrack));
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
      Flagship.logger(Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$error"));
    }
  }
}
