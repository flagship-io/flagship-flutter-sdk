import 'package:get_it/get_it.dart';
import 'qa_message_service.dart';

/// Get the GetIt instance
final getIt = GetIt.instance;

/// Initialize the QA Assistant service locator
/// This should be called once at app startup
void setupQAServiceLocator() {
  // Register QAMessageService as a singleton
  if (!getIt.isRegistered<QAMessageService>()) {
    getIt.registerSingleton<QAMessageService>(QAMessageService());
    print('✅ QA Service Locator: QAMessageService registered');
  }
}

/// Clean up the service locator
void cleanupQAServiceLocator() {
  if (getIt.isRegistered<QAMessageService>()) {
    getIt.unregister<QAMessageService>();
    print('🧹 QA Service Locator: QAMessageService unregistered');
  }
}

/// Get the QAMessageService instance
QAMessageService getQAMessageService() {
  if (!getIt.isRegistered<QAMessageService>()) {
    setupQAServiceLocator();
  }
  return getIt<QAMessageService>();
}
