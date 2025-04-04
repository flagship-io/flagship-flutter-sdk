import 'dart:convert';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/dataUsage/data_usage_tracking.dart';
import 'package:flagship/emotionAi/emotion_event.dart';
import 'package:flagship/emotionAi/emotion_pageview.dart';
import 'package:flagship/emotionAi/emotion_tools.dart';
import 'package:flagship/emotionAi/polling_score.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

const double FSAIDuration30 = 30.0 + 2; // 32.0
const double FSAIDuration120 = 120.0;

class EmotionAI {
  String visitorId;
  String? anonymousId = null;
  String currentScreenName = "";
  VoidCallback? onEmotionCollected;
  DateTime? touchStartTime;
  bool isCollecting = false;
  Service? service;

  PollingScore? pollingScore;

  double timeStartCollecting = 0;

  // -- Dico for positions
  final Map<int, Offset> startPositions = {};
  final Map<int, bool> hasScrolled = {};
  final Map<int, List<Map<String, dynamic>>> pointerPaths = {};
  final Map<int, DateTime> pointerDownTimes = {};

  // -- Threshold for "tap" - "scroll/drag"
  static const double kTouchSlop = 18.0;

  // Delegate
  EmotionAiDelegate? delegate;

  // Define your callback
  late PointerRoute _emotionAIGlobalPointerRoute;

  // Constructor
  EmotionAI(this.visitorId, this.anonymousId) {
    // Init service
    service = Service(http.Client());
  }

  void startEAICollectForView(String nameScreen) {
    if (isCollecting == true) {
      Flagship.logger(
          Level.INFO, "The emotionAI process is already collecting");
      return;
    }
    // Update current scree name
    this.currentScreenName = nameScreen;
    // Create emotion page view
    FSEmotionPageView eventPage = FSEmotionPageView(nameScreen);
    this.sendEmotionEvent(eventPage).whenComplete(() {
      // Start time of collecting
      timeStartCollecting = DateTime.now().millisecondsSinceEpoch / 1000.0;
      // Start event emotion capture
      this._startCollecting();

      // Send TR on start emotionAI
      DataUsageTracking.sharedInstance().processTroubleShootingEAIWorkFlow(
          CriticalPoints.EMOTIONS_AI_START_COLLECTING.name,
          Flagship.sharedInstance().currentVisitor);
    });
  }

  // Start collecting gestures
  void _startCollecting() {
    isCollecting = true;
    _emotionAIGlobalPointerRoute = (PointerEvent event) {
      if (event is PointerDownEvent) {
        // Save initial position
        startPositions[event.pointer] = event.position;
        // set as tap
        hasScrolled[event.pointer] = false;
        // Initialise list positions
        pointerPaths[event.pointer] = [
          {
            'position': event.position,
            'timeStamp': DateTime.now().toUtc().microsecondsSinceEpoch,
          }
        ];

        pointerDownTimes[event.pointer] = DateTime.now().toUtc(); // Instant UTC
      } else if (event is PointerMoveEvent) {
        // Add the current position and timeStamp
        pointerPaths[event.pointer]?.add({
          'position': event.position,
          'timeStamp': DateTime.now().microsecondsSinceEpoch,
        });
        // Check if already identified as scroll
        if (hasScrolled[event.pointer] == false) {
          final initialPosition = startPositions[event.pointer];
          if (initialPosition != null) {
            final distance = (event.position - initialPosition).distance;
            // If the distance over the threshold, then will consider it as scroll
            if (distance > kTouchSlop) {
              hasScrolled[event.pointer] = true;
              Flagship.logger(Level.DEBUG,
                  "Pointer ${event.pointer}: Scroll/Drag détecté (distance > $kTouchSlop)");
            }
          }
        }
      } else if (event is PointerUpEvent) {
        final double deltaTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) -
                timeStartCollecting;

        // Add final position and timeStamp
        pointerPaths[event.pointer]?.add({
          'position': event.position,
          'timeStamp': DateTime.now().toUtc().microsecondsSinceEpoch,
        });
        // Check is this pointer is already tagged as scroll
        final wasScrolled = hasScrolled[event.pointer] ?? false;
        if (!wasScrolled) {
          // Time click duration
          final downTime = pointerDownTimes[event.pointer];
          int clickDuration = 0;
          if (downTime != null) {
            clickDuration =
                DateTime.now().toUtc().difference(downTime).inMilliseconds;
          }
          // create a CPO field
          String cpoString = EmotionAITools.createCpoField(
              event: event,
              timestamps: DateTime.now().toUtc().microsecondsSinceEpoch,
              clickDuration: clickDuration);

          // Send Event for click
          sendEvent(
              FSEmotionEvent("", cpoString, "", currentScreenName), deltaTime);
        } else {
          String cpString =
              EmotionAITools().createCpFiled(pointerPaths[event.pointer]);
          String spoString =
              EmotionAITools().createSpoFiled(pointerPaths[event.pointer]);
          // Send Event for move
          sendEvent(FSEmotionEvent(cpString, "", spoString, currentScreenName),
              deltaTime);
        }

        // Clean
        startPositions.remove(event.pointer);
        hasScrolled.remove(event.pointer);
        pointerPaths.remove(event.pointer);
      } else if (event is PointerCancelEvent) {
        // Cancel by the system
        // Clean
        startPositions.remove(event.pointer);
        hasScrolled.remove(event.pointer);
        pointerPaths.remove(event.pointer);
      }
    };

