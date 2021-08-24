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

class Visitor /*implements IVisitor */ {
  /// VisitorId
  final String visitorId;

  /// Configuration
  final FlagshipConfig config;

  /// Context
  Map<String, Object> _context = {};

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

  //Consent
  bool _hasConsented = true;

  late VisitorDelegate _visitorDelegate;
  //late DefaultStrategy _strategy;

  /// Create new instance for visitor
  ///
  /// config: this object manage the mode of the sdk and other params
  /// visitorId : the user ID for the visitor
  /// context : Map that represent the conext for the visitor
  Visitor(this.config, this.visitorId, Map<String, Object> context) {
    this.updateContextWithMap(context);

    _visitorDelegate = VisitorDelegate(this);
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

  // Consent

  void setConsent(bool hasConsented) {
    _hasConsented = hasConsented;

    // Create hit for consent
    Consent hitConsent = Consent(hasConsented: hasConsented);
    _visitorDelegate.sendHit(hitConsent);
  }

  bool getConsent() {
    return _hasConsented;
  }
}
