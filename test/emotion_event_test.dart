import 'package:flagship/emotionAi/emotion_event.dart';
import 'package:flagship/emotionAi/emotion_pageview.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Test VISITOREVENT object", () {
    String cpStirng = "cpString";
    String cpoString = "cpoString";
    String spoString = "spoString";
    String currentScreen = "currenTtScreent";

    FSEmotionEvent eventTest =
        FSEmotionEvent(cpStirng, cpoString, spoString, currentScreen);

    var customParams = eventTest.bodyTrack;
    // Check the category
    expect(customParams['t'], "VISITOREVENT");
    expect(customParams['cpo'], cpoString);
    expect(customParams['cp'], cpStirng);
    expect(customParams['spo'], spoString);
    expect(customParams['dl'], currentScreen);
  });

  test("Test EmotionPageView object", () {
    String currentScreen = "currenTtScreent";
    // Init with current screen
    FSEmotionPageView eventTest = FSEmotionPageView(currentScreen);

    var customParams = eventTest.bodyTrack;
    // Check the category
    expect(customParams['t'], "VISITOREVENT");
    expect(customParams['dl'], currentScreen);
  });
}
