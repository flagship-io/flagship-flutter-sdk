
# 4.1.2-beta - 24/06/2025

### Fix
- Add information in visitor context: 'fs_users', 'fs_client', 'fs_version'.
- Handle special characters on decoding.

# 4.1.0-beta - 07/04/2025
### Added

- Emotion AI collect method `collectEmotionsAIEvents` in visitor instance
- Emotion AI `onAppScreenChange` method to update the name of the screen being displayed during the collect process
- The EmotionAI features are covered by troubleshooting hits in order to debug and examine any issues that may arise.

# 4.0.0 - 10/08/2024
  ### Changed 
-   The `Flag getFlag<T>(String key)` is the new signature for the getFlag method .
-   The `func value<T>(defaultValue:T?,visitorExposed: Bool = true)->T?` is the new signature for flag.value() method .
-   Signature `newVisitor` method builder changed to `VisitorBuilder newVisitor({required String visitorId, required bool hasConsented, Instance instanceType = Instance.SINGLE_INSTANCE})`.
-   `hasConsented` parameter is mandatory on visitor creation instance.
-   Enum SDK status `FSSdkStatus` has replaced `FStatus`.
- `withStatusListener` renamed to `onSdkStatusChanged`.
 
**For further information, see [migration](https://docs.developers.flagship.io/docs/flutter-migration-to-4x) code.**

### Added
-  Flag status
-  Visitor status
- `getFlags()` new method to get all flags in one collection as `FSFlagCollection`
- `FlagCollection` is a collection of flag `Map<String, Flag>`
**For further information, see [4.0.0](https://docs.developers.flagship.io/docs/flutter-reference) reference.**

### Removed 
 Deprecated methods: 
```
- synchronizeModifications
- getModification
- getModificationInfo 
- activateModification
- userExposed
```

# 3.1.2 - 06/02/2024

- Bug fixes on Troubleshooting and Developer Usage hits

# 3.1.1 - 16/01/2024

- Return the correct flag value from value() method when null is given as default value or when the value for flag is null

# 3.1.0 - 08/11/2023

- Troubleshooting mode : If you are experiencing issues while using the SDK, we are now able to gather logs and information to help you.
- Developer Usage Tracking :The SDK collects data to help us improve the product.

# 3.0.4 - 28/09/2023

#### Added

-  Add campaignName, variationGroupName and variationName in flags & campaigns metadata

# 3.0.3 - 12/09/2023

#### Added

- New warnings logs when flags are out of date

# 3.0.2 - 27/07/2023

#### Fixed

- Correct typo "trackingMangerConfig" to "trackingManagerConfig

# 3.0.1 - 03/07/2023

Added

- Page, hit tracking for embedded web view

- qt field in activate batch it indicate the time duration between the occurrence sending.

# 3.0.0 - 16/03/2023

Added

- Preventing from a data lost and bandwidth hogs. See Config Tracking Manager for more information.

- Dealing with offline mode. Managing visitor cache

- Customisable interfaces IVisitorCacheImplementation & IHitCacheImplementation to control data. A default implementation is provided by the SDK.

# 2.1.0 - 02/03/2023

Added

- onVisitorExposed callback in SDK configuration.

Changed

- Deprecate userExposed(). Use visitorExposed() instead.

# 2.0.1 - 04/01/2023

Added

- visitor_consent key in body of the campaign request

# 2.0.0 - 2022-10-03

Added

- Bucketing Mode
- Experience Continuity
- Predefined context
- VisitorBuilder class to manage options
- ConfigBuilder class to create a FlagshipConfig instance and manage options

# 1.3.0 - 2022-06-22

Added

- Flag class to manipulate Flag

Changed

- synchronizeModification is now deprecated, use fetchFlags function through the visitor instance
- getModification / getModificationInfo / activateModification are now obsolete and have been replaced by Flag class

# 1.2.0 - 2022-03-24

Added

- Callback (status listener), called when SDK status has changed
- Improve FlagshipConfig class and manage listener status

# 1.1.3 - 2022-01-26

Changed

- Imporove synchronize modificaation function
- Improve logs

# 1.1.2 - 2022-01-17

Fixed

- Configuration when the current visitor is not Set

# 1.1.1 - 2021-11-25

Added

- Unit tests and secure code

# 1.1.0 - 2021-09-29

Added

- Visitor consent management

# 1.0.0 - 2021-07-19

Added

- logManager to manage logs
- FlagshipConfig object to customize the timeout and the logger

# 0.2.1 - 2021-06-23

Added

- [Panic Mode](https://developers.flagship.io/docs/glossary#panic-mode)

# 0.2.0 - 2021-05-17

Changed

- Refactor naming of the constants & hits to remove FS prefix

# 0.1.3 - 2020-05-15

Added

Implement generics for visitor methods:

- getModification
- updateContext

# 0.1.2

Changed

- `ctax` for `tax` in Transaction hit.

# 0.1.1

Added

- optional constructor parameters for Hits

# 0.1.0

First implementation of the SDK with minimal features:
Added

- Initialization
- Visitor & context management
- Synchronization
- Modification helpers
- Hit tracking
