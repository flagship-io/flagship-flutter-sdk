import 'dart:async';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';
import 'package:flagship/visitor/Ivisitor.dart';
import 'package:flagship/model/modification.dart';

/// QA Assistant Strategy that connects to QA Assistant package
class QassistantStrategy extends DefaultStrategy {
  /// Map des modifications QA qui override celles du visitor
  final Map<String, Modification> qaaModifications = {};

  /// Stream subscriptions for listening to QA messages
  final List<StreamSubscription> _streamSubscriptions = [];

  QassistantStrategy(Visitor visitor) : super(visitor) {
    // Get QA Message Service
    final messageService = getQAMessageService();

    // Listen to QA Modification from QA Assistant
    _streamSubscriptions.add(
      messageService.modificationMessageStream
          .listen(_handleModificationMessage),
    );

    // Listen to user context requests from QA Assistant
    _streamSubscriptions.add(
      messageService.userContextRequestStream.listen((_) {
        _handleUserContextRequest();
      }),
    );

    print(
        '✅ QA Strategy: Subscribed to QAAssistant Modification Message Stream');
    print('✅ QA Strategy: Subscribed to User Context Request Stream');
  }

  void cleanup() {
    // Clean up stream subscriptions when strategy is disposed
    for (final subscription in _streamSubscriptions) {
      subscription.cancel();
    }
    _streamSubscriptions.clear();
    print('🧹 QA Strategy: All stream subscriptions cancelled');
  }

  @override
  Modification? getFlagModification(String key) {
    // D'abord chercher dans les modifications QA
    if (qaaModifications.containsKey(key)) {
      print('🎯 QA Override: Using QA modification for key: $key');
      return qaaModifications[key];
    }

    // Sinon chercher dans les modifications du visitor
    Modification? ret = super.getFlagModification(key);
    print(
        '📦 Visitor: Using visitor modification for key: $key, value: ${ret?.value}');
    return ret;
  }

  @override
  Future<FetchResponse?> fetchFlags() async {
    // Call parent fetchFlags to get campaigns/variations
    final response = await super.fetchFlags();

    // Send campaigns info to QA Assistant
    _sendCampaignsInfoToQA();
    return response;
  }

  @override
  void updateContext<T>(String key, T value) {
    // Update parent context first
    super.updateContext(key, value);

    // Send updated user context to QA Assistant
    try {
      final messageService = getQAMessageService();

      // Get the complete context after update
      final completeContext = visitor.getContext();

      print('📤 Broadcasting updated user context to QA Assistant');
      print('   Updated key: $key = $value');
      print('   Complete context: $completeContext');

      // Broadcast the complete context
      messageService.broadcastUserContextUpdate(completeContext);

      print('✅ User context broadcasted successfully');
    } catch (e) {
      print('⚠️ Error sending updated user context to QA Assistant: $e');
    }
  }

  @override
  Future<void> sendHit(BaseHit hit) async {
    try {
      // In QA mode the qa flag is set to true
      hit.qa = true;
      // Récupérer le payload du hit
      final payload = hit.bodyTrack;

      print('📤 QA Strategy: Intercepting hit before sending');
      print('   Hit Type: ${hit.runtimeType}');
      print('   Payload: $payload');

      // Broadcaster le hit vers QA Assistant
      final messageService = getQAMessageService();
      messageService.broadcastHitEvent(hit, payload);

      print('✅ QA Strategy: Hit broadcasted to QA Assistant');
    } catch (e) {
      print('⚠️ QA Strategy: Error broadcasting hit: $e');
    }

    // Envoyer le hit normalement via la stratégie parent
    return super.sendHit(hit);
  }

