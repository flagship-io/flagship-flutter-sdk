import 'package:flagship/emotionAi/emotion_tools.dart';
import 'package:flagship/hits/hit.dart';

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
    // Cursor and scroll positions
    customParams["cp"] = cpStirng;
    // spo field - click
    customParams["spo"] = spoString;
    // The current screen
    customParams["dl"] = currentScreen;
    // Size of the of the window ex: 1516,464;
    customParams["sr"] = EmotionAITools.getSrValueScreen();
    // Merge in any common tracking fields
    customParams.addAll(communBodyTrack);

    customParams.remove("qt");
    return customParams;
  }
}
