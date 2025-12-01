import 'dart:async';
import 'package:flagship/flagship.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';
import 'package:flagship/visitor/Ivisitor.dart';
import 'package:flagship/model/modification.dart';
import 'package:abtastyqaassistant/abtastyqaassistant.dart';

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

    // Listen to stop commands
    //  _streamSubscriptions.add(
    //   messageService.stopCommandStream.listen((_) => _handleStopQAAssistant()),
    //  );

    print(
        '✅ QA Strategy: Subscribed to QAAssistant Modification Message Stream');
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
      print('📤 Sending campaigns info to QA Assistant');
      print('   Variations count: ${processedVariations.length}');
      messageService.broadcastFetchedFlagIds(processedVariations);

      print('✅ Campaigns info sent to QA Assistant');
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
          message.campaignSlug, // slug
          value,
        );

        qaaModifications[key] = modification;
        print('  ✓ $key: $value (added to QA modifications)');
      }

      print('✅ All modifications applied to QA strategy.modifications');
      print('📊 Total QA modifications: ${qaaModifications.length}');
    } else {
      print('⚠️ No flag values found in modifications');
    }
  }

  /// Handle stop QA Assistant command from stream
  // void _handleStopQAAssistant() {
  //   print('⏹️ Flagship: Stop QA Assistant command received from stream');
  //   // Update Flagship SDK state to indicate QA Assistant is inactive
  //   Flagship.sharedInstance().isQAAssistantConnected = false;
  //   print('✅ QA Assistant stopped');
  // }
}
