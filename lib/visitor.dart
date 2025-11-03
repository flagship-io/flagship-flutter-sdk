import 'dart:async';
import 'dart:convert';
import 'package:flagship/Targeting/targeting_manager.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/dataUsage/data_usage_tracking.dart';
import 'package:flagship/emotionAi/fs_emotion.dart';
import 'package:flagship/emotionAi/polling_score.dart';
import 'package:flagship/flagshipContext/flagship_context.dart';
import 'package:flagship/flagshipContext/flagship_context_manager.dart';
import 'package:flagship/hits/event.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/visitor_cache/visitor_cache.dart';
import 'package:flagship/tracking/tracking_manager_periodic_strategy.dart';
import 'package:flagship/tracking/tracking_manager_continuous_strategies.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor/visitor_delegate.dart';
import 'package:flagship/model/visitor_flag.dart';
import 'package:flutter/foundation.dart';
import 'flagship_delegate.dart';
import 'package:http/http.dart' as http;
import 'package:flagship/status.dart';

enum Instance {
  // The  newly created visitor instance will be returned and saved into the Flagship singleton. Call `Flagship.getVisitor()` to retrieve the instance.
  // This option should be adopted on applications that handle only one visitor at the same time.
  SINGLE_INSTANCE,

  // The newly created visitor instance wont be saved and will simply be returned. Any previous visitor instance will have to be recreated.
  //  This option should be adopted on applications that handle multiple visitors at the same time.
  NEW_INSTANCE
}

const Duration FSSessionVisitor = Duration(seconds: 1 * 60 * 30); // 30 min

class Visitor with EmotionAiDelegate {
  /// VisitorId
  String visitorId;

  String? anonymousId;

  /// Configuration
  final FlagshipConfig config;

  /// Context
  Map<String, Object> _context = {};

  /// Get context
  Map<String, Object> getContext() {
    return _context;
  }

  /// Map for the modification , {"key for the flag": Modification object}
  Map<String, Modification> modifications = {};

  /// Core decision manager , can manage both modes for the sdk
  DecisionManager get decisionManager {
    return this.config.decisionManager;
  }

  TrackingManager? trackingManager;

  /// Consent by default is true
  bool _hasConsented = true;

  /// Experience Continuity
  bool _isAuthenticated;

  /// AssignmentsHistory history
  Map<String, dynamic> assignmentsHistory = {};

  /// Delegate visitor

  late VisitorDelegate _visitorDelegate;

  /// Delegate to update the status
  final FlagshipDelegate flagshipDelegate = Flagship.sharedInstance();

  /// flagSyncStatus
  FlagSyncStatus _flagSyncStatus = FlagSyncStatus.CREATED;

  /// DataUsageTracking
  DataUsageTracking dataUsageTracking = DataUsageTracking.sharedInstance();

  // Fetch status
  FlagStatus _flagStatus = FlagStatus.FETCH_REQUIRED;

  // FSFetchReasons
  FetchFlagsRequiredStatusReason _fetchReasons =
      FetchFlagsRequiredStatusReason.FLAGS_NEVER_FETCHED;

  // Callback for status
  OnFlagStatusChanged _onFlagStatusChanged;

  // _onFlagStatusFetchRequired
  OnFlagStatusFetchRequired _onFlagStatusFetchRequired;

  // _onFlagStatusFetched
  OnFlagStatusFetched _onFlagStatusFetched;

  // Add this flag to track if visitor lookup has been performed
  bool _needLookupVisitor = true;

// Get flagStatus
  FlagStatus get flagStatus {
    return _flagStatus;
  }

  // EmotionAI
  EmotionAI? emotion_ai;

  // Is the visitor is scored
  bool eaiVisitorScored = false;
  // the score value
  String? emotionScoreAI = null;

// Get fetchReasons
  FetchFlagsRequiredStatusReason get fetchReasons {
    return _fetchReasons;
  }

  set flagStatus(FlagStatus newValue) {
    if (newValue != this._flagStatus) {
      this._flagStatus = newValue;
      _onFlagStatusChanged?.call(this.flagStatus);
    }

    // Og the state is required then trigger also the required callback
    if (newValue == FlagStatus.FETCH_REQUIRED) {
      _onFlagStatusFetchRequired?.call(this._fetchReasons);
    } else if (newValue == FlagStatus.FETCHED) {
      // If the state is fetched then trigger the callback fetched
      _onFlagStatusFetched?.call();
    }
  }

  // Init the sesssion
  DateTime sessionDuration = DateTime.now();