    try {
      GestureBinding.instance.pointerRouter
          .addGlobalRoute(_emotionAIGlobalPointerRoute);
    } catch (e) {
      Flagship.logger(Level.EXCEPTIONS, e.toString());
    }
  }

  Future<void> sendEmotionEvent(
    Hit aiHit, {
    Function(Exception?)? completion,
  }) async {
    // Set the visitor Id
    aiHit.visitorId = visitorId;
    aiHit.anonymousId = anonymousId;
    // Create url
    String urlString = Endpoints.EmotionAiUrl;
    Flagship.logger(Level.DEBUG, 'Sending emotion AI events : ' + urlString);
    try {
      var response = await service?.sendHttpRequest(
          RequestType.Post,
          urlString,
          Endpoints.getFSHeader(Flagship.sharedInstance().apiKey ?? ""),
          jsonEncode(aiHit.bodyTrack),
          timeoutMs: TIMEOUT_REQUEST);
      switch (response?.statusCode) {
        case 200:
        case 204:
        case 201:
          Flagship.logger(Level.INFO, HIT_SUCCESS);

          DataUsageTracking.sharedInstance()
              .processTroubleShootingEAIEvent(null, aiHit, response);

          break;
        default:
          Flagship.logger(Level.ERROR, HIT_FAILED);
          DataUsageTracking.sharedInstance().processTroubleShootingEAIEvent(
              null, aiHit, response,
              onFailed: true);
      }
    } catch (error) {
      Flagship.logger(
          Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$error") + urlString);
      Flagship.logger(Level.ERROR, HIT_FAILED);
    }
  }

  // Stop collecting gestures
  void stopCollecting() {
    DataUsageTracking.sharedInstance().processTroubleShootingEAIWorkFlow(
        CriticalPoints.EMOTIONS_AI_STOP_COLLECTING.name,
        Flagship.sharedInstance().currentVisitor);
    isCollecting = false;
    try {
      GestureBinding.instance.pointerRouter
          .removeGlobalRoute(_emotionAIGlobalPointerRoute);
    } catch (e) {
      Flagship.logger(Level.EXCEPTIONS, e.toString());
    }
    Flagship.logger(Level.INFO, "The emotionAI collection is stopped");
  }

  sendEvent(Hit event, double deltaTime) {
    Flagship.logger(Level.INFO,
        "Send emotion Event after $deltaTime seconds from starting collect");
    if (deltaTime < FSAIDuration30) {
      sendEmotionEvent(event);
    } else if (deltaTime <= FSAIDuration120) {
      sendEmotionEvent(event);
      Flagship.logger(
          Level.INFO, "Send last emotion event and stop the collect");
      stopCollecting();
      // Start get scoring from remote
      pollingScore = PollingScore(
          visitorId: visitorId, anonymousId: anonymousId, delegate: delegate);
    } else {
      // visitor not scored
    }
  }

  onAppScreenChange(String screenName) {
    this.currentScreenName = screenName;
    FSEmotionPageView eventPage = FSEmotionPageView(this.currentScreenName);
    this.sendEmotionEvent(eventPage).whenComplete(() {
      Flagship.logger(Level.INFO, "Send pageview when app change screen");
    });
  }

  updateTupleId(String visitorId, String? anonymousId) {
    this.visitorId = visitorId;
    this.anonymousId = anonymousId;
  }
}
