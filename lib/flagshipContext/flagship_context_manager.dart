import 'package:flagship/flagshipContext/flagship_context.dart';

class FlagshipContextManager {
  static Map<String, dynamic> getPresetContextForApp() {
    Map<String, dynamic> result = {};

    FlagshipContext.values.forEach((element) {
      if (getValue(element) != null) {
        result.addEntries({rawValue(element): getValue(element)}.entries);
      }
    });
    return result;
  }

  static dynamic getValue(FlagshipContext type) {
    switch (type) {

      //     // Automatically set by the sdk
      // case FlagshipContext.DEVICE_LOCALE:

      //   //  return FSDevice.getDeviceLanguage()

      //     // Automatically set by the sdk
      // case .DEVICE_TYPE:
      //    // return  FSDevice.getDeviceType()

      //     // Automatically set by the sdk
      // case .DEVICE_MODEL:
      //    // return  FSDevice.getDeviceModel()

      //     /// Set by the client Geolocation
      // case .LOCATION_CITY, .LOCATION_REGION, .LOCATION_COUNTRY, .LOCATION_LAT, .LOCATION_LONG, .IP:
      //    // return FlagshipContextManager.readValueFromPreDefinedContext(self)

      //     // Automatically set by the sdk
      // case .OS_NAME:
      //      //return OSName

      //     // Automatically set by the sdk
      // case .OS_VERSION_CODE,.OS_VERSION:
      //     //return FSDevice.getSystemVersion()

      // case .OS_VERSION_NAME:

      //     // set by the client
      //    // return FSDevice.getSystemVersionName()

      //     // Set by the client
      // case .CARRIER_NAME:
      //    // return FlagshipContextManager.readValueFromPreDefinedContext(self)

      //     /// Set by the client
      // case .DEV_MODE:
      //      // return FlagshipContextManager.readValueFromPreDefinedContext(self)

      //     // Automatically set by the sdk
      // case .FIRST_TIME_INIT:
      //   //  return FSDevice.isFirstTimeUser()

      //     /// Set by the client
      // case .INTERNET_CONNECTION, .APP_VERSION_NAME, .APP_VERSION_CODE :
      //    //  return FlagshipContextManager.readValueFromPreDefinedContext(self)

      //     /// Automatically set by the sdk
      // case .FLAGSHIP_VERSION:

      //     // return FlagShipVersion

      //      /// Set by the client
      // case .INTERFACE_NAME:
      //      // return FlagshipContextManager.readValueFromPreDefinedContext(self)
      case FlagshipContext.FIRST_TIME_INIT:
        // TODO: Handle this case.
        break;
      case FlagshipContext.DEVICE_TYPE:
        // TODO: Handle this case.
        break;
      case FlagshipContext.DEVICE_MODEL:
        // TODO: Handle this case.
        break;
      case FlagshipContext.LOCATION_CITY:
        // TODO: Handle this case.
        break;
      case FlagshipContext.LOCATION_REGION:
        // TODO: Handle this case.
        break;
      case FlagshipContext.LOCATION_COUNTRY:
        // TODO: Handle this case.
        break;
      case FlagshipContext.LOCATION_LAT:
        // TODO: Handle this case.
        break;
      case FlagshipContext.LOCATION_LONG:
        // TODO: Handle this case.
        break;
      case FlagshipContext.IP:
        // TODO: Handle this case.
        break;
      case FlagshipContext.OS_NAME:
        // TODO: Handle this case.
        break;
      case FlagshipContext.OS_VERSION_NAME:
        // TODO: Handle this case.
        break;
      case FlagshipContext.OS_VERSION_CODE:
        // TODO: Handle this case.
        break;
      case FlagshipContext.CARRIER_NAME:
        // TODO: Handle this case.
        break;
      case FlagshipContext.DEV_MODE:
        // TODO: Handle this case.
        break;
      case FlagshipContext.INTERNET_CONNECTION:
        // TODO: Handle this case.
        break;
      case FlagshipContext.APP_VERSION_NAME:
        // TODO: Handle this case.
        break;
      case FlagshipContext.APP_VERSION_CODE:
        // TODO: Handle this case.
        break;
      case FlagshipContext.FLAGSHIP_VERSION:
        // TODO: Handle this case.
        break;
      case FlagshipContext.INTERFACE_NAME:
        // TODO: Handle this case.
        break;
      case FlagshipContext.DEVICE_LOCALE:
        // TODO: Handle this case.
        break;
    }
    return "";
  }

  bool chekcValidity(dynamic valueToSet) {
    return true;
  }
}
