import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship/visitor/visitor_strategy.dart';

class DefaultStrategy extends VisitorStrategy {
  DefaultStrategy(Visitor visitor) : super(visitor);

  @override
  void updateContext<T>(String key, T value) {
    switch (value.runtimeType) {
      case int:
      case double:
      case String:
      case bool:
        // _context.addAll({key: value as Object});
        break;
      default:
        Flagship.logger(Level.WARNING, CONTEXT_PARAM_ERROR);
    }
  }

  /// Activate
  Future<void> _sendActivate(Modification pModification) async {
    // Construct the activate hit
    // Refractor later the envId
    Activate activateHit = Activate(pModification, visitor.visitorId,
        Flagship.sharedInstance().envId ?? "");

    await visitor.trackingManager.sendActivate(activateHit);
  }

  @override
  Future<void> activateModification(String key) async {
    if (!visitor.decisionManager.isPanic() &&
        visitor.modifications.containsKey(key)) {
      try {
        var modification = visitor.modifications[key];

        if (modification != null) {
          await _sendActivate(modification);
        }
      } catch (exp) {
        Flagship.logger(Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$exp"));
      }
    }
  }

  @override
  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    var ret = defaultValue;

    if (!visitor.decisionManager.isPanic() &&
        visitor.modifications.containsKey(key)) {
      try {
        var modification = visitor.modifications[key];

        if (modification == null) {
          Flagship.logger(
              Level.INFO, GET_MODIFICATION_ERROR.replaceFirst("%s", key));
          return ret;
        }
        switch (T) {
          case double:
            if (modification.value is double) {
              ret = modification.value as T;
              break;
            }

            if (modification.value is int) {
              ret = (modification.value as int).toDouble() as T;
              break;
            }
            Flagship.logger(Level.INFO,
                "Modification value ${modification.value} type ${modification.value.runtimeType} cannot be casted as $T, will return default value");
            break;
          default:
            if (modification.value is T) {
              ret = modification.value as T;
              break;
            }
            Flagship.logger(Level.INFO,
                "Modification value ${modification.value} type ${modification.value.runtimeType} cannot be casted as $T, will return default value");
            break;
        }
        if (activate) {
          /// send activate later
          _sendActivate(modification);
        }
      } catch (exp) {
        Flagship.logger(Level.INFO,
            "an exception raised  $exp , will return a default value ");
      }
    }
    return ret;
  }

  @override
  Map<String, Object>? getModificationInfo(String key) {
    if (!visitor.decisionManager.isPanic() &&
        visitor.modifications.containsKey(key)) {
      try {
        var modification = visitor.modifications[key];
        return modification?.toJson();
      } catch (exp) {
        return null;
      }
    } else {
      Flagship.logger(
          Level.ERROR, GET_MODIFICATION_INFO_ERROR.replaceFirst("%s", key));
      return null;
    }
  }

  /// Synchronize modification for the visitor
  @override
  Future<Status> synchronizeModifications() async {
    Flagship.logger(Level.ALL, SYNCHRONIZE_MODIFICATIONS);
    Status state = Status.NOT_INITIALIZED;
    try {
      var camp = await visitor.decisionManager.getCampaigns(
          Flagship.sharedInstance().envId ?? "",
          visitor.visitorId,
          visitor.getContext());
      // Clear the previous modifications
      visitor.modifications.clear();
      // Update panic value
      visitor.decisionManager.updatePanicMode(camp.panic);
      if (camp.panic) {
        state = Status.PANIC_ON;
      } else {
        var modif = visitor.decisionManager.getModifications(camp.campaigns);
        visitor.modifications.addAll(modif);
        Flagship.logger(
            Level.INFO,
            SYNCHRONIZE_MODIFICATIONS_RESULTS.replaceFirst(
                "%s", "${visitor.modifications}"));
        state = Status.READY;
      }
    } catch (error) {
      Flagship.logger(Level.EXCEPTIONS,
          EXCEPTION.replaceFirst("%s", "${error.toString()}"));
    }

    // Update the state
    Flagship.updateState(state);

    /// Return the state
    return state;
  }

  @override
  Future<void> sendHit(BaseHit hit) async {
    if (visitor.decisionManager.isPanic()) {
      Flagship.logger(Level.INFO, PANIC_HIT);
      return;
    }
    await visitor.trackingManager.sendHit(hit);
  }
}
