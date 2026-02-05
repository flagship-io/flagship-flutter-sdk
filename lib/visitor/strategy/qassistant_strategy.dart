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

  /// Set of hidden campaign IDs - these should return null (default value)
  final Set<String> hiddenCampaigns = {};

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

    // Listen to campaign actions (hide/unhide)
    _streamSubscriptions.add(
      messageService.campaignActionStream.listen(_handleCampaignAction),
    );

    print(
        '✅ QA Strategy: Subscribed to QAAssistant Modification Message Stream');
    print('✅ QA Strategy: Subscribed to User Context Request Stream');
    print('✅ QA Strategy: Subscribed to Campaign Action Stream');
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
    // First check if this flag belongs to a hidden campaign
    final visitorMod = super.getFlagModification(key);

    print('🔍 getFlagModification called for key: $key');
    print('   hiddenCampaigns: $hiddenCampaigns');
    print('   visitorMod campaignId: ${visitorMod?.campaignId}');

    if (visitorMod != null && hiddenCampaigns.contains(visitorMod.campaignId)) {
      print(
          '🚫 QA Override: Flag "$key" belongs to hidden campaign ${visitorMod.campaignId}, returning null (default value)');
      return null;
    }

    // Then check for QA forced modifications
    if (qaaModifications.containsKey(key)) {
      print('🎯 QA Override: Using QA modification for key: $key');
      return qaaModifications[key];
    }

    // Finally return visitor modification (production value)
    print(
        '📦 Visitor: Using visitor modification for key: $key, value: ${visitorMod?.value}');
    return visitorMod;
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

      // Remove from hidden campaigns when forcing
      hiddenCampaigns.remove(message.campaignId);
      print('✓ Campaign ${message.campaignId} removed from hidden list');

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
      // Empty modifications means clearing the campaign (hide or unforce)
      print('⚠️ Empty modifications received - clearing campaign');
      _clearCampaignModifications(message.campaignId);
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

  /// Clear all modifications for a specific campaign
  void _clearCampaignModifications(String campaignId) {
    print('🧹 Clearing modifications for campaign: $campaignId');

    final removedKeys = <String>[];

    // Remove all modifications belonging to this campaign
    qaaModifications.removeWhere((key, modification) {
      if (modification.campaignId == campaignId) {
        removedKeys.add(key);
        return true;
      }
      return false;
    });

    print(
        '✅ Removed ${removedKeys.length} QA modifications for campaign $campaignId');

    if (removedKeys.isNotEmpty) {
      _notifyFlagChanges(removedKeys);
    }
  }

  /// Handle campaign action messages (hide/unhide)
  void _handleCampaignAction(CampaignActionMessage message) {
    print(
        '🎯 QA Strategy: Received campaign action: ${message.action} for ${message.campaignId}');

    switch (message.action) {
      case 'hide':
        _hideCampaign(message.campaignId);
        break;
      case 'unhide':
        _unhideCampaign(message.campaignId);
        break;
      default:
        print('⚠️ Unknown campaign action: ${message.action}');
    }
  }

  /// Mark a campaign as hidden - its flags will return null (default values)
  void _hideCampaign(String campaignId) {
    print('🙈 Hiding campaign: $campaignId');
    print('   hiddenCampaigns before: $hiddenCampaigns');

    hiddenCampaigns.add(campaignId);
    _clearCampaignModifications(campaignId);

    print('   hiddenCampaigns after: $hiddenCampaigns');
    print('✅ Campaign $campaignId is now hidden');

    // Notify about flags that will now return default values
    final affectedFlags = visitor.modifications.entries
        .where((entry) => entry.value.campaignId == campaignId)
        .map((entry) => entry.key)
        .toList();

    if (affectedFlags.isNotEmpty) {
      print('   Affected flags: $affectedFlags');
      _notifyFlagChanges(affectedFlags);
    }
  }

  /// Remove a campaign from hidden list - restore to production behavior
  void _unhideCampaign(String campaignId) {
    print('👁️ Unhiding campaign: $campaignId');
    print('   hiddenCampaigns before: $hiddenCampaigns');

    final wasHidden = hiddenCampaigns.remove(campaignId);

    print('   hiddenCampaigns after: $hiddenCampaigns');

    if (wasHidden) {
      // Get all flags affected by this campaign and notify
      final affectedFlags = visitor.modifications.entries
          .where((entry) => entry.value.campaignId == campaignId)
          .map((entry) => entry.key)
          .toList();

      if (affectedFlags.isNotEmpty) {
        print('   Affected flags: $affectedFlags');
        _notifyFlagChanges(affectedFlags);
      }
      print('✅ Campaign $campaignId is now visible');
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
