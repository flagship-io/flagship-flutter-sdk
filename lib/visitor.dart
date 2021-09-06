import 'dart:async';
import 'package:flagship/hits/event.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/api/tracking_manager.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor/visitor_delegate.dart';

import 'flagship_delegate.dart';

class Visitor {
  // VisitorId
  final String visitorId;

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

  TrackingManager trackingManager = TrackingManager();

  //Consent by default is true
  bool _hasConsented = true;

  // delegate visitor
  late VisitorDelegate _visitorDelegate;
  // delegate to update the status
  final FlagshipDelegate flagshipDelegate = Flagship.sharedInstance();

  /// Create new instance for visitor
  ///
  /// config: this object manage the mode of the sdk and other params
  /// visitorId : the user ID for the visitor
  /// context : Map that represent the conext for the visitor
  Visitor(this.config, this.visitorId, Map<String, Object> context,
      {bool hasConsented = true}) {
    // update context
    this.updateContextWithMap(context);
    // set delegate
    _visitorDelegate = VisitorDelegate(this);
    // set the consent
    _hasConsented = hasConsented;
    // Send the consent hit on false at the start
    if (!_hasConsented) {
      trackingManager.sendHit(Consent(hasConsented: _hasConsented));
    }
  }

  /// Update context directely with map for <String, Object>
  void clearContext() {
    _context.clear();
  }

  /// Update context directely with map for <String, Object>
  void updateContextWithMap(Map<String, Object> context) {
    _context.addAll(context);
    Flagship.logger(Level.INFO, CONTEXT_UPDATE.replaceFirst("%s", "$_context"));
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
    _visitorDelegate.updateContext(key, value);
  }

  /// Get Modification
  ///
  /// key : the name of the key relative to modification
  /// defaultValue: the returned value if the key is not found
  ///

  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    return _visitorDelegate.getModification(key, defaultValue,
        activate: activate);
  }

  /// Get the modification infos relative to flag (modification)
  ///
  /// key : the name of the key relative to modification
  /// Return map {"campaignId":"xxx", "variationId" : "xxxx", "variationGroupId":"xxxxx", "isReference": true/false}

  Map<String, Object>? getModificationInfo(String key) {
    return _visitorDelegate.getModificationInfo(key);
  }

  /// Synchronize modification for the visitor

  Future<Status> synchronizeModifications() async {
    return _visitorDelegate.synchronizeModifications();
  }

  /// Activate modificationx

  Future<void> activateModification(String key) async {
    _visitorDelegate.activateModification(key);
  }

  /// Send hit
  Future<void> sendHit(BaseHit hit) async {
    _visitorDelegate.sendHit(hit);
  }

  // Set Consent
  void setConsent(bool isConsent) {
    if (Flagship.getStatus() != Status.PANIC_ON) {
      _hasConsented = isConsent;
      // Create hit for consent
      Consent hitConsent = Consent(hasConsented: isConsent);
      _visitorDelegate.sendHit(hitConsent);

      // update the consent for decision manager
      decisionManager.updateConsent(isConsent);
    }
  }

  // Get consent
  bool getConsent() {
    return _hasConsented;
  }
}
