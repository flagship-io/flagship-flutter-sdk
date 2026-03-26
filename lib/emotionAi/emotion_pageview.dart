import 'package:flagship/emotionAi/emotion_tools.dart';
import 'package:flagship/hits/page.dart';
import 'package:flagship/utils/device_tools.dart';
import 'package:flagship/utils/flagship_tools.dart';

class FSEmotionPageView extends Page {
  FSEmotionPageView(String location) : super(location: location);

  @override
  Map<String, Object> get bodyTrack {
    final Map<String, Object> customParams = <String, Object>{};

    // Size of the of the window  ex: 1516,464;
    customParams["sr"] = EmotionAITools.getSrValueScreen();

    // Retrieve window information using platformDispatcher.
    final window = EmotionAITools.getInstanceWindow();

    // Viewport represented using physical resolution
    customParams["vp"] =
        '[${window?.physicalSize.width},${window?.physicalSize.height}]';

    // Does the user have an adblock?
    customParams["adb"] = false;

    // Number of bits per pixel for the user's machine.
    customParams["sd"] = "${FlagshipTools.getBitsPerPixel()}";

    // Browser configuration on user tracking preference.
    customParams["dnt"] = 'unknown';

    // List of installed fonts.
    customParams["fnt"] = '[]';
    // Fake browser infos.
    customParams["hlb"] = false;
    // Fake OS infos.
    customParams["hlo"] = false;
    // Fake resolution infos.
    customParams["hlr"] = false;
    // Fake language infos.
    customParams["hll"] = true;

    // Browser language.
    customParams["ul"] = FSDevice.getDevicelanguageCode();

    // Machine type of the user.
    customParams["dc"] = FSDevice.getDeviceType();

    // Ratio between physical pixels and device-independent pixels.
    customParams["pxr"] = window?.devicePixelRatio.toInt() ?? "";

    // Offset from UTC in minutes.
    customParams["tof"] = FlagshipTools.getAmountTimeInMinute();

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