  // Create new instance for visitor
  Visitor(
      this.config,
      this.visitorId,
      this._isAuthenticated,
      Map<String, Object> context,
      this._hasConsented,
      this._onFlagStatusChanged,
      this._onFlagStatusFetchRequired,
      this._onFlagStatusFetched) {
    if (_isAuthenticated == true) {
      this.anonymousId = FlagshipTools.generateFlagshipId();
    } else {
      anonymousId = null;
    }

    // Init Tracking manager
    switch (config.trackingManagerConfig.batchStrategy) {
      case BatchCachingStrategy.BATCH_CONTINUOUS_CACHING:
        trackingManager = TrackingManageContinuousStrategy(
            Service(http.Client()),
            config.trackingManagerConfig,
            this.config.hitCacheImp ?? DefaultCacheHitImp());
        break;
      case BatchCachingStrategy.BATCH_PERIODIC_CACHING:
        trackingManager = TrackingManagerPeriodicStrategy(
            Service(http.Client()),
            config.trackingManagerConfig,
            this.config.hitCacheImp ?? DefaultCacheHitImp());
        break;
      default:
        trackingManager = TrackingManager(Service(http.Client()),
            config.trackingManagerConfig, DefaultCacheHitImp());
        break;
    }

    // Load preset_Context
    this.updateContextWithMap(FlagshipContextManager.getPresetContextForApp());

    // Set visitorId into the context
    context.addEntries({FS_USERS: visitorId}.entries);

    // Update context
    this.updateContextWithMap(context);

    // Set delegate
    _visitorDelegate = VisitorDelegate(this);

    // Set the consent
    _hasConsented; //= hasConsented;

    // Load the hits in cache if exist
    _visitorDelegate.lookupHits();

    // Lookup for the cached visitor data
    // _visitorDelegate.lookupVisitor(this.visitorId).then((isLoadedFromCache) => {
    //       this._fetchReasons = isLoadedFromCache
    //           ? FetchFlagsRequiredStatusReason.FLAGS_FETCHED_FROM_CACHE
    //           : FetchFlagsRequiredStatusReason.FLAGS_NEVER_FETCHED
    //     });
    // _visitorDelegate.lookupVisitor(this.visitorId).whenComplete(() {});

    /// Send the consent hit
    _visitorDelegate.sendHit(Consent(hasConsented: _hasConsented));

    DataUsageTracking.sharedInstance()
        .configureDataUsageWithVisitor(null, this);
  }

  // Update context directely with map for <String, Object>
  void clearContext() {
    sessionDuration = DateTime.now();
    _context.clear();
  }

  // Update context directely with map for <String, Object>
  void updateContextWithMap(Map<String, Object> context) {
    sessionDuration = DateTime.now();
    var oldContext = Map.fromEntries(_context.entries);
    _context.addAll(context);
    if (mapEquals(oldContext, _context) == false) {
      // if the context still the same then no need to raise the warning
      // Update flagSyncStatus to raise a warning when access to flag
      this._flagSyncStatus = FlagSyncStatus.CONTEXT_UPDATED;
      flagStatus = FlagStatus.FETCH_REQUIRED;
      _fetchReasons = FetchFlagsRequiredStatusReason.VISITOR_CONTEXT_UPDATED;
    }

    Flagship.logger(
        Level.DEBUG, CONTEXT_UPDATE.replaceFirst("%s", "$_context"));
  }

  /// Get the current context for the visitor
  ///
  /// Return a Map that represent the current context
  Map<String, Object> getCurrentContext() {
    return _context;
  }

  /// Update context with key and value
  ///
  /// key the name for the context (attribut)
  /// value can be int, double, String or boolean
  /// otherwise the update context skip with warnning log

  void updateContext<T>(String key, T value) {
    sessionDuration = DateTime.now();
    var oldContext = Map.fromEntries(_context.entries);

    /// Delegate the action to strategy to update
    _visitorDelegate.updateContext(key, value);
    // Check the eqaulity before raise the warning
    if (mapEquals(oldContext, _context) == false) {
      // if the context still the same then no need to raise the warning
      // Update flagSyncStatus to raise a warning when access to flag
      this._flagSyncStatus = FlagSyncStatus.CONTEXT_UPDATED;

      this.flagStatus = FlagStatus.FETCH_REQUIRED;
      this._fetchReasons =
          FetchFlagsRequiredStatusReason.VISITOR_CONTEXT_UPDATED;
    }
  }

  /// Update with predefined context
  void updateFlagshipContext<T>(FlagshipContext flagshipContext, T value) {
    sessionDuration = DateTime.now();
    if (FlagshipContextManager.chekcValidity(flagshipContext, value)) {
      updateContext(rawValue(flagshipContext), value);
    } else {
      Flagship.logger(Level.ERROR,
          "Skip updating the context with predefined context ${flagshipContext.name} ..... the value is not valid");
    }
  }

