import '../flagship_version.dart';

enum Mode {
  DECISION_API,
  BUCKETING,
}

/// START
const String STARTED = "SDK (version: $FlagshipVersion) is started";
const String INITIALIZATION_PARAM_ERROR = "Params 'envId' is not valide.";
// ToDo: update this wording when the sdk manage other type

// CONTEXT
const String CONTEXT_UPDATE = "Update context with Map %s";
const String CONTEXT_PARAM_ERROR =
    "params 'key' must be a non null String, and 'value' must be one of the " +
        "following types : String, Number, Boolean.";
const String PARSING_ERROR = "An error occured whil parsing ";

// MODIFICATION
const String SYNCHRONIZE_MODIFICATIONS = "SDK - synchronize modifications.";
const String SYNCHRONIZE_MODIFICATIONS_RESULTS =
    "SDK - synchronized modifications are %s";

const String GET_MODIFICATION_ERROR =
    "An error occured while retreiving modification for key '%s'. Default value is returned.";

const String GET_MODIFICATION_INFO_ERROR = "No modification for key '%s'.";

// HITS
const String HIT_SUCCESS = "Hit sent with success";
const String HIT_FAILED = "Failed to send hit";
const String ACTIVATE_SUCCESS = "Activate sent with success";
const String ACTIVATE_FAILED = "Failed to send activate";
const String HIT_INVALID_DATA_ERROR = "'%s' hit invalid format error. \n %s";
const String HIT_NOT_READY = "Not ready to send hits";
const String GETMODIFICATION_NOT_READY =
    "Not ready to get modification, sdk will return the default value";
const String GETMODIFICATION_INFO_NOT_READY =
    "Not ready to get modification infos";
const String ACTIVTAE_NOT_READY = "Not ready to send activate";

// PANIC
const String PANIC = "Panic mode is on.";
const String PANIC_HIT = "Panic mode is on, no event will be sent";
const String PANIC_ACTIVATE = "panic mode is on, the activate is not sent";
const String PANIC_MODIFICATION_INFO =
    "Panic mode is on, no modification infos for key '%s'.";
const String PANIC_MODIFICATION =
    "panic mode is on, will return the default value";
const String PANIC_UPDATE_CONTEXT =
    "Panic mode is on, update context not effective";

const String PANIC_HIT_CONSENT =
    "Panic mode is on, the hit consent is not sent";

// CONSENT
const String CONSENT_HIT = "The user is not consented to send hit";
const String CONSENT_ACTIVATE =
    "The user is not consented to send the actiavte hit";

// REQUEST
const String REQUEST_POST_BODY = "Body of the POST: %s";
const String REQUEST_ERROR = "An error occured while sending the request: %s";

const String REQUEST_TIMEOUT = "Request Timeout: %s";

// EXCEPTION
const String EXCEPTION = "An exception occurred %s";
