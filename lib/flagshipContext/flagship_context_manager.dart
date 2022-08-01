import 'package:flagship/flagshipContext/flagship_context.dart';
import 'package:flagship/flagship_version.dart';
import 'package:flagship/utils/device_tools.dart';

class FlagshipContextManager {
  static Map<String, Object> getPresetContextForApp() {
    Map<String, Object> result = {};
    FlagshipContext.values.forEach((element) {
      Object? val = getValue(element);
      if (val != null) {
        result.addAll({rawValue(element): val});
      }
    });
    return result;
  }

  static Object? getValue(FlagshipContext type) {
    switch (type) {
      case FlagshipContext.DEVICE_LOCALE:
        return FSDevice.getDeviceLanguage();
      case FlagshipContext.FIRST_TIME_INIT:
        return FSDevice.isFirstTimeSdkUse;
      case FlagshipContext.DEVICE_TYPE:
        return FSDevice.getDeviceType();
      case FlagshipContext.DEVICE_MODEL:
        return FSDevice.deviceModel;
      case FlagshipContext.OS_NAME:
      case FlagshipContext.OS_VERSION_NAME:
        return FSDevice.getSystemVersionName();
      case FlagshipContext.OS_VERSION_CODE:
        return FSDevice.getSystemVersion();
      case FlagshipContext.FLAGSHIP_VERSION:
        return FlagshipVersion;
      // Set by the client
      case FlagshipContext.LOCATION_CITY:
      case FlagshipContext.LOCATION_REGION:
      case FlagshipContext.LOCATION_COUNTRY:
      case FlagshipContext.LOCATION_LAT:
      case FlagshipContext.LOCATION_LONG:
      case FlagshipContext.IP:
      case FlagshipContext.CARRIER_NAME:
      case FlagshipContext.INTERNET_CONNECTION:
      case FlagshipContext.APP_VERSION_NAME:
      case FlagshipContext.APP_VERSION_CODE:
      case FlagshipContext.INTERFACE_NAME:
      case FlagshipContext.DEV_MODE:
        return null;
    }
  }

  bool chekcValidity(dynamic valueToSet) {
    return true;
  }
}
