import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_device_type/flutter_device_type.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class FSDevice {
  // Load thoses infos when start flagship becasue an async

  // Device Model
  static String? deviceModel;
  // Is first time of use
  static bool isFirstTimeSdkUse = false;

  static String? getDeviceLanguage() {
    return Platform.localeName;
  }

  static isFirstTimeUser() async {
    await SharedPreferences.getInstance().then((value) {
      bool? startedBefore = value.getBool("isFirstTimeUser");
      if (startedBefore == null) {
        value.setBool("isFirstTimeUser", true);
        isFirstTimeSdkUse = true;
        return true;
      }
    });
  }

  static Future<String?> getDeviceModel() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid == true) {
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      return androidInfo.model;
    } else if (Platform.isIOS == true) {
      IosDeviceInfo iphoneInfo = await deviceInfo.iosInfo;
      return iphoneInfo.model;
    }
    return null;
  }

  static String? getSystemVersionName() {
    return Platform.operatingSystem;
  }

  static String? getSystemVersion() {
    return Platform.operatingSystemVersion;
  }

  static String getDeviceType() {
    return (Device.get().isPhone == true) ? "Mobile" : "Tablet";
  }

  static loadDeviceInfo() async {
    await getDeviceModel().then((value) {
      deviceModel = value;
    });
    await isFirstTimeUser();
  }
}
