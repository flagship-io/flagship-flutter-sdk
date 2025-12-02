import 'dart:async';
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
import 'package:flagship/visitor/strategy/qassistant_strategy.dart';
import '../visitor.dart';

class VisitorDelegate implements IVisitor {
  final Visitor visitor;
  DefaultStrategy? _cachedStrategy;
  FSSdkStatus? _lastSdkStatus;
  bool? _lastConsentStatus;
  bool? _lastQAStatus;
  bool _isQAAssistantReady = false;
  StreamSubscription? _qaReadySubscription;
  StreamSubscription? _qaStopSubscription;

  Map<String, String> _activatedVariations = {};

  VisitorDelegate(this.visitor) {
    _listenToQAAssistantReady();
    _listenToQAAssistantStop();
  }

  // Listen to QA Assistant ready message
  void _listenToQAAssistantReady() {
    try {
      final messageService = getQAMessageService();

      /// A refaire ce calll ce n 'est pas bon ---- ne compile pas
      _qaReadySubscription = messageService.startCommandStream.listen((_) {
        print('✅ VisitorDelegate: QA Assistant is ready');
        Flagship.sharedInstance().isQAAssistantConnected = true;
        _isQAAssistantReady = true;
        // Create QassistantStrategy immediately to ensure we don't miss broadcasts
        _cachedStrategy = QassistantStrategy(visitor);
        _lastQAStatus = true;

        // Build variations list from visitor modifications
        final variations = <Map<String, String>>[];
        final processedVariations = <String>{};

        for (final modification in visitor.modifications.values) {
          final variationKey =
              '${modification.campaignId}_${modification.variationId}';

          if (!processedVariations.contains(variationKey)) {
            variations.add({
              'campaignId': modification.campaignId,
              'variationId': modification.variationId,
              'variationGroupId': modification.variationGroupId,
            });
            processedVariations.add(variationKey);
          }
        }

        // Send fetched flag IDs to QA Assistant
        messageService.broadcastFetchedFlagIds(variations);
        print(
            '📤 VisitorDelegate: Sent fetched flag IDs to QA Assistant (${variations.length} variations)');
      });
    } catch (e) {
      print('⚠️ VisitorDelegate: Could not listen to QA Assistant ready: $e');
    }
  }

  // Listen to QA Assistant stop message
  void _listenToQAAssistantStop() {
    try {
      final messageService = getQAMessageService();
      _qaStopSubscription = messageService.stopCommandStream.listen((_) {
        print('⏹️ VisitorDelegate: QA Assistant stopped');
        Flagship.sharedInstance().isQAAssistantConnected = false;
        _isQAAssistantReady = false;
        // Invalidate cached strategy to switch back to normal strategy
        _cachedStrategy = null;
        print('✅ VisitorDelegate: Switched back to normal strategy');
      });
    } catch (e) {
      print('⚠️ VisitorDelegate: Could not listen to QA Assistant stop: $e');
    }
  }

  // Cleanup method to cancel subscriptions
  void dispose() {
    _qaReadySubscription?.cancel();
    _qaStopSubscription?.cancel();
  }

  // Get the strategy

  DefaultStrategy getStrategy() {
    final currentSdkStatus = Flagship.getStatus();
    final currentConsent = visitor.getConsent();
    final currentQAStatus = Flagship.sharedInstance().isQAAssistantConnected;

    // Vérifier si la stratégie doit être invalidée
    if (_cachedStrategy == null ||
        _lastSdkStatus != currentSdkStatus ||
        _lastConsentStatus != currentConsent ||
        _lastQAStatus != currentQAStatus) {
      // Créer une nouvelle stratégie seulement si nécessaire
      _cachedStrategy =
          _createStrategy(currentSdkStatus, currentConsent, currentQAStatus);

      // Sauvegarder l'état actuel
      _lastSdkStatus = currentSdkStatus;
      _lastConsentStatus = currentConsent;
      _lastQAStatus = currentQAStatus;
    }

    // Review later because we fallback on NotReadyStrategy too often
    return _cachedStrategy ?? NotReadyStrategy(visitor);
  }

  DefaultStrategy _createStrategy(
      FSSdkStatus status, bool? consent, bool qaConnected) {
    // Only use QassistantStrategy if QA Assistant is connected AND ready
    if (qaConnected && _isQAAssistantReady) {
      print('🔄 VisitorDelegate: Using QassistantStrategy');
      return QassistantStrategy(visitor);
    }
    switch (status) {
      case FSSdkStatus.SDK_NOT_INITIALIZED:
        return NotReadyStrategy(visitor);
      case FSSdkStatus.SDK_PANIC:
        return PanicStrategy(visitor);
      case FSSdkStatus.SDK_INITIALIZED:
        return consent == false
            ? NoConsentStrategy(visitor)
            : DefaultStrategy(visitor);
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

  /// Returns `true` if flag is already activated during visitor session
  bool _isDeduplicatedFlag(String campId, String varGrpId) {
    final DateTime now = DateTime.now();
    final Duration elapsed = now.difference(visitor.sessionDuration);

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
