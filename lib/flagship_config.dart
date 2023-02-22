import 'package:flagship/decision/api_manager.dart';
import 'package:flagship/decision/bucketing_manager.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/model/userExposure.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import "package:flagship/api/service.dart";

import 'flagship.dart';

/// Will refarctor this class by using a builder
// Time out 2 seconds
const TIMEOUT = 2000;

// On user Exposure
typedef OnUserExposure = void Function(UserExposure userExposure)?;

typedef StatusListener = void Function(Status newStatus)?;

@protected
class FlagshipConfig {
  // Mode
  Mode decisionMode;
  // Timeout
  int timeout = TIMEOUT;
  // Decision Manager
  late DecisionManager decisionManager;
  // LogManager
  late LogManager logManager;
  // Status listner
  StatusListener statusListener;
  // Callback trigger on flag user exposed
  OnUserExposure onUserExposure;

  // Interval polling time
  int pollingTime = 60; // every 60 seconds will download the script bucketing.

  Level _logLevel;

  FlagshipConfig(this.decisionMode, this.timeout, this.pollingTime,
      this._logLevel, this.onUserExposure,
      {this.statusListener}) {
    // Set the log Manager
    this.logManager = LogManager(level: _logLevel);
    // Log the timeout value in ms
    this.logManager.printLog(Level.ALL, "Flagship The $timeout is : ms", false);

    decisionManager = (decisionMode == Mode.DECISION_API)
        ? ApiManager(Service(http.Client()))
        : BucketingManager(Service(http.Client()), this.pollingTime);
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

  // StatusListener
  StatusListener? _statusListener;

  OnUserExposure? _onUserExposure;

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

  // StatusListener
  ConfigBuilder withStatusListener(StatusListener listener) {
    _statusListener = listener;
    return this;
  }

  // On User exposure
  ConfigBuilder withUserExposureCallback(OnUserExposure pOnUserExposure) {
    _onUserExposure = pOnUserExposure;
    return this;
  }

  FlagshipConfig build() {
    return FlagshipConfig(
        _mode, _timeout, _pollingTime, _logLevel, _onUserExposure,
        statusListener: _statusListener);
  }
}
