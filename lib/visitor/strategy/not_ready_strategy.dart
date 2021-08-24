import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';

import '../../flagship.dart';

class NotReadyStrategy extends DefaultStrategy {
  NotReadyStrategy(Visitor visitor) : super(visitor);

  @override
  Future<void> activateModification(String key) async {
    Flagship.logger(Level.ERROR, ACTIVTAE_NOT_READY);
  }

  @override
  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    Flagship.logger(Level.ERROR, GETMODIFICATION_NOT_READY);
    return defaultValue;
  }

  @override
  Map<String, Object>? getModificationInfo(String key) {
    Flagship.logger(Level.ERROR, GETMODIFICATION_INFO_NOT_READY);
    return null;
  }

  @override
  Future<void> sendHit(Hit hit) async {
    Flagship.logger(Level.ERROR, HIT_NOT_READY);
  }
}
