import 'dart:async';

import 'package:flagship/model/modification.dart';
import 'package:flagship/api/tracking_manager.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';

class Visitor {
  /// VisitorId
  final String visitorId;

  /// Configuration
  final FlagshipConfig config;

  /// Context
  Map<String, Object> _context = {};

  /// Map for the modification , {"key for the flag": Modification object}
  Map<String, Modification> modifications = {};

  /// Core decision manager , can manage both modes for the sdk
  DecisionManager get decisionManager {
    return this.config.decisionManager;
  }

  TrackingManager trackingManager = TrackingManager();

  /// Create new instance for visitor
  ///
  /// config: this object manage the mode of the sdk and other params
  /// visitorId : the user ID for the visitor
  /// context : Map that represent the conext for the visitor
  Visitor(this.config, this.visitorId, Map<String, Object> context) {
    this.updateContextWithMap(context);
  }

  /// Update context directely with map for <String, Object>
  void clearContext() {
    _context.clear();
  }

  /// Update context directely with map for <String, Object>
  void updateContextWithMap(Map<String, Object> context) {
    _context.addAll(context);
    Flagship.logger(Level.INFO, CONTEXT_UPDATE.replaceFirst("%s", "$_context"));
  }

  /// Get the current context for the visitor
  ///
  /// Return a Map that represent the current context
  Map<String, Object> getCurrentContext() {
    return _context;
  }

  /// Update context with key and value
  ///
  /// key the name for the context (attribut)
  /// value can be int, double, String or boolean
  /// otherwise the update context skip with warnning log
  void updateContext<T>(String key, T value) {
    switch (value.runtimeType) {
      case int:
      case double:
      case String:
      case bool:
        _context.addAll({key: value as Object});
        break;
      default:
        Flagship.logger(Level.WARNING, CONTEXT_PARAM_ERROR);
    }
  }

  /// Get Modification
  ///
  /// key : the name of the key relative to modification
  /// defaultValue: the returned value if the key is not found
  ///
  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    var ret = defaultValue;

    if (!this.decisionManager.isPanic() &&
        this.modifications.containsKey(key)) {
      try {
        var modification = this.modifications[key];

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

  /// Get the modification infos relative to flag (modification)
  ///
  /// key : the name of the key relative to modification
  /// Return map {"campaignId":"xxx", "variationId" : "xxxx", "variationGroupId":"xxxxx", "isReference": true/false}
  Map<String, Object>? getModificationInfo(String key) {
    if (!this.decisionManager.isPanic() &&
        this.modifications.containsKey(key)) {
      try {
        var modification = this.modifications[key];
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
  Future<Status> synchronizeModifications() async {
    Flagship.logger(Level.ALL, SYNCHRONIZE_MODIFICATIONS);
    Status state = Status.NOT_INITIALIZED;
    try {
      var camp = await decisionManager.getCampaigns(
          Flagship.sharedInstance().envId ?? "", visitorId, _context);
      // Clear the previous modifications
      this.modifications.clear();
      // Update panic value
      this.decisionManager.updatePanicMode(camp.panic);
      if (camp.panic) {
        state = Status.PANIC_ON;
      } else {
        var modif = decisionManager.getModifications(camp.campaigns);
        this.modifications.addAll(modif);
        Flagship.logger(
            Level.INFO,
            SYNCHRONIZE_MODIFICATIONS_RESULTS.replaceFirst(
                "%s", "${this.modifications}"));
        state = Status.READY;
      }
    } catch (error) {
      Flagship.logger(Level.EXCEPTIONS,
          EXCEPTION.replaceFirst("%s", "${error.toString()}"));
    }

    /// Return the state
    return state;
  }

  /// Activate modification
  Future<void> activateModification(String key) async {
    if (!this.decisionManager.isPanic() &&
        this.modifications.containsKey(key)) {
      try {
        var modification = this.modifications[key];

        if (modification != null) {
          await _sendActivate(modification);
        }
      } catch (exp) {
        Flagship.logger(Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$exp"));
      }
    }
  }

  /// Activate
  Future<void> _sendActivate(Modification pModification) async {
    /// Construct the activate hit
    /// Refractor later the envId
    Activate activateHit = Activate(
        pModification, this.visitorId, Flagship.sharedInstance().envId ?? "");

    await trackingManager.sendActivate(activateHit);
  }

  /// Send hit
  Future<void> sendHit(Hit hit) async {
    if (this.decisionManager.isPanic()) {
      Flagship.logger(Level.INFO, PANIC_HIT);
      return;
    }
    await trackingManager.sendHit(hit);
  }
}
