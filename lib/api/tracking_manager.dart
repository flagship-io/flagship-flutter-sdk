import 'dart:convert';

import 'package:flagship/api/endpoints.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/utils/constants.dart';
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
      "x-sdk-version": version,
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
        print("activate sent with success ");
        break;
      default:
        print("Failed to send activate");
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
          print("Event sent with success ");
          break;
        default:
          print("Failed to send Event");
      }
    } catch (error) {
      print("error occured when sending hit: $error");
    }
  }
}