  // Get Flag
  // - Return Flag instance
  Flag getFlag<T>(String key) {
    sessionDuration = DateTime.now();
    if (_flagSyncStatus != FlagSyncStatus.FLAGS_FETCHED) {
      Flagship.logger(
          Level.ALL, _flagSyncStatus.warningMessage(visitorId, key));
    }
    return Flag(key, this._visitorDelegate);
  }

  // Get the colllection flags
  /// - Returns: an instance of FSFlagCollection with flags
  FlagCollection getFlags() {
    sessionDuration = DateTime.now();
    Map<String, Flag> ret = {};

    this.modifications.forEach((keyItem, modifItem) {
      ret.addAll({keyItem: Flag(keyItem, this._visitorDelegate)});
    });
    return FlagCollection(this._visitorDelegate, ret);
  }

  // Private function to handle visitor lookup logic
  Future<void> _performVisitorLookupIfNeeded() async {
    if (!_needLookupVisitor)
      return; // temporary disable to always lookup visitor

    String? idToLookup;

    // First check if visitorId exists in cache using config
    bool visitorExists =
        await config.visitorCacheImp?.visitorExists(visitorId) ?? false;

    if (visitorExists) {
      idToLookup = visitorId;
    } else if (anonymousId != null) {
      // If visitorId doesn't exist but we have anonymousId, check if it exists
      bool anonymousExists =
          await config.visitorCacheImp?.visitorExists(anonymousId!) ?? false;
      if (anonymousExists) {
        idToLookup = anonymousId!;
      }
    }
    // Only perform lookup if we found an existing ID
    if (idToLookup != null) {
      await _visitorDelegate
          .lookupVisitor(idToLookup)
          .then((isLoadedFromCache) {
        this._fetchReasons = isLoadedFromCache
            ? FetchFlagsRequiredStatusReason.FLAGS_FETCHED_FROM_CACHE
            : FetchFlagsRequiredStatusReason.FLAGS_NEVER_FETCHED;
        this._needLookupVisitor = false;
      });
    } else {
      // No existing visitor found, set appropriate fetch reason
      this._fetchReasons = FetchFlagsRequiredStatusReason.FLAGS_NEVER_FETCHED;
      this._needLookupVisitor = false;
    }
  }

  Future<void> fetchFlags() async {
    sessionDuration = DateTime.now();

    /// Delegate the action to strategy
    this.flagStatus = FlagStatus.FETCHING;

    // Only lookup visitor if it is necessary
    await _performVisitorLookupIfNeeded();

    return _visitorDelegate.fetchFlags().then((fetchResponse) {
      if (fetchResponse?.error == null) {
        _flagSyncStatus = FlagSyncStatus.FLAGS_FETCHED;
        this.flagStatus =
            fetchResponse?.fetchStatus ?? FlagStatus.FETCH_REQUIRED;
        this._fetchReasons = FetchFlagsRequiredStatusReason.NONE;
      } else {
        this.flagStatus =
            fetchResponse?.fetchStatus ?? FlagStatus.FETCH_REQUIRED;
        this._fetchReasons =
            FetchFlagsRequiredStatusReason.FLAGS_FETCHING_ERROR;
      }
    });
  }

  /// Send hit
  Future<void> sendHit(BaseHit hit) async {
    sessionDuration = DateTime.now();
    // Delegate the action to strategy
    _visitorDelegate.sendHit(hit);
  }

  /// Set Consent
  void setConsent(bool newValue) {
    sessionDuration = DateTime.now();
    // flush the hits from the pool
    if (newValue == false) {
      this.trackingManager?.flushAllTracking(this.visitorId);
      // Erase the related data in cache
      this.config.visitorCacheImp?.flushVisitor(this.visitorId);
    }
    // Update the state for visitor
    _hasConsented = newValue;

    // Delegate the action to strategy
    _visitorDelegate.setConsent(_hasConsented);

    // Update the value for the data usage tracking
    dataUsageTracking.updateConsent(newValue);
  }

  // Get consent
  bool getConsent() {
    return _hasConsented;
  }

  ///   Use authenticate methode to go from Logged-out session to logged-in session
  ///
  /// - Parameters:
  ///      - visitorId: newVisitorId to authenticate
  /// - Important: After using this method, you should use Flagship.fetchFlags method to update the visitor informations
  /// - Requires: Make sure that the experience continuity option is enabled on the flagship platform before using this method

