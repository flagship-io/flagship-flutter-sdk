import 'package:flagship/hits/hit.dart';
import 'package:flagship/hits/segment.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/status.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/visitor/Ivisitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';
import 'package:flagship/visitor/strategy/no_consent_strategy.dart';
import 'package:flagship/visitor/strategy/not_ready_strategy.dart';
import 'package:flagship/visitor/strategy/panic_strategy.dart';
import 'package:flagship/flagship.dart';
import 'package:flutter/material.dart';
import '../visitor.dart';

class VisitorDelegate implements IVisitor {
  final Visitor visitor;

  Map<String, String> _activatedVariations = {};
  VisitorDelegate(this.visitor);
  // Get the strategy
  DefaultStrategy getStrategy() {
    switch (Flagship.getStatus()) {
      case FSSdkStatus.SDK_NOT_INITIALIZED:
        return NotReadyStrategy(visitor);
      case FSSdkStatus.SDK_PANIC:
        return PanicStrategy(visitor);
      case FSSdkStatus.SDK_INITIALIZED:
        if (visitor.getConsent() == false) {
          // Return non consented
          return NoConsentStrategy(visitor);
        } else {
          return DefaultStrategy(visitor);
        }
      case FSSdkStatus.SDK_INITIALIZING:
        return NotReadyStrategy(visitor);
    }
  }

  @override
  Future<void> activateFlag(Modification pModification) {
    bool isDup = _isDeduplicatedFlag(
        pModification.campaignId, pModification.variationGroupId);
    return getStrategy().activateFlag(pModification, isDuplicated: isDup);
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
  Future<FetchResponse?> fetchFlags() async {
    return getStrategy().fetchFlags().whenComplete(() {
      // Before to send the segment, we need to check if the context already changed
      // In Buckting mode
      if (visitor.config.decisionMode == Mode.BUCKETING &&
          //Flagship.getStatus() != FSSdkStatus.SDK_PANIC &&
          visitor.fetchReasons ==
              FetchFlagsRequiredStatusReason.VISITOR_CONTEXT_UPDATED) {
        sendHit(Segment(persona: visitor.getCurrentContext()));
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
  Future<bool> lookupVisitor(String visitoId) async {
    return getStrategy().lookupVisitor(visitoId);
  }

  @override
  void lookupHits() async {
    getStrategy().lookupHits();
  }

  @override
  void onExposure(Modification pModification) {
    getStrategy().onExposure(pModification);
  }

  @override
  FlagStatus getFlagStatus(String key) {
    return getStrategy().getFlagStatus(key);
  }

  @override
  collectEmotionsAIEvents(String screenName) {
    getStrategy().collectEmotionsAIEvents(screenName);
  }

  @override
  onAppScreenChange(String screenName) {
    getStrategy().onAppScreenChange(screenName);
  }

  /// Returns `true` if this (campId, varGrpId) pair is considered “deduplicated”.
  bool _isDeduplicatedFlag(String campId, String varGrpId) {
    final DateTime now = DateTime.now();
    final Duration elapsed = now.difference(visitor.sessionDuration);

    print(
        "--------- Session time duration is ${elapsed.inSeconds} ------------");

    try {
      if (elapsed > FSSessionVisitor) {
        _activatedVariations
          ..clear()
          ..[campId] = varGrpId;
        return false;
      }

      final bool isDup = _activatedVariations[campId] == varGrpId;

      _activatedVariations[campId] = varGrpId;

      return isDup;
    } finally {
      visitor.sessionDuration = now;
    }
  }
}
