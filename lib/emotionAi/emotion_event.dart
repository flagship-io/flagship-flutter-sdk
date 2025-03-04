import 'dart:ui' as ui;

import 'package:flagship/hits/hit.dart';

/// This function mimics the Swift NumberFormatter that truncates integer digits

/// Dart/Flutter version of your `FSEmotionEvent` class
class FSEmotionEvent extends BaseHit {
  final String cpStirng;
  final String cpoString;
  final String spoString;
  String currentScreen;

  FSEmotionEvent(
      this.cpStirng, this.cpoString, this.spoString, this.currentScreen)
      : super() {
    type = HitCategory.EMOTION_AI;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customParams = new Map<String, Object>();
    // Put the tracking event type
    customParams["t"] = typeOfEvent;
    // cpo field
    customParams["cpo"] = cpoString;
    // cpoString;
    // Cursor and scroll positions
    customParams["cp"] = cpStirng;
    // spo field - click
    customParams["spo"] = spoString;
    // The current screen
    customParams["dl"] = currentScreen;
    // The resolution -- approximate UIScreen.main.bounds in Flutter:
    // For a purely static approach (outside any widget tree):
    final size = ui.window.physicalSize; // physical pixels
    final devicePixelRatio = ui.window.devicePixelRatio;
    final logicalWidth = size.width / devicePixelRatio;
    final logicalHeight = size.height / devicePixelRatio;
    // Or, inside a widget, you could use MediaQuery:
    // final size = MediaQuery.of(context).size;
    // final logicalWidth = size.width;
    // final logicalHeight = size.height;
    final String srValue = "$logicalWidth,$logicalHeight;";
    customParams["sr"] = srValue;
    // Merge in any common tracking fields. Equivalent to .merge(self.communBodyTrack).
    customParams.addAll(communBodyTrack);

    customParams.remove("qt");
    return customParams;
  }
}
