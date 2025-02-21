import 'dart:convert';

import 'package:flagship/api/endpoints.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/model/account_settings.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

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

// all mouse position :
// y,x,last 5 digits from timestamp
// Separated by semi colon (limited to 2000 characters max)

  static String createCpFiled(List<Map<String, dynamic>>? path) {
    return '${path?.map((record) {
      final pos = record["position"] as Offset;
      final ts = record["timeStamp"] as int;
      return '${pos.dy},${pos.dx},${ts % 100000}';
    }).join(';')}';
  }

//Scroll position :
// Desktop: y, last 5 digits from timestamp
// Mobile touch : x,y, last 5 digits from timestamp
  static String createSpoFiled(List<Map<String, dynamic>>? path) {
    return '${path?.map((record) {
      final pos = record["position"] as Offset;
      final ts = record["timeStamp"] as int;
      return '${pos.dx},${pos.dy},${ts % 100000}';
    }).join(';')}';
  }

  static getInstanceWindow() {
    // Retrieve window information using Flutter's WidgetsBinding.
    return WidgetsBinding.instance.window;
  }

  // Get settings ressources
  static Future<AccountSettings?> fetchRessources(String envId) async {
    try {
      // Url for settings
      String urlString = Endpoints.SettingsUrl.replaceFirst(
          "%s", Flagship.sharedInstance().envId ?? "");

      final response = await http.get(Uri.parse(urlString));

      if (response.statusCode == 200) {
        // Return AccountSettings
        return AccountSettings.fromJson(
            json.decode(response.body)['accountSettings'] ?? {});
      } else {
        // You can return any error message or throw an exception
        return null;
      }
    } catch (e) {
      // Handle any exceptions thrown during the request
      print('Request failed with error: $e');
      return null;
    }
  }

  /// This uses the http package to perform a GET request and parse the result.
  Future<ScoreResult> fetchScore(String visitorId) async {
    String envId = Flagship.sharedInstance().envId ?? "";
    const fetchEmotionAIScoreURL = Endpoints.fetchEmotionAIScoreURL;

    final Uri requestUri = Uri.parse(fetchEmotionAIScoreURL
        .replaceFirst("%s", envId)
        .replaceFirst("%s", visitorId));

    try {
      // Perform the GET request
      final response = await http.get(requestUri);

      if (response.statusCode == 204) {
        // The server returned "no content"
        print("No score found (HTTP 204).");
        return ScoreResult(null, 204);
      } else if (response.statusCode == 200) {
        // The server returned OK, parse the body to extract the score
        final Map<String, dynamic> responseBody = json.decode(response.body);
        final Map<String, dynamic>? eaiMap = responseBody["eai"];

        // Looking for a "score" inside "eas"
        final String? score = eaiMap?["eas"];
        if (score != null) {
          print("Your current EAI score is: $score");
          return ScoreResult(score, 200);
        } else {
          print("No score found in the server response.");
          // Return status 200, but null score
          return ScoreResult(null, 200);
        }
      } else {
        // Any other status code – handle appropriately
        print("Error fetching score: HTTP ${response.statusCode}");
        // ... You may also add logging or usage tracking as needed ...
        return ScoreResult(null, response.statusCode);
      }
    } catch (error) {
      // Handle network or decoding errors
      print("Exception occurred while fetching score: $error");
      return ScoreResult(null, -1);
    }
  }
}

class ScoreResult {
  final String? score;
  final int statusCode;
  ScoreResult(this.score, this.statusCode);
}
