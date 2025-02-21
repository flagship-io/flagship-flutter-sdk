import 'dart:ui';
import 'package:flagship/emotionAi/emotion_tools.dart';
import 'package:flagship/hits/page.dart';

/// A helper class simulating FSTools from Swift.
class FSTools {
  /// Example: returns the number of bits per pixel. (Assumed value)
  static int getBitsPerPixel() => 32;

  /// Returns the amount of time offset in minutes from UTC.
  static int getAmountTimeInMinute() {
    return DateTime.now().timeZoneOffset.inMinutes;
  }
}

/// A helper class simulating FSDevice from Swift.
class FSDevice {
  /// Returns the device language using the current window locale.
  static String? getDeviceLanguage() {
    return window.locale.languageCode;
  }

  /// Returns a simplified device type. You can expand this logic as needed.
  static String getDeviceType() {
    // For example, you could implement logic to differentiate phones from tablets.
    return "Mobile";
  }
}

/// Converted FSEmotionPageView from Swift into a Dart class.
/// It extends FSPage and overrides the body's tracking info.
class FSEmotionPageView extends Page {
  FSEmotionPageView(String location) : super(location: location);

  @override
  Map<String, Object> get bodyTrack {
    final Map<String, Object> customParams = <String, Object>{};

    // Retrieve window information using Flutter's WidgetsBinding.
    final window = EmotionAITools.getInstanceWindow();

    // Logical (device-independent) screen dimensions.
    final logicalWidth = window.physicalSize.width / window.devicePixelRatio;
    final logicalHeight = window.physicalSize.height / window.devicePixelRatio;

    // Size of the window browser (equivalent to UIScreen.main.bounds in Swift)
    final srValue = '$logicalWidth,$logicalHeight;';
    customParams["sr"] = srValue;

    // Viewport represented using physical resolution (equivalent to nativeBounds)
    customParams["vp"] =
        '[${window.physicalSize.width},${window.physicalSize.height}]';

    // Does the user have an adblock? (example: default false)
    customParams["adb"] = false;

    // Number of bits per pixel for the user's machine.
    customParams["sd"] = "${FSTools.getBitsPerPixel()}";

    // Browser configuration on user tracking preference.
    customParams["dnt"] = 'unknown';

    // List of installed fonts.
    // Flutter does not support enumerating installed fonts at runtime.
    // In Swift the code stringifies UIFont.familyNames.
    // Here you might return a hardcoded value or an empty list.
    customParams["fnt"] = "[\"Andale Mono\", \"Arial\"]";

    // Fake browser infos.
    customParams["hlb"] = false;
    // Fake OS infos.
    customParams["hlo"] = false;
    // Fake resolution infos.
    customParams["hlr"] = false;
    // Fake language infos.
    customParams["hll"] = true;

    // Browser language.
    customParams["ul"] = FSDevice.getDeviceLanguage() ?? "";

    // Machine type of the user.
    customParams["dc"] = FSDevice.getDeviceType();

    // Ratio between physical pixels and device-independent pixels.
    customParams["pxr"] = window.devicePixelRatio.toInt();

    // Offset from UTC in minutes.
    customParams["tof"] = FSTools.getAmountTimeInMinute();

    // tsp: a placeholder value.
    customParams["tsp"] = '[0,false,false]';

    // Send an empty list for plu.
    customParams["plu"] = '[]';

    // Send empty strings for ua and dr.
    customParams["ua"] = '';
    customParams["dr"] = '';

    // Merge with parent's tracking info.
    customParams.addAll(super.bodyTrack);

    // Remove 'qt' if it exists.
    customParams.remove('qt');

    return customParams;
  }
}
