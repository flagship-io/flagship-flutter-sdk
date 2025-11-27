import 'package:flagship/visitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';
import 'package:flagship/model/modification.dart';
import 'package:abtastyqaassistant/abtastyqaassistant.dart';

/// QA Assistant Strategy that connects to QA Assistant package
class QassistantStrategy extends DefaultStrategy {
  //final FlagshipQAListener flagshipListener = FlagshipQAListener();
  late final FlagshipQAMessageHandler _messageHandler;

  /// Map des modifications QA qui override celles du visitor
  final Map<String, Modification> modifications = {};

  QassistantStrategy(Visitor visitor) : super(visitor) {
    // Register the message handler to receive FSModification messages
    final messageService = getQAMessageService();
    _messageHandler = FlagshipQAMessageHandler(visitor, this);
    messageService.registerHandler(_messageHandler);

    //flagshipListener.startListening();
    print('✅ QA Strategy: FSModification message handler registered');
  }

  void cleanup() {
    // Clean up when strategy is disposed
    final messageService = getQAMessageService();
    messageService.unregisterHandler();
    // flagshipListener.stopListening();
    print('🧹 QA Strategy: Message handler unregistered');
  }

  @override
  Modification? getFlagModification(String key) {
    // D'abord chercher dans les modifications QA
    if (modifications.containsKey(key)) {
      print('🎯 QA Override: Using QA modification for key: $key');
      return modifications[key];
    }

    // Sinon chercher dans les modifications du visitor
    Modification? ret = super.getFlagModification(key);
    print(
        '📦 Visitor: Using visitor modification for key: $key, value: ${ret?.value}');
    return ret;
  }

  @override
  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    // D'abord chercher dans les modifications QA
    if (modifications.containsKey(key)) {
      final modification = modifications[key];
      if (modification != null) {
        print('🎯 QA Override: Using QA modification for key: $key');
        try {
          return modification.value as T;
        } catch (e) {
          print('⚠️ Type conversion error for QA modification: $e');
          return defaultValue;
        }
      }
    }

    // Sinon utiliser la méthode parent
    return super.getModification(key, defaultValue, activate: activate);
  }
}

/// Implementation of QAMessageHandler to receive FSModification messages from QA Assistant
class FlagshipQAMessageHandler implements QAMessageHandler {
  final Visitor visitor;
  final QassistantStrategy strategy;

  FlagshipQAMessageHandler(this.visitor, this.strategy);

  @override
  void handleModificationMessage(ModificationMessage message) {
    print('🎯 Flagship: Received FSModification message');
    print('📄 Message JSON: ${message.toJsonString()}');
    print('');
    print('Campaign Details:');
    print('  - ID: ${message.campaignId}');
    print('  - Name: ${message.campaignName}');
    print('  - Type: ${message.campaignType}');
    print('');
    print('Variation Group:');
    print('  - ID: ${message.variationGroupId}');
    print('  - Name: ${message.variationGroupName}');
    print('');
    print('Variation Details:');
    print('  - ID: ${message.variationId}');
    print('  - Name: ${message.variationName}');
    print('  - Is Reference: ${message.isReference}');
    print('');
    print('Modifications:');

    // Apply each modification to the QA strategy modifications map
    for (final entry in message.modifications["value"]!.entries) {
      final key = entry.key;
      final value = entry.value;

      // Create a Modification object and add it to strategy.modifications
      final modification = Modification(
        key,
        message.campaignId,
        message.campaignName,
        message.variationGroupId,
        message.variationGroupName,
        message.variationId,
        message.variationName,
        message.isReference,
        message.campaignType,
        null, // slug is optional
        value,
      );

      strategy.modifications[key] = modification;
      print('  ✓ $key: $value (added to QA modifications)');
    }

    print('✅ All modifications applied to QA strategy.modifications');
    print('📊 Total QA modifications: ${strategy.modifications.length}');
  }

  @override
  void handleConfigurationUpdate(Map<String, dynamic> config) {
    print('⚙️ Flagship: Configuration update received');
    print('   Config: $config');

    // Handle configuration updates if needed
  }

  @override
  void handleRefreshCommand() {
    print('🔄 Flagship: Refresh command received');
    visitor.fetchFlags();
    print('✅ Visitor flags refreshed');
  }

  @override
  void handleResetCommand() {
    print('🔄 Flagship: Reset command received');
    visitor.getContext().clear();
    visitor.fetchFlags();
    print('✅ Visitor context cleared and flags refreshed');
  }
}
