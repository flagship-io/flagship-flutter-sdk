import 'dart:async';
import 'package:flagship/flagshipContext/flagship_context.dart';
import 'package:flagship/flagshipContext/flagship_context_manager.dart';
import 'package:flagship/hits/event.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/api/tracking_manager.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor/visitor_delegate.dart';
import 'flagship_delegate.dart';

enum Instance {
  // The  newly created visitor instance will be returned and saved into the Flagship singleton. Call `Flagship.getVisitor()` to retrieve the instance.
  // This option should be adopted on applications that handle only one visitor at the same time.
  SINGLE_INSTANCE,

  // The newly created visitor instance wont be saved and will simply be returned. Any previous visitor instance will have to be recreated.
  //  This option should be adopted on applications that handle multiple visitors at the same time.
  NEW_INSTANCE
}

class Visitor {
  // VisitorId
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

  TrackingManager trackingManager = TrackingManager();

  //Consent by default is true
  bool _hasConsented = true;

  // Xpc
  bool _isAuthenticated;

  // delegate visitor
  late VisitorDelegate _visitorDelegate;
  // delegate to update the status
  final FlagshipDelegate flagshipDelegate = Flagship.sharedInstance();

  /// Create new instance for visitor
  ///
  /// config: this object manage the mode of the sdk and other params
  /// visitorId : the user ID for the visitor
  /// context : Map that represent the conext for the visitor
  Visitor(this.config, this.visitorId, this._isAuthenticated, Map<String, Object> context, {bool hasConsented = true}) {
    if (_isAuthenticated == true) {
      this.anonymousId = FlagshipTools.generateFlagshipId();
    } else {
      anonymousId = null;
    }

    // Load preset_Context
    this.updateContextWithMap(FlagshipContextManager.getPresetContextForApp());

    // update context
    this.updateContextWithMap(context);
    // set delegate
    _visitorDelegate = VisitorDelegate(this);
    // set the consent
    _hasConsented = hasConsented;
    // Send the consent hit on false at the start
    if (!_hasConsented) {
      _visitorDelegate.sendHit(Consent(hasConsented: _hasConsented));
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
    // Delegate the action to strategy
    _visitorDelegate.updateContext(key, value);
  }

  // Update with predefined context
  void updateFlagshipContext<T>(FlagshipContext flagshipContext, T value) {
    if (FlagshipContextManager.chekcValidity(flagshipContext, value)) {
      _visitorDelegate.updateContext(rawValue(flagshipContext), value);
    } else {
      Flagship.logger(Level.ERROR,
          "Skip updating the context with predefined context ${flagshipContext.name} ..... the value is not valid");
    }
  }

  /// Get Flag object
  ///
  /// key : the name of the key relative to modification
  /// defaultValue: the returned value if the key is not found
  /// return Flag object. See Flag class
  Flag getFlag<T>(String key, T defaultValue) {
    return Flag<T>(key, defaultValue, this._visitorDelegate);
  }

  /// Get Modification
  ///
  /// key : the name of the key relative to modification
  /// defaultValue: the returned value if the key is not found
  ///
  @Deprecated('Use value() in Flag class instead')
  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    // Delegate the action to strategy
    return _visitorDelegate.getModification(key, defaultValue, activate: activate);
  }

  /// Get the modification infos relative to flag (modification)
  ///
  /// key : the name of the key relative to modification
  /// Return map {"campaignId":"xxx", "variationId" : "xxxx", "variationGroupId":"xxxxx", "isReference": true/false}
  @Deprecated('Use metadata() in Flag class instead')
  Map<String, Object>? getModificationInfo(String key) {
    // Delegate the action to strategy
    return _visitorDelegate.getModificationInfo(key);
  }

  /// Synchronize modification for the visitor
  @Deprecated('Use fetchFlags instead')
  Future<void> synchronizeModifications() async {
    // Delegate the action to strategy
    return _visitorDelegate.synchronizeModifications();
  }

  Future<void> fetchFlags() async {
    // Delegate the action to strategy
    return _visitorDelegate.synchronizeModifications();
  }

  /// Activate modificationx
  @Deprecated('Use userExposed() in Flag class instead')
  Future<void> activateModification(String key) async {
    // Delegate the action to strategy
    _visitorDelegate.activateModification(key);
  }

  /// Send hit
  Future<void> sendHit(BaseHit hit) async {
    // Delegate the action to strategy
    _visitorDelegate.sendHit(hit);
  }

  // Set Consent
  void setConsent(bool newValue) {
    // Update the state for visitor
    _hasConsented = newValue;
    // Update the decision manager
    decisionManager.updateConsent(newValue);
    // Delegate the action to strategy
    _visitorDelegate.setConsent(_hasConsented);
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
    _visitorDelegate.getStrategy().authenticateVisitor(visitorId);
  }

  /// Use authenticate methode to go from Logged in  session to logged out session
  unauthenticate() {
    _visitorDelegate.getStrategy().unAuthenticateVisitor();
  }
}

//// Builder

class VisitorBuilder {
  final String visitorId;

  final Instance instanceType;

// Context
  Map<String, Object> _context = {};

// Has consented
  bool _hasConsented = true;

// Xpc by default false
  bool _isAuthenticated = false;

  VisitorBuilder(this.visitorId, {this.instanceType = Instance.SINGLE_INSTANCE});

// Context
  VisitorBuilder withContext(Map<String, Object> context) {
    _context = context;
    return this;
  }

  VisitorBuilder hasConsented(bool hasConsented) {
    _hasConsented = hasConsented;
    return this;
  }

  isAuthenticated(bool authenticated) {
    _isAuthenticated = authenticated;
    return this;
  }

  Visitor build() {
    Visitor newVisitor = Visitor(
        Flagship.sharedInstance().getConfiguration() ?? ConfigBuilder().build(), visitorId, _isAuthenticated, _context,
        hasConsented: _hasConsented);
    if (this.instanceType == Instance.SINGLE_INSTANCE) {
      //Set this visitor as shared instance
      Flagship.setCurrentVisitor(newVisitor);
    }
    return newVisitor;
  }
}
