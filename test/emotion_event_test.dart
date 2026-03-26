import 'package:flagship/emotionAi/emotion_event.dart';
import 'package:flagship/emotionAi/emotion_pageview.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'test_tools.dart';

void main() {
  ToolsTest.sqfliteTestInit();
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

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
    String currentScreen = "currentScreent";
    // Init with current screen
    FSEmotionPageView eventTest = FSEmotionPageView(currentScreen);
    var customParams = eventTest.bodyTrack;
    // Check the category
    expect(customParams['t'], "PAGEVIEW");
    expect(customParams['dl'], currentScreen);
  });
}
