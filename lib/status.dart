enum FSSdkStatus {
  // Before start the sdk the status is not intialized
  SDK_NOT_INITIALIZED,
  // During the initialization
  SDK_INITIALIZING,
  // The Initialization is done
  SDK_INITIALIZED,
  // The panic mode is ON
  SDK_PANIC
}

// Fetch status
enum FSFetchStatus {
  // The flags have been successfully fetched from the API or re-evaluated in bucketing mode.
  FETCHED,
  // The flags are currently being fetched from the API or re-evaluated in bucketing mode.
  FETCHING,
  // The flags need to be re-fetched due to a change in context, or because the flags were loaded from cache or XPC.
  FETCH_REQUIRED,
  // The SDK is in PANIC mode: All features are disabled except for the one to fetch flags
  PANIC
}

enum FSFetchReasons {
  // Indicate that the visitor is created for the first time or without cache
  VISITOR_CREATE,
  // Indicates that a context has been updated or changed.
  UPDATE_CONTEXT,
  // Indicates that the XPC method 'authenticate' has been called.
  AUTHENTICATE,
  // Indicates that the XPC method 'unauthenticate' has been called.
  UNAUTHENTICATE,
  // Indicates that fetching flags has failed.
  FETCH_ERROR,
  // Indicates that flags have been fetched from the cache.
  FETCHED_FROM_CACHE,
  // No Reason, the state should be  FETCHED,  FETCHING, PANIC
  NONE
}

// Flag Status
enum FlagStatus { FETCHED, FETCH_REQUIRED, NOT_FOUND, PANIC }