  void _sendCampaignsInfoToQA() {
    try {
      final messageService = getQAMessageService();

      // Track unique variations using a Set to avoid duplicates
      final seenVariations = <String>{};
      final processedVariations = <Map<String, String>>[];

      for (final modification in visitor.modifications.values) {
        // Create unique key combining campaignId, variationId, and variationGroupId
        final uniqueKey =
            '${modification.campaignId}_${modification.variationId}_${modification.variationGroupId}';

        // Only add if not already processed
        if (!seenVariations.contains(uniqueKey)) {
          seenVariations.add(uniqueKey);
          processedVariations.add({
            'campaignId': modification.campaignId,
            'variationId': modification.variationId,
            'variationGroupId': modification.variationGroupId,
          });
        }
      }

      // Get complete visitor context
      final visitorContext = visitor.getContext();

      // Prepare the complete data with variations and visitor context
      final campaignsData = {
        'variations': processedVariations,
        'visitorContext': visitorContext,
      };

      print('📤 Sending campaigns info and user context to QA Assistant');
      print('   Variations count: ${processedVariations.length}');
      print('   Visitor context keys: ${visitorContext.keys.toList()}');

      // Send variations
      messageService.broadcastFetchedFlagIds(processedVariations);

      // Send complete visitor context
      messageService.broadcastUserContextUpdate(visitorContext);

      print('✅ Campaigns info and visitor context sent to QA Assistant');
    } catch (e) {
      print('⚠️ Error sending campaigns info to QA Assistant: $e');
    }
  }

  /// Handle modification message from stream
  void _handleModificationMessage(ModificationMessage message) {
    print('🎯 Flagship: Received modification message from stream');
    print('📄 Message JSON: ${message.toJsonString()}');
    print('');
    print('Campaign Details:');
    print('  - ID: ${message.campaignId}');
    print('  - Name: ${message.campaignName}');
    print('  - Type: ${message.campaignType}');
    print('  - Slug: ${message.campaignSlug}');
    print('');
    print('Variation Group:');
    print('  - ID: ${message.variationGroupId}');
    print('  - Name: ${message.variationGroupName}');
    print('');
    print('Variation Details:');
    print('  - ID: ${message.variation.id}');
    print('  - Name: ${message.variation.name}');
    print('  - Is Reference: ${message.variation.reference}');
    print('');

    // Extract the modifications from the nested structure
    // Format: { "type": "Flag", "value": { "flagKey": "flagValue" } }
    final modificationsData = message.variation.modifications;
    final modificationType = modificationsData['type'] ?? 'Unknown';
    final flagsValue = modificationsData['value'] as Map<String, dynamic>?;

    print('Modifications (Type: $modificationType):');

    if (flagsValue != null && flagsValue.isNotEmpty) {
      final changedFlags = <String>[];

      // Apply each flag modification to the QA strategy modifications map
      for (final entry in flagsValue.entries) {
        final key = entry.key;
        final value = entry.value;

        // Create a Modification object and add it to strategy.modifications
        final modification = Modification(
          key,
          message.campaignId,
          message.campaignName,
          message.variationGroupId,
          message.variationGroupName,
          message.variation.id,
          message.variation.name,
          message.variation.reference,
          message.campaignType,
          message.campaignSlug,
          value,
        );

        qaaModifications[key] = modification;
        changedFlags.add(key);
        print('  ✓ $key: $value (added to QA modifications)');
      }

      print('✅ All modifications applied to QA strategy.modifications');
      print('📊 Total QA modifications: ${qaaModifications.length}');

      // Trigger optional callback if client has set one
      _notifyFlagChanges(changedFlags);
    } else {
      print('⚠️ No flag values found in modifications');
    }
  }

  /// Notify about flag changes via optional callback
  void _notifyFlagChanges(List<String> changedFlagKeys) {
    // Call the optional callback if it exists
    final callback = visitor.onFlagUpdate;
    if (callback != null) {
      callback(changedFlagKeys);
      print('🔔 Notified client about ${changedFlagKeys.length} flag changes');
    }
  }

  /// Handle user context request from QA Assistant
  void _handleUserContextRequest() {
    print('🔔 QA Strategy: Received user context request');

    try {
      final messageService = getQAMessageService();
      final currentContext = visitor.getContext();

      print('📤 QA Strategy: Sending user context in response to request');
      print('   Context: $currentContext');

      messageService.broadcastUserContextUpdate(currentContext);

      print('✅ QA Strategy: User context sent successfully');
    } catch (e) {
      print('⚠️ QA Strategy: Error sending user context: $e');
    }
  }
}
