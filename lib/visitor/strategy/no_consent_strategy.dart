import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';

import '../../flagship.dart';

class NoConsentStrategy extends DefaultStrategy {
  NoConsentStrategy(Visitor visitor) : super(visitor);

  @override
  Future<void> activateModification(String key) async {
    Flagship.logger(Level.INFO, CONSENT_ACTIVATE);
  }

  @override
  Future<void> sendHit(BaseHit hit) async {
    switch (hit.type) {
      case Type.CONSSENT:
        {
          visitor.trackingManager.sendHit(hit);
        }
        break;
      default:
        Flagship.logger(Level.INFO, CONSENT_HIT);
    }
  }
}
