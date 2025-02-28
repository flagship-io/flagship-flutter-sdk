/// Example Dart/Flutter code that mirrors the logic of the Swift FSPollingScore class.
/// Adjust as needed for your actual networking, logging, and delegate mechanisms.

import 'dart:async';

import 'package:flagship/emotionAi/emotion_tools.dart';

/// A sample delegate interface similar to FSEmotionAiDelegate in Swift.
mixin EmotionAiDelegate {
  /// Called when a score is successfully fetched from the server.
  void emotionAiCaptureCompleted(dynamic score);
}

class PollingScore {
  /// Timer that stops polling after a fixed duration (10 seconds).
  Timer? _stopTimer;

  /// Periodic timer that checks for a new score every 0.5 seconds.
  Timer? _pollingTimer;

  /// Number of times we've retried fetching the score.
  int _retryCount = 0;

  /// Values passed from Swift code.
  final String visitorId;
  final String? anonymousId;
  final EmotionAiDelegate? delegate;

  /// Create the polling score object, schedule stop timer, and start polling.
  PollingScore({
    required this.visitorId,
    this.anonymousId,
    this.delegate,
  }) {
    // Equivalent to the Timer.scheduledTimer(...) in Swift that stops
    // polling after 10 seconds if no score was fetched.
    _stopTimer = Timer(const Duration(seconds: 10), stopPollingScore);

    // Start polling right away (like startPolling() in Swift init).
    startPolling();
  }

  /// Initiate repeated polling of the server to fetch the score.
  void startPolling() {
    // Create a repeating timer with a 0.5 second interval (similar to FSRepeatingTimer in Swift).
    _pollingTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      _retryCount++;
      print('GET THE SCORE FROM THE SERVER - RETRY COUNT: $_retryCount');

      // Fetch the score from the server (placeholder).
      final scoreResult = await EmotionAITools().fetchScore(visitorId);
      final statusCode = scoreResult.statusCode;
      final score = scoreResult.score;

      if (statusCode == 204) {
        // Score not ready; let the timer keep going
        print('Score not ready (statusCode=204). Continuing to poll...');
      } else if (statusCode == 200) {
        // We got a valid score
        print('Score successfully received (statusCode=200)');
        delegate?.emotionAiCaptureCompleted(score);

        // Invalidate timers since we have our score
        _stopTimer?.cancel();
        _pollingTimer?.cancel();
      } else {
        // Some other status code (error, etc.)
        print('Score not received - status code: $statusCode');
      }
    });
  }

  /// Called when the stop timer fires (after 10 seconds), indicating no score was found.
  void stopPollingScore() {
    print('Stop Polling Score-EmotionAI, Session Ended');
    _pollingTimer?.cancel();
  }
}
