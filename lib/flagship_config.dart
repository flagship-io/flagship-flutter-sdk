import 'package:flagship/cache/default_cache.dart';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/decision/bucketing_manager.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/status.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/model/exposed_flag.dart';
import 'package:flagship/model/visitor_exposed.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "package:flagship/api/service.dart";

// Time out 2 seconds
const TIMEOUT = 2000;

// On user Exposure
typedef OnVisitorExposed = void Function(
    VisitorExposed visitorExposed, ExposedFlag fromFlag)?;

typedef SdkStatusChanged = void Function(FSSdkStatus newStatus)?;

@protected
class FlagshipConfig {
  // Mode
  Mode decisionMode;
  // Timeout
  int timeout = TIMEOUT;
  // Decision Manager
  late DecisionManager decisionManager;
  // LogManager
  LogManager? logManager;
  // Status listner
  SdkStatusChanged onSdkStatusChanged;
  // Callback trigger on flag visitor exposed
  OnVisitorExposed onVisitorExposed;

  // Interval polling time
  int pollingTime = 60; // every 60 seconds will download the script bucketing.

  Level _logLevel;

  TrackingManagerConfig trackingManagerConfig;

  IHitCacheImplementation? hitCacheImp;

  IVisitorCacheImplementation? visitorCacheImp;

  // Data Usage
  bool disableDeveloperUsageTracking;

  FlagshipConfig(this.decisionMode, this.timeout, this.pollingTime,
      this._logLevel, this.onVisitorExposed, this.trackingManagerConfig,
      {this.onSdkStatusChanged,
      this.visitorCacheImp,
      this.hitCacheImp,
      this.disableDeveloperUsageTracking = false}) {
    // Set the log Manager
    this.logManager = LogManager(level: _logLevel);
    // Log the timeout value in ms
    this.logManager?.printLog(Level.INFO,
        "The timeout for fetching campaigns is $timeout: ms", false);

    decisionManager = (decisionMode == Mode.DECISION_API)
        ? ApiManager(Service(http.Client()))
        : BucketingManager(Service(http.Client()), this.pollingTime);

    if (this.hitCacheImp == null) {
      this.hitCacheImp = DefaultCacheHitImp();
    }
    if (this.visitorCacheImp == null) {
      this.visitorCacheImp = DefaultCacheVisitorImp();
    }
  }

  Level getLevel() {
    return _logLevel;
  }
}

class ConfigBuilder {
  // _ Mode
  Mode _mode = Mode.DECISION_API;

  // _timeout
  int _timeout = TIMEOUT;

  // _logLevel
  Level _logLevel = Level.ALL;

  // _pollingTime
  int _pollingTime = 60;

  // _onSdkStatusChanged
  SdkStatusChanged? _onSdkStatusChanged;

  // Tracking Config
  TrackingManagerConfig? _trackingManagerConfig;

  // Cache Hit imp
  IHitCacheImplementation? _hitCacheImp;

  // Cache Visitor Imp
  IVisitorCacheImplementation? _visitorCacheImp;

  OnVisitorExposed? _onVisitorExposed;

  // Data usage developer tracking
  bool _disableDeveloperUsageTracking = false;

  ConfigBuilder();

  ConfigBuilder withMode(Mode newMode) {
    _mode = newMode;
    return this;
  }

  // TimeOut
  ConfigBuilder withTimeout(int newTimeout) {
    _timeout = newTimeout;
    return this;
  }

  // LogLevel
  ConfigBuilder withLogLevel(Level newLevel) {
    _logLevel = newLevel;
    return this;
  }

  // Polling Time
  ConfigBuilder withBucketingPollingIntervals(int newPollingTime) {
    _pollingTime = newPollingTime;
    return this;
  }

  // onSdkStatusChanged
  ConfigBuilder onSdkStatusChanged(SdkStatusChanged pSdkStatusChanged) {
    _onSdkStatusChanged = pSdkStatusChanged;
    return this;
  }

  ConfigBuilder withTrackingConfig(
      TrackingManagerConfig trackingManagerConfig) {
    _trackingManagerConfig = trackingManagerConfig;
    return this;
  }

  ConfigBuilder withCacheHitManager(IHitCacheImplementation hitCacheImp,
      {int hitCacheTimeout = 200}) {
    _hitCacheImp = hitCacheImp;
    _hitCacheImp?.hitCacheLookupTimeout = hitCacheTimeout;
    return this;
  }

  ConfigBuilder withCacheVisitorManager(
      IVisitorCacheImplementation visitorCacheImp,
      {int visitorCacheTimeout = 200}) {
    _visitorCacheImp = visitorCacheImp;
    _visitorCacheImp?.visitorCacheLookupTimeout = visitorCacheTimeout;
    return this;
  }

  // On User exposure
  ConfigBuilder withOnVisitorExposed(OnVisitorExposed pOnVisitorExposed) {
    _onVisitorExposed = pOnVisitorExposed;
    return this;
  }

  // Data usage developer tracking
  ConfigBuilder withDisableDeveloperUsageTracking(
      bool disableDeveloperUsageTracking) {
    _disableDeveloperUsageTracking = disableDeveloperUsageTracking;
    return this;
  }

  FlagshipConfig build() {
    return FlagshipConfig(_mode, _timeout, _pollingTime, _logLevel,
        _onVisitorExposed, _trackingManagerConfig ?? TrackingManagerConfig(),
        onSdkStatusChanged: _onSdkStatusChanged,
        hitCacheImp: _hitCacheImp,
        visitorCacheImp: _visitorCacheImp,
        disableDeveloperUsageTracking: _disableDeveloperUsageTracking);
  }
}
