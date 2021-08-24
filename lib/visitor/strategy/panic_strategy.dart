import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';

import '../../flagship.dart';

class PanicStrategy extends DefaultStrategy {
  PanicStrategy(Visitor visitor) : super(visitor);

  @override
  Future<void> activateModification(String key) async {
    Flagship.logger(Level.INFO, PANIC_ACTIVATE);
  }

  @override
  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    return defaultValue;
  }

  @override
  void updateContext<T>(String key, T value) {}

  @override
  void testAction() {
    print("action from panic strategy ");
  }
}
