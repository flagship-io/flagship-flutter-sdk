// Called every time the Flag status changes.
typedef OnFlagStatusChanged = void Function(FlagStatus newStatus)?;

// Called every time when the FlagStatus is equals to FETCH_REQUIRED
typedef OnFlagStatusFetchRequired = void Function(
    FetchFlagsRequiredStatusReason reason)?;

// Called every time when the FlagStatus is equals to FETCHED.
typedef OnFlagStatusFetched = void Function()?;

typedef OnFetchFlagsStatusChanged = void Function(
    FlagStatus flagStatus, FetchFlagsRequiredStatusReason fetchReason)?;

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

enum FetchFlagsRequiredStatusReason {
  // Indicate that the visitor is created for the first time or without cache
  FLAGS_NEVER_FETCHED,
  // Indicates that a context has been updated or changed.
  VISITOR_CONTEXT_UPDATED,
  // Indicates that the XPC method 'authenticate' has been called.
  VISITOR_AUTHENTICATED,
  // Indicates that the XPC method 'unauthenticate' has been called.
  VISITOR_UNAUTHENTICATED,
  // Indicates that fetching flags has failed.
  FLAGS_FETCHING_ERROR,
  // Indicates that flags have been fetched from the cache.
  FLAGS_FETCHED_FROM_CACHE,
  // No reason; the state should be  FETCHED,  FETCHING, PANIC
  NONE
}

// Flag Status
enum FlagStatus {
  //Flags have been successfully fetched from the API or re-evaluated in bucketing mode and are up-to-date
  FETCHED,
  // Flags are currently being fetched from the API or re-evaluated in bucketing mode.
  FETCHING,
  // Flags need to be re-fetched due to a change in the visitor context, visitor authentication or because the flags were loaded from cache.
  FETCH_REQUIRED,
  // The flag was not found when creating the flag instance.
  NOT_FOUND,
  // The SDK is in PANIC mode: All features are disabled except for the one to fetch flags. Flags default value will be returned.
  PANIC
}
