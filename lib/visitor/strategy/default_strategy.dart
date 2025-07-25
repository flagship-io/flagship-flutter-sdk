import 'dart:convert';
import 'package:flagship/Targeting/targeting_manager.dart';
import 'package:flagship/dataUsage/data_usage_tracking.dart';
import 'package:flagship/hits/activate.dart';
import 'package:flagship/hits/event.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/exposed_flag.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/model/visitor_cache/visitor_cache.dart';
import 'package:flagship/status.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flagship/model/visitor_exposed.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship/visitor/Ivisitor.dart';

// This class represent the default behaviour
class DefaultStrategy implements IVisitor {
  final Visitor visitor;

  DefaultStrategy(this.visitor);

  @override
  void updateContext<T>(String key, T value) {
    switch (value.runtimeType) {
      case int:
      case double:
      case String:
      case bool:
        visitor.getContext().addAll({key: value as Object});
        break;
      default:
        Flagship.logger(Level.WARNING, CONTEXT_PARAM_ERROR);
    }
  }

  // Activate
  Future<void> _sendActivate(Modification pModification) async {
    // Check if the callback is defined
    String? exposedFlag;
    String? exposedVisitor;
    if (Flagship.sharedInstance().getConfiguration()?.onVisitorExposed !=
        null) {
      exposedFlag = jsonEncode(ExposedFlag(
              pModification.key,
              pModification.value,
              pModification.defaultValue,
              FlagMetadata.withMap(pModification.toJsonInformation()))
          .toJson());

      exposedVisitor = jsonEncode(VisitorExposed(
              visitor.visitorId, visitor.anonymousId, visitor.getContext())
          .toJson());
    }
    // Build the activate hit
    Activate activateHit = Activate(
        pModification,
        visitor.visitorId,
        visitor.anonymousId,
        Flagship.sharedInstance().envId ?? "",
        exposedFlag,
        exposedVisitor);
    // Process the troubleShooting
    DataUsageTracking.sharedInstance().processTroubleShootingHits(
        CriticalPoints.VISITOR_SEND_ACTIVATE.name, visitor, activateHit);
    visitor.trackingManager?.sendActivate(activateHit).then((activateResponse) {
      if (activateResponse.statusCode >= 200 &&
          activateResponse.statusCode < 300) {
      } else {
        Flagship.logger(
            Level.ERROR,
            ACTIVATE_FAILED +
                " status code = ${activateResponse.statusCode.toString()}");
      }
    });
  }

