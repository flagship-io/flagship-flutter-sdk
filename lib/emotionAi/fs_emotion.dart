import 'dart:convert';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
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

  // -- Dictionnaires pour mémoriser la position initiale et l'état de scroll pour chaque pointeur
  final Map<int, Offset> startPositions = {};
  final Map<int, bool> hasScrolled = {};
  final Map<int, List<Map<String, dynamic>>> pointerPaths = {};
  final Map<int, DateTime> pointerDownTimes = {};

  // -- Valeur seuil pour distinguer un "tap" d'un "scroll/drag"
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
      print("The process emotionAI is already collecting ..... ");
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
    });
  }

  // Start collecting gestures
  void _startCollecting() {
    print("Start Collecting emotionAI ....");
    isCollecting = true;
    _emotionAIGlobalPointerRoute = (PointerEvent event) {
      if (event is PointerDownEvent) {
        // Enregistre la position initiale pour ce pointeur
        startPositions[event.pointer] = event.position;
        // Marque qu'on n'a pas encore reconnu de scroll pour ce pointeur
        hasScrolled[event.pointer] = false;
        // Initialise la liste des positions (historique) pour ce pointeur
        // Initialise l'historique pour ce pointeur
        pointerPaths[event.pointer] = [
          {
            'position': event.position,
            'timeStamp': DateTime.now().toUtc().microsecondsSinceEpoch,
          }
        ];

        pointerDownTimes[event.pointer] = DateTime.now().toUtc(); // Instant UTC
      } else if (event is PointerMoveEvent) {
        // Ajoute la position courante + le timeStamp à l'historique
        pointerPaths[event.pointer]?.add({
          'position': event.position,
          'timeStamp': DateTime.now().microsecondsSinceEpoch,
        });
        // Vérifie si nous avons déjà identifié un scroll pour ce pointeur
        if (hasScrolled[event.pointer] == false) {
          final initialPosition = startPositions[event.pointer];
          if (initialPosition != null) {
            final distance = (event.position - initialPosition).distance;
            // Si la distance dépasse le seuil, on considère qu'il s'agit d'un scroll/drag
            if (distance > kTouchSlop) {
              hasScrolled[event.pointer] = true;
              debugPrint(
                'Pointer ${event.pointer}: Scroll/Drag détecté (distance > $kTouchSlop)',
              );
            }
          }
        }
      } else if (event is PointerUpEvent) {
        final double deltaTime =
            (DateTime.now().millisecondsSinceEpoch / 1000.0) -
                timeStartCollecting;

        // Ajoute la position finale + timeStamp à l'historique (pour complétude)
        pointerPaths[event.pointer]?.add({
          'position': event.position,
          'timeStamp': DateTime.now().toUtc().microsecondsSinceEpoch,
        });
        // Vérifie si ce pointeur a été marqué comme ayant scrollé
        final wasScrolled = hasScrolled[event.pointer] ?? false;
        if (!wasScrolled) {
          // On calcule la durée du clic
          final downTime = pointerDownTimes[event.pointer];
          int clickDuration = 0;
          if (downTime != null) {
            clickDuration =
                DateTime.now().toUtc().difference(downTime).inMilliseconds;
            debugPrint(
              'Durée du clic (Pointer ${event.pointer}): ${clickDuration} ms',
            );
          }
          // create a CPO
          String cpoString = EmotionAITools.createCpoField(
              event: event,
              timestamps: DateTime.now().toUtc().microsecondsSinceEpoch,
              clickDuration: clickDuration);
          debugPrint(
            'Pointer ${event.pointer}: Touch/Tap détecté (distance ≤ $kTouchSlop) Le champs SPO sera donc ${cpoString}',
          );

          // Send Event for click
          sendEvent(
              FSEmotionEvent("", cpoString, "", currentScreenName), deltaTime);
        } else {
          String cpString =
              EmotionAITools.createCpFiled(pointerPaths[event.pointer]);
          String spoString =
              EmotionAITools.createSpoFiled(pointerPaths[event.pointer]);
          // Send Event for move

          sendEvent(FSEmotionEvent(cpString, "", spoString, currentScreenName),
              deltaTime);

          debugPrint(
            'Pointer ${event.pointer}: Scroll/Drag confirmé, le champ CP est ${cpString}',
          );

          debugPrint(
            'Pointer ${event.pointer}: Scroll/Drag confirmé, le champ SPO est ${spoString}',
          );
        }

        // Nettoyage : supprime les entrées pour ce pointeur
        startPositions.remove(event.pointer);
        hasScrolled.remove(event.pointer);
        pointerPaths.remove(event.pointer);
      } else if (event is PointerCancelEvent) {
        // Cancel by the system
        debugPrint(
            'Pointer ${event.pointer}: Événement annulé (PointerCancel)');
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
      // Todo later add flagship logger
      print(e);
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
          break;
        default:
          Flagship.logger(Level.ERROR, HIT_FAILED);
      }
    } catch (error) {
      Flagship.logger(
          Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$error") + urlString);
      Flagship.logger(Level.ERROR, HIT_FAILED);
    }
  }

  // Stop collecting gestures
  void stopCollecting() {
    isCollecting = false;
    try {
      GestureBinding.instance.pointerRouter
          .removeGlobalRoute(_emotionAIGlobalPointerRoute);
    } catch (e) {
      // ToDO later add logger flagship
      print(e);
    }

    debugPrint("Emotion AI collection stopped");
  }

  sendEvent(Hit event, double deltaTime) {
    print("Send emotion Event after $deltaTime seconds from starting collect");
    if (deltaTime < FSAIDuration30) {
      sendEmotionEvent(event);
    } else if (deltaTime <= FSAIDuration120) {
      sendEmotionEvent(event);
      print("Send last EAI event and STOP COLLECTING");
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
      print("Send a pageview for a screen change ");
    });
  }

  updateTupleId(String visitorId, String? anonymousId) {
    this.visitorId = visitorId;
    this.anonymousId = anonymousId;
  }
}
