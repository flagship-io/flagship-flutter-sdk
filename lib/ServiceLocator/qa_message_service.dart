import 'dart:async';
import 'dart:convert';

/// Represents a variation object
class VariationInfo {
  final String id;
  final String name;
  final bool reference;
  final Map<String, dynamic> modifications;

  VariationInfo({
    required this.id,
    required this.name,
    required this.reference,
    required this.modifications,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'reference': reference,
      'modifications': {'type': 'Flag', 'value': modifications},
    };
  }
}

/// Represents a modification object to be sent to Flagship (New format)
class ModificationMessage {
  final String campaignId;
  final String campaignName;
  final String campaignType;
  final String? campaignSlug;
  final String variationGroupId;
  final String variationGroupName;
  final VariationInfo variation;
  final DateTime timestamp;

  ModificationMessage({
    required this.campaignId,
    required this.campaignName,
    required this.campaignType,
    this.campaignSlug,
    required this.variationGroupId,
    required this.variationGroupName,
    required this.variation,
  }) : timestamp = DateTime.now();

  /// Convert to JSON format with campaignId as key
  Map<String, dynamic> toJson() {
    return {
      campaignId: {
        'campaignId': campaignId,
        'campaignName': campaignName,
        'campaignType': campaignType,
        'CampaignSlug': campaignSlug,
        'variationGroupId': variationGroupId,
        'variationGroupName': variationGroupName,
        'variation': variation.toJson(),
      },
    };
  }

  /// Convert to JSON string
  String toJsonString() {
    return jsonEncode(toJson());
  }

  /// Create from JSON (expects the new format with campaignId as key)
  factory ModificationMessage.fromJson(Map<String, dynamic> json) {
    // Extract the first key which should be the campaignId
    final campaignKey = json.keys.first;
    final campaignData = json[campaignKey] as Map<String, dynamic>;
    final variationData = campaignData['variation'] as Map<String, dynamic>;
    final modificationsData =
        variationData['modifications'] as Map<String, dynamic>;
    final flagValue = modificationsData['value'] as Map<String, dynamic>;

    return ModificationMessage(
      campaignId: campaignData['campaignId'] ?? campaignKey,
      campaignName: campaignData['campaignName'] ?? '',
      campaignType: campaignData['campaignType'] ?? '',
      campaignSlug: campaignData['CampaignSlug'],
      variationGroupId: campaignData['variationGroupId'] ?? '',
      variationGroupName: campaignData['variationGroupName'] ?? '',
      variation: VariationInfo(
        id: variationData['id'] ?? '',
        name: variationData['name'] ?? '',
        reference: variationData['reference'] ?? false,
        modifications: flagValue,
      ),
    );
  }

  /// Create from JSON string
  factory ModificationMessage.fromJsonString(String jsonString) {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    return ModificationMessage.fromJson(json);
  }
}

/// Service responsible for sending messages from QA Assistant to Flagship using streams
class QAMessageService {
  // Stream controllers for broadcasting all message types to multiple listeners
  final _modificationMessageController =
      StreamController<ModificationMessage>.broadcast();
  final _liveVariationsIdsController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _startCommandController = StreamController<void>.broadcast();
  final _stopCommandController = StreamController<void>.broadcast();

  /// Stream of modification messages
  Stream<ModificationMessage> get modificationMessageStream =>
      _modificationMessageController.stream;

  /// Stream of fetched flag IDs updates
  Stream<Map<String, dynamic>> get liveVariationsIdsStream =>
      _liveVariationsIdsController.stream;

  /// Stream of start QA Assistant commands
  Stream<void> get startCommandStream => _startCommandController.stream;

  /// Stream of stop QA Assistant commands
  Stream<void> get stopCommandStream => _stopCommandController.stream;

  /// Dispose all stream controllers
  void dispose() {
    _modificationMessageController.close();
    _liveVariationsIdsController.close();
    _startCommandController.close();
    _stopCommandController.close();
    print('🧹 QA Message Service: All streams closed');
  }

  /// Send modification message to Flagship (New format)
  void sendModification({
    required String campaignId,
    required String campaignName,
    required String campaignType,
    String? campaignSlug,
    required String variationGroupId,
    required String variationGroupName,
    required String variationId,
    required String variationName,
    required bool isReference,
    required Map<String, dynamic> modifications,
  }) {
    final message = ModificationMessage(
      campaignId: campaignId,
      campaignName: campaignName,
      campaignType: campaignType,
      campaignSlug: campaignSlug,
      variationGroupId: variationGroupId,
      variationGroupName: variationGroupName,
      variation: VariationInfo(
        id: variationId,
        name: variationName,
        reference: isReference,
        modifications: modifications,
      ),
    );

    print('📤 QA Message Service: Broadcasting modification message');
    print('   Campaign: $campaignId ($campaignName)');
    print('   Variation: $variationId ($variationName)');
    print('   IsReference: $isReference');
    print('   Type: $campaignType');
    print('   JSON: ${message.toJsonString()}');

    _modificationMessageController.add(message);
  }

  /// Send modification message using ModificationMessage object
  void sendModificationMessage(ModificationMessage message) {
    print('📤 QA Message Service: Broadcasting modification message');
    print('   JSON: ${message.toJsonString()}');

    _modificationMessageController.add(message);
  }

  /// Broadcast fetched flag IDs from Flagship SDK to QA Assistant
  void broadcastFetchedFlagIds(List<Map<String, String>> fetchedFlagIds) {
    print('📤 QA Message Service: Broadcasting fetched flag IDs');
    print('   FetchedFlagIds: ${jsonEncode(fetchedFlagIds)}');

    final campaignsData = {'variations': fetchedFlagIds};
    _liveVariationsIdsController.add(campaignsData);
  }

  /// Broadcast start QA Assistant command from Flagship SDK
  void broadcastStartQAAssistant() {
    print('📤 QA Message Service: Broadcasting start QA Assistant');
    _startCommandController.add(null);
  }

  /// Broadcast stop QA Assistant command from Flagship SDK
  void broadcastStopQAAssistant() {
    print('📤 QA Message Service: Broadcasting stop QA Assistant command');
    _stopCommandController.add(null);
  }
}
