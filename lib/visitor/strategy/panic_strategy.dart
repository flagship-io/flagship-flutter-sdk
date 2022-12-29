import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';

// This class represent the PANIC behaviour
class PanicStrategy extends DefaultStrategy {
  PanicStrategy(Visitor visitor) : super(visitor);

  @override
  Future<void> activateModification(String key) async {
    Flagship.logger(Level.INFO, PANIC_ACTIVATE);
  }

  @override
  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    Flagship.logger(Level.ERROR, PANIC_MODIFICATION);
    return defaultValue;
  }

  @override
  void updateContext<T>(String key, T value) {
    Flagship.logger(Level.ERROR, PANIC_UPDATE_CONTEXT);
  }

  @override
  Map<String, Object>? getModificationInfo(String key) {
    Flagship.logger(
        Level.ERROR, PANIC_MODIFICATION_INFO.replaceFirst("%s", key));
    return null;
  }

  @override
  Future<void> sendHit(BaseHit hit) async {
    Flagship.logger(Level.INFO, PANIC_HIT);
  }

  @override
  void setConsent(bool isConsent) {
    Flagship.logger(Level.INFO, PANIC_HIT_CONSENT);
  }

  @override
  authenticateVisitor(String visitorId) {
    Flagship.logger(Level.INFO, PANIC_AUTHENTICATE);
  }

  @override
  unAuthenticateVisitor() {
    Flagship.logger(Level.INFO, PANIC_UNAUTHENTICATE);
  }
}