  @override
  Future<void> activateModification(String key) async {
    if (visitor.modifications.containsKey(key)) {
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
  Future<void> activateFlag(Modification pModification) async {
    return _sendActivate(pModification);
  }

  @override
  // Get Modification object, this object will be used by the flag class
  Modification? getFlagModification(String key) {
    return visitor.modifications[key];
  }

  @override
  T getModification<T>(String key, T defaultValue, {bool activate = false}) {
    var ret = defaultValue;

    bool hasSameType =
        true; // When the Type is not the same the activate won't be sent
    if (visitor.modifications.containsKey(key)) {
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
            hasSameType = false;
            Flagship.logger(Level.INFO,
                "Modification value ${modification.value} type ${modification.value.runtimeType} cannot be casted as $T, will return default value");
            break;
        }
        if (activate && hasSameType) {
          // Send activate later
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
  Map<String, dynamic>? getModificationInfo(String key) {
    if (visitor.modifications.containsKey(key)) {
      try {
        var modification = visitor.modifications[key];
        return modification?.toJsonInformation();
      } catch (exp) {
        return null;
      }
    } else {
      Flagship.logger(
          Level.ERROR, GET_MODIFICATION_INFO_ERROR.replaceFirst("%s", key));
      return null;
    }
  }

  // Synchronize modification for the visitor
  @override
  Future<FetchResponse?> fetchFlags() async {
    Flagship.logger(Level.ALL, SYNCHRONIZE_MODIFICATIONS);
    // get actual state flagship sdk
    FSSdkStatus state = Flagship.getStatus();
    DataUsageTracking.sharedInstance().processDataUsageTracking(visitor);
    try {
      var camp = await visitor.decisionManager.getCampaigns(
          Flagship.sharedInstance().envId ?? "",
          visitor.visitorId,
          visitor.anonymousId,
          visitor.getConsent(),
          visitor.getContext());
      // Clear the previous modifications
      visitor.modifications.clear();
      // Update panic value
      visitor.decisionManager.updatePanicMode(camp.panic);
      if (camp.panic) {
        state = FSSdkStatus.SDK_PANIC;
        // Stop batching loop when the panic mode is ON
        visitor.trackingManager?.stopBatchingLoop();
      } else {
        state = FSSdkStatus.SDK_INITIALIZED;
        var modif = visitor.decisionManager.getModifications(camp.campaigns);
        visitor.modifications.addAll(modif);
        // Start Batching loop
        visitor.trackingManager?.startBatchingLoop();
        Flagship.logger(
            Level.INFO,
            SYNCHRONIZE_MODIFICATIONS_RESULTS.replaceFirst(
                "%s", "${visitor.modifications.keys}"));
      }
      // Update the state for Flagship
      visitor.flagshipDelegate.onUpdateState(state);

      // Save the response for the visitor database
      cacheVisitor(visitor.visitorId,
          jsonEncode(VisitorCache.fromVisitor(this.visitor).toJson()));
      // Update the dataUsage tracking
      visitor.dataUsageTracking
          .updateTroubleshooting(camp.accountSettings?.troubleshooting);
      // Notify the data report
      DataUsageTracking.sharedInstance().processTSFetching(this.visitor);

      return FetchResponse(
          camp.panic ? FlagStatus.PANIC : FlagStatus.FETCHED, null);
      // return null;
    } catch (error) {
      // Report the error
      Flagship.logger(Level.EXCEPTIONS,
          EXCEPTION.replaceFirst("%s", "${error.toString()}"));
      DataUsageTracking.sharedInstance()
          .processTroubleShootingException(visitor, error);
      return FetchResponse(FlagStatus.FETCH_REQUIRED, Error());
    }
  }

  @override
  Future<void> sendHit(BaseHit hit) async {
    DataUsageTracking.sharedInstance().processTroubleShootingHits(
        CriticalPoints.VISITOR_SEND_HIT.name, this.visitor, hit);
    await visitor.trackingManager?.sendHit(hit);
  }

  @override
  void setConsent(bool isConsent) {
    // Create the hit of consent
    Consent hitConsent = Consent(hasConsented: isConsent);
    // Send hit ...
    visitor.sendHit(hitConsent);
  }

  @override
  authenticateVisitor(String pVisitorId) {
    if (visitor.config.decisionMode == Mode.DECISION_API) {
      if (visitor.anonymousId == null) {
        visitor.anonymousId = visitor.visitorId;
        visitor.visitorId = pVisitorId;
        // Update fs_users
        visitor.updateContext(FS_USERS, pVisitorId);
      }

      DataUsageTracking.sharedInstance()
          .processTSXpc(CriticalPoints.VISITOR_AUTHENTICATE.name, this.visitor);
    } else {
      Flagship.logger(Level.ALL,
          "AuthenticateVisitor method will be ignored in Bucketing configuration");
    }
  }

  @override
  unAuthenticateVisitor() {
    if (visitor.config.decisionMode == Mode.DECISION_API) {
      if (visitor.anonymousId != null) {
        visitor.visitorId = visitor.anonymousId as String;
        visitor.anonymousId = null;

        // Update fs_users in context
        visitor.updateContext(FS_USERS, visitor.visitorId);
      }
      DataUsageTracking.sharedInstance().processTSXpc(
          CriticalPoints.VISITOR_UNAUTHENTICATE.name, this.visitor);
    } else {
      Flagship.logger(Level.ALL,
          "unAuthenticateVisitor method will be ignored in Bucketing configuration");
    }
  }

  @override
  void cacheVisitor(String visitorId, String jsonString) {
    visitor.config.visitorCacheImp?.cacheVisitor(visitor.visitorId, jsonString);
  }

  @override
  // Called right at visitor creation, return a jsonString corresponding to visitor. Return a jsonString
  Future<bool> lookupVisitor(String visitoId) async {
    var resultFromCacheBis = await visitor.config.visitorCacheImp
        ?.lookupVisitor(visitor.visitorId)
        .timeout(
            Duration(
                milliseconds:
                    visitor.config.visitorCacheImp?.visitorCacheLookupTimeout ??
                        200), onTimeout: () {
      Flagship.logger(
          Level.ERROR, "Timeout on trying to read the cache visitor");
      return "";
    });
    if (resultFromCacheBis != null && resultFromCacheBis.length != 0) {
      // convert to Map
      Map<String, dynamic> result = jsonDecode(resultFromCacheBis);
      // Retreive the json string stored in the visitor filed of this map.
      if (result['visitor'] != null) {
        VisitorCache cachedVisitor =
            VisitorCache.fromJson(jsonDecode(result['visitor']));
        Flagship.logger(Level.DEBUG,
            'The cached visitor get through the lookup is ${cachedVisitor.toString()}');
        // update the current visitor with his own cached data
        // 1 - update modification Map<String, Modification> modifications
        visitor.modifications
            .addEntries(cachedVisitor.getModifications().entries);
        // 2- Update the assignation history
        visitor.decisionManager.updateAssignationHistory(
            cachedVisitor.getAssignationHistory() ?? {});
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  @override
  void lookupHits() async {
    // Load the hits in cache if exist
    visitor.config.hitCacheImp?.lookupHits().then((value) {
      // Convert hits map to list hit
      List<BaseHit> remainListOfTrackInCache =
          FlagshipTools.converMapToListOfHits(value);
      List<String> invalidIds = [];
      List<BaseHit> remainTracking = [];
      //Remove oldest hit
      remainListOfTrackInCache.forEach((element) {
        if (element.isLessThan4H()) {
          remainTracking.add(element);
        } else {
          invalidIds.add(element.id);
        }
      });
      // Add backed elements of tracking
      if (remainTracking.isNotEmpty) {
        Flagship.logger(Level.DEBUG,
            "Adding the founded hits and activate in cache to the pools");
        visitor.trackingManager?.addTrackingElementsToBatch(remainTracking);
      }
      // Remove invalide hits or activate
      if (invalidIds.isNotEmpty) {
        Flagship.logger(Level.INFO,
            "Some tracking found in cache are useless because their date of creation is more than 4 hours, the process will remove them");
        visitor.config.hitCacheImp?.flushHits(invalidIds);
      }
    }).timeout(
        Duration(
            milliseconds: visitor.config.hitCacheImp?.hitCacheLookupTimeout ??
                200), onTimeout: () {
      Flagship.logger(Level.ERROR, "Timeout on reading hits for cache");
    });
  }

  void onExposure(Modification pModification) {
    Flagship.sharedInstance().getConfiguration()?.onVisitorExposed?.call(
        VisitorExposed(
            visitor.visitorId, visitor.anonymousId, visitor.getContext()),
        ExposedFlag(
            pModification.key,
            pModification.value,
            pModification.defaultValue,
            FlagMetadata.withMap(pModification.toJsonInformation())));
  }

  // void onExposureBis(List<FSExposedInfo> exposureInfos) {
  //   print(" @@@@@@@@@ callback exposure is called with " +
  //       exposureInfos.length.toString() +
  //       " Activate @@@@@@@@@@@@@@@@@");
  //   exposureInfos.forEach((item) {
  //     print(" onExposure item " + item.visitorExposed.id);

  //     Flagship.sharedInstance()
  //         .getConfiguration()
  //         ?.onVisitorExposed
  //         ?.call(item.visitorExposed, item.exposedFlag);
  //   });
  // }

  @override
  FlagStatus getFlagStatus(String key) {
    if (this.visitor.modifications.containsKey(key)) {
      return this.visitor.flagStatus;
    } else {
      return FlagStatus.NOT_FOUND;
    }
  }
}
