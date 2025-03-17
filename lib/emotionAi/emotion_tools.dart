import 'dart:convert';
import 'dart:ui';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/model/account_settings.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flutter/widgets.dart';

class EmotionAITools {
  // Position of the clic : y,x, last 5 digits from timestamp, clic duration in ms
  static String createCpoField(
      {required PointerUpEvent event,
      required int timestamps,
      required int clickDuration}) {
    return event.position.dy.toString() +
        "," +
        event.position.dx.toString() +
        "," +
        (timestamps % 100000).toString() +
        "," +
        clickDuration.toString();
  }

// All mouse position
  String createCpFiled(List<Map<String, dynamic>>? path) {
    return '${path?.map((record) {
      final pos = record["position"] as Offset;
      final ts = record["timeStamp"] as int;
      return '${pos.dy},${pos.dx},${ts % 100000}';
    }).join(';')}';
  }

//Scroll position :
  String createSpoFiled(List<Map<String, dynamic>>? path) {
    return '${path?.map((record) {
      final pos = record["position"] as Offset;
      final ts = record["timeStamp"] as int;
      return '${pos.dx},${pos.dy},${ts % 100000}';
    }).join(';')}';
  }

  static FlutterView? getInstanceWindow() {
    return WidgetsBinding.instance.platformDispatcher.implicitView;
  }

  static String getLanguageCode() {
    return WidgetsBinding.instance.platformDispatcher.locale.languageCode;
  }

  // Get settings ressources
  Future<AccountSettings?> fetchRessources(String envId) async {
    try {
      // Url for settings
      String urlString = Endpoints.SettingsUrl.replaceFirst(
          "%s", Flagship.sharedInstance().envId ?? "");

      var response = await Flagship.sharedInstance()
          .getConfiguration()
          ?.decisionManager
          .service
          .sendHttpRequest(RequestType.Get, urlString, {}, null);

      if (response?.statusCode == 200) {
        // Return AccountSettings
        return AccountSettings.fromJson(
            json.decode(response?.body ?? "")['accountSettings'] ?? {});
      } else {
        // You can return any error message or throw an exception
        Flagship.logger(Level.INFO,
            "Failed to get AccountSettings.json from $urlString - Code Error is : ${response?.statusCode}");
        return null;
      }
    } catch (e) {
      // Handle any exceptions thrown during the request
      Flagship.logger(Level.INFO, "Request failed with error: $e");
      return null;
    }
  }

  /// This uses the http package to perform a GET request and parse the result.
  Future<ScoreResult> fetchScore(String visitorId) async {
    String envId = Flagship.sharedInstance().envId ?? "";
    const fetchEmotionAIScoreURL = Endpoints.fetchEmotionAIScoreURL;

    var urlString = fetchEmotionAIScoreURL
        .replaceFirst("%s", envId)
        .replaceFirst("%s", visitorId);

    try {
      // Perform the GET request
      final response = await Flagship.sharedInstance()
          .getConfiguration()
          ?.decisionManager
          .service
          .sendHttpRequest(RequestType.Get, urlString, {}, null);

      if (response?.statusCode == 204) {
        // The server returned "no content"
        Flagship.logger(Level.INFO, "Score not found");
        return ScoreResult(null, 204);
      } else if (response?.statusCode == 200) {
        // The server returned OK, parse the body to extract the score
        final Map<String, dynamic> responseBody =
            json.decode(response?.body ?? "");
        final Map<String, dynamic>? eaiMap = responseBody["eai"];

        // Looking for a "score" inside "eas"
        final String? score = eaiMap?["eas"];
        if (score != null) {
          Flagship.logger(
              Level.INFO, "Your current EmotionAI score is: $score");

          return ScoreResult(score, 200);
        } else {
          Flagship.logger(
              Level.INFO, "No score found from the server response.");

          // Return status 200, but null score
          return ScoreResult(null, 200);
        }
      } else {
        // Any other status code – handle appropriately
        print("");

        Flagship.logger(Level.INFO,
            "Error on fetching score: HTTP ${response?.statusCode}");
        // ... You may also add logging or usage tracking as needed ...
        return ScoreResult(null, response?.statusCode ?? 0);
      }
    } catch (error) {
      // Handle network or decoding errors
      Flagship.logger(
          Level.INFO, "Exception occurred while fetching score: $error");
      return ScoreResult(null, -1);
    }
  }

  static String getSrValueScreen() {
    final size = EmotionAITools.getInstanceWindow()?.physicalSize;
    final devicePixelRatio =
        EmotionAITools.getInstanceWindow()?.devicePixelRatio ?? 1.0;
    final logicalWidth = size?.width ?? 0 / devicePixelRatio;
    final logicalHeight = size?.height ?? 0 / devicePixelRatio;
    return "$logicalWidth,$logicalHeight;";
  }
}

class ScoreResult {
  final String? score;
  final int statusCode;
  ScoreResult(this.score, this.statusCode);
}
