import 'package:flagship/hits/hit.dart';
import 'package:flagship/hits/segment.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/visitor/Ivisitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';
import 'package:flagship/visitor/strategy/no_consent_strategy.dart';
import 'package:flagship/visitor/strategy/not_ready_strategy.dart';
import 'package:flagship/visitor/strategy/panic_strategy.dart';
import 'package:flagship/flagship.dart';
import '../visitor.dart';

class VisitorDelegate implements IVisitor {
  final Visitor visitor;
  VisitorDelegate(this.visitor);
  // Get the strategy
  DefaultStrategy getStrategy() {
    switch (Flagship.getStatus()) {
      case Status.NOT_INITIALIZED:
        return NotReadyStrategy(visitor);
      case Status.PANIC_ON:
        return PanicStrategy(visitor);
      case Status.READY:
        if (visitor.getConsent() == false) {
          // Return non consented
          return NoConsentStrategy(visitor);
        } else {
          return DefaultStrategy(visitor);
        }
    }
  }

// Activate modification
  @override
  Future<void> activateModification(String key) {
    return getStrategy().activateModification(key);
  }

  @override
  Future<void> activateFlag(Modification pModification) {
    return getStrategy().activateFlag(pModification);
  }

// Get modification
  @override
  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    return getStrategy().getModification(key, defaultValue, activate: activate);
  }

  @override
  Modification? getFlagModification(String key) {
    return getStrategy().getFlagModification(key);
  }

// Get modification info
  @override
  Map<String, dynamic>? getModificationInfo(String key) {
    return getStrategy().getModificationInfo(key);
  }

// Fetch modification
  @override
  Future<Error?> synchronizeModifications() async {
    return getStrategy().synchronizeModifications().whenComplete(() {
      if (visitor.config.decisionMode == Mode.BUCKETING &&
          Flagship.getStatus() != Status.PANIC_ON) {
        visitor.sendHit(Segment(persona: visitor.getCurrentContext()));
      }
    });
  }

// Update context
  @override
  void updateContext<T>(String key, T value) {
    getStrategy().updateContext(key, value);
  }

// Send hits
  @override
  Future<void> sendHit(BaseHit hit) async {
    // set visitorId for hit
    hit.visitorId = visitor.visitorId;
    // set anonymousId for hit
    hit.anonymousId = visitor.anonymousId;
    hit.createdAt = DateTime.now();
    getStrategy().sendHit(hit);
  }

  @override
  void setConsent(bool isConsent) {
    getStrategy().setConsent(isConsent);
  }

  @override
  authenticateVisitor(String visitorId) {
    getStrategy().authenticateVisitor(visitorId);
  }

  @override
  unAuthenticateVisitor() {
    getStrategy().unAuthenticateVisitor();
  }

  void cacheVisitor(String visitorId, String jsonString) {
    getStrategy().cacheVisitor(visitorId, jsonString);
  }

  @override
  void lookupVisitor(String visitoId) async {
    getStrategy().lookupVisitor(visitoId);
  }

  @override
  void lookupHits() async {
    getStrategy().lookupHits();
  }

  @override
  void onExposure(Modification pModification) {
    getStrategy().onExposure(pModification);
  }
}
