// ignore: non_constant_identifier_names
final ALL_USERS = "fs_all_users";

/// Enumeration cases that represent **Predefined** targetings
/// Warning
enum FlagshipContext {
  /// First init of the app
  FIRST_TIME_INIT, // = "sdk_firstTimeInit"

  /// Language of the device
  DEVICE_LOCALE, // = "sdk_deviceLanguage"

  /// Model of the device
  DEVICE_TYPE, //  = "sdk_deviceType"

  /// Tablette / Mobile
  DEVICE_MODEL, // = "sdk_deviceModel"

  /// City geolocation
  LOCATION_CITY, // = "sdk_city"

  /// Region geolocation
  LOCATION_REGION, // = "sdk_region"

  /// Country geolocation
  LOCATION_COUNTRY, // = "sdk_country"

  /// Current Latitude
  LOCATION_LAT, // = "sdk_lat"

  /// Current Longitude
  LOCATION_LONG, // = "sdk_long"

  /// Ip of the device
  IP, //, = "sdk_ip"

  /// Ios
  OS_NAME, //, = "sdk_osName"

  /// The current OS version name in the visitor context. Must be a String.
  OS_VERSION_NAME, //  = "sdk_osVersionName"

  /// The current OS version code in the visitor context.
  OS_VERSION_CODE,

  /// Name of the operator
  CARRIER_NAME, //= "sdk_carrierName"

  /// Is the app in debug mode?
  DEV_MODE, //  = "sdk_devMode"

  /// What is the internet connection
  INTERNET_CONNECTION, //= "sdk_internetConnection"

  /// Version name of the app
  APP_VERSION_NAME, //= "sdk_versionName"

  /// Version code of the app
  APP_VERSION_CODE, // = "sdk_versionCode"

  /// Version FlagShip
  FLAGSHIP_VERSION, //  = "sdk_fsVersion"

  FS_VERSION, //  = "fs_Version"

  /// Name of the interface
  INTERFACE_NAME, // = "sdk_interfaceName"

  FS_CLIENT, // fs_client
}

// Get the key for the relative context
String rawValue(FlagshipContext type) {
  String ret = "";
  switch (type) {
    case FlagshipContext.FIRST_TIME_INIT:
      ret = "sdk_firstTimeInit";
      break;
    case FlagshipContext.DEVICE_LOCALE:
      ret = "sdk_deviceLanguage";
      break;
    case FlagshipContext.DEVICE_TYPE:
      ret = "sdk_deviceType";
      break;
    case FlagshipContext.DEVICE_MODEL:
      ret = "sdk_deviceModel";
      break;
    case FlagshipContext.LOCATION_CITY:
      ret = "sdk_city";
      break;
    case FlagshipContext.LOCATION_REGION:
      ret = "sdk_region";
      break;
    case FlagshipContext.LOCATION_COUNTRY:
      ret = "sdk_country";
      break;
    case FlagshipContext.LOCATION_LAT:
      ret = "sdk_lat";
      break;
    case FlagshipContext.LOCATION_LONG:
      ret = "sdk_long";
      break;
    case FlagshipContext.IP:
      ret = "sdk_ip";
      break;
    case FlagshipContext.OS_NAME:
      ret = "sdk_osName";
      break;
    case FlagshipContext.OS_VERSION_NAME:
      ret = "sdk_osVersionName";
      break;
    case FlagshipContext.OS_VERSION_CODE:
      ret = "sdk_osVersionCode";
      break;
    case FlagshipContext.CARRIER_NAME:
      ret = "sdk_carrierName";
      break;
    case FlagshipContext.DEV_MODE:
      ret = "sdk_devMode";
      break;
    case FlagshipContext.INTERNET_CONNECTION:
      ret = "sdk_internetConnection";
      break;
    case FlagshipContext.APP_VERSION_NAME:
      ret = "sdk_versionName";
      break;
    case FlagshipContext.APP_VERSION_CODE:
      ret = "sdk_versionCode";
      break;
    case FlagshipContext.FLAGSHIP_VERSION:
      ret = "sdk_fsVersion";
      break;
    case FlagshipContext.INTERFACE_NAME:
      ret = "sdk_interfaceName";
      break;
    case FlagshipContext.FS_VERSION:
      ret = "fs_version";
      break;
    case FlagshipContext.FS_CLIENT:
      ret = "fs_client";
      break;
  }
  return ret;
}
