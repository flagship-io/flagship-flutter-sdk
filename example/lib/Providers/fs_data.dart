import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flutter/material.dart';

class FSData extends ChangeNotifier {
  // Apikey
  String _apiKey = "apiKey"; //
  // EnvI
  String _envId = "bkk9glocmjcg0vtmdlng"; //
  // Mode
  Mode _mode = Mode.DECISION_API;
  // Timeout
  int _timeout = 2000;

  // Strategy
  BatchCachingStrategy _strategy =
      BatchCachingStrategy.BATCH_CONTINUOUS_CACHING;

  void updateEnvId(String pEnvId) {
    _envId = pEnvId;
    notifyListeners();
  }

  void updateApiKey(String pApiKey) {
    _apiKey = pApiKey;
    notifyListeners();
  }

  void updateSdkMode(Mode pMode) {
    _mode = pMode;
    notifyListeners();
  }

  void updaeTimeout(int pTimeout) {
    _timeout = pTimeout;
    notifyListeners();
  }

  void updateStrategy(BatchCachingStrategy pStrategy) {
    _strategy = pStrategy;
    notifyListeners();
  }

  Mode get sdkMode {
    return _mode;
  }

  String get envId {
    return _envId;
  }

  String get apiKey {
    return _apiKey;
  }

  int get timeout {
    return _timeout;
  }

  BatchCachingStrategy get strategy {
    return _strategy;
  }
}

class UserData extends ChangeNotifier {
  String _visitorId = "flutter_user253";
  Map<String, Object> context = {
    "testing_tracking_manager": true,
    "isQA": true,
    "fs_is_vip": true,
    "customer": "spécial"
  };
  bool _hasConsented = true;
  bool _isAuthenticated = false;

  UserData();

  // Update context
  void updateUserDataCtx(Map<String, Object> inputs) {
    context.addAll(inputs);
    notifyListeners();
  }

  String get visitorId {
    return _visitorId;
  }

  bool get hasConsented {
    return _hasConsented;
  }

  bool get isAuthenticated {
    return _isAuthenticated;
  }

  void updateVisitorId(String pVisitorId) {
    _visitorId = pVisitorId;
    notifyListeners();
  }

  void updateConsent(bool pConsented) {
    _hasConsented = pConsented;
    notifyListeners();
  }

  void updateIsAuthenticated(bool pIsAuthenticated) {
    _isAuthenticated = pIsAuthenticated;
    notifyListeners();
  }
}
