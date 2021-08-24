import 'package:flagship/hits/hit.dart';
import 'package:flagship/visitor/Ivisitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';
import 'package:flagship/visitor/strategy/no_consent_strategy.dart';
import 'package:flagship/visitor/strategy/panic_strategy.dart';
import 'package:flagship/visitor/strategy/not_ready_strategy.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/visitor/visitor_strategy.dart';

import '../visitor.dart';

class VisitorDelegate implements IVisitor {
  final Visitor visitor;

  VisitorDelegate(this.visitor);

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

  @override
  Future<void> activateModification(String key) {
    return getStrategy().activateModification(key);
  }

  @override
  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    return getStrategy().getModification(key, defaultValue, activate: activate);
  }

  @override
  Map<String, Object>? getModificationInfo(String key) {
    return getStrategy().getModificationInfo(key);
  }

  Future<Status> synchronizeModifications() {
    return getStrategy().synchronizeModifications();
  }

  @override
  void updateContext<T>(String key, T value) {
    getStrategy().updateContext(key, value);
  }

  @override
  Future<void> sendHit(BaseHit hit) async {
    getStrategy().sendHit(hit);
  }
}