  authenticate(String visitorId) {
    sessionDuration = DateTime.now();
    _needLookupVisitor = true;
    _isAuthenticated = true;
    _visitorDelegate.getStrategy().authenticateVisitor(visitorId);
    this.flagStatus = FlagStatus.FETCH_REQUIRED;
    this._fetchReasons = FetchFlagsRequiredStatusReason.VISITOR_AUTHENTICATED;
    // Update flagSyncStatus
    this._flagSyncStatus = FlagSyncStatus.AUTHENTICATED;
  }

  /// Use authenticate methode to go from Logged in  session to logged out session
  unauthenticate() {
    sessionDuration = DateTime.now();
    _needLookupVisitor = true;
    _isAuthenticated = false;
    _visitorDelegate.getStrategy().unAuthenticateVisitor();
    this.flagStatus = FlagStatus.FETCH_REQUIRED;
    this._fetchReasons = FetchFlagsRequiredStatusReason.VISITOR_UNAUTHENTICATED;
    // Update flagSyncStatus
    this._flagSyncStatus = FlagSyncStatus.UNAUTHENTICATED;
  }

// Is the visitor is autenticated
  bool isAuthenticated() {
    return _isAuthenticated;
  }

  @visibleForTesting
  FlagSyncStatus getFlagSyncStatus() {
    sessionDuration = DateTime.now();
    return _flagSyncStatus;
  }

  // Add emotionAI function
  collectEmotionsAIEvents(String screenName) {
    sessionDuration = DateTime.now();
    if (Flagship.sharedInstance().eaiCollectEnabled == true) {
      if (eaiVisitorScored == true) {
        Flagship.logger(Level.INFO,
            "The visitor $visitorId is already collected and scored");
      } else {
        this._visitorDelegate.collectEmotionsAIEvents(screenName);
      }
    } else {
      Flagship.logger(Level.INFO, "The Emotion AI feature is not activated ");
    }
  }

  onAppScreenChange(String screenName) {
    if (Flagship.sharedInstance().eaiCollectEnabled == true &&
        this.eaiVisitorScored == false) {
      this._visitorDelegate.onAppScreenChange(screenName);
    }
  }

  @override
  void emotionAiCaptureCompleted(score) {
    Flagship.logger(Level.INFO,
        "The delegate with score \($score ?? \"null\" has been called");
    this.eaiVisitorScored = (score == null) ? false : true;

    if (Flagship.sharedInstance().eaiActivationEnabled) {
      this.emotionScoreAI = score;
      // Update the context
      if (score != null) {
        this.updateContext("eai::eas", score);
      }
    } else {
      Flagship.logger(Level.INFO,
          "eaiActivationEnabled is false will not communicate the score value");
    }
    // save to cache
    _visitorDelegate.getStrategy().cacheVisitor(
        visitorId, jsonEncode(VisitorCache.fromVisitor(this).toJson()));
  }
}

// Builder
class VisitorBuilder {
  final String visitorId;

  final Instance instanceType;

// Context
  Map<String, Object> _context = {};

// Has consented
  bool _hasConsented; //= true;

// Xpc by default false
  bool _isAuthenticated = false;

// Callback status fetch

  OnFlagStatusChanged _onFlagStatusChanged;

  OnFlagStatusFetchRequired _onFlagStatusFetchRequired;

  OnFlagStatusFetched _onFlagStatusFetched;

  VisitorBuilder(this.visitorId, this._hasConsented,
      {this.instanceType = Instance.SINGLE_INSTANCE});

// Context
  VisitorBuilder withContext(Map<String, Object> context) {
    _context = context;
    return this;
  }

  VisitorBuilder isAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    return this;
  }

  // Visitor flags status callback
  VisitorBuilder withOnFlagStatusChanged(OnFlagStatusChanged pCallback) {
    _onFlagStatusChanged = pCallback;
    return this;
  }

  VisitorBuilder withOnFlagStatusFetchRequired(
      OnFlagStatusFetchRequired pCallback) {
    _onFlagStatusFetchRequired = pCallback;
    return this;
  }

  VisitorBuilder withOnFlagStatusFetched(OnFlagStatusFetched pCallBack) {
    _onFlagStatusFetched = pCallBack;
    return this;
  }

  Visitor build() {
    Visitor newVisitor = Visitor(
        Flagship.sharedInstance().getConfiguration() ?? ConfigBuilder().build(),
        visitorId,
        _isAuthenticated,
        _context,
        _hasConsented,
        _onFlagStatusChanged,
        _onFlagStatusFetchRequired,
        _onFlagStatusFetched);
    if (this.instanceType == Instance.SINGLE_INSTANCE) {
      //Set this visitor as shared instance
      Flagship.setCurrentVisitor(newVisitor);
    }
    return newVisitor;
  }
}
