import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship/visitor/strategy/default_strategy.dart';

// This class represent the NO CONSENT behaviour
class NoConsentStrategy extends DefaultStrategy {
  NoConsentStrategy(Visitor visitor) : super(visitor);

// The activate modification is not allowed
  @override
  // Future<void> activateModification(String key) async {
  // Flagship.logger(Level.INFO, CONSENT_ACTIVATE);
  // }

  @override
  Future<void> activateFlag(Modification pFlag,
      {bool isDuplicated = false}) async {
    Flagship.logger(Level.INFO, CONSENT_ACTIVATE);
  }

// The send hits is not allowed, except the consent event
  @override
  Future<void> sendHit(BaseHit hit) async {
    switch (hit.type) {
      case HitCategory.CONSENT:
        {
          visitor.trackingManager?.sendHit(hit);
        }
        break;
      default:
        Flagship.logger(Level.INFO, CONSENT_HIT);
    }
  }

  @override
  Future<bool> lookupVisitor(String visitoId) async {
    Flagship.logger(Level.INFO, "No lookup Visitor when not consent");
    return false;
  }

  @override
  void lookupHits() async {
    Flagship.logger(Level.INFO, "No lookup Hits when not consent");
  }

  @override
  void onExposure(Modification pModification) {
    Flagship.logger(Level.INFO, CONSENT_ACTIVATE);
  }

  @override
  collectEmotionsAIEvents(String screenName) {
    Flagship.logger(Level.INFO, CONSENT_EAI);
  }
}
