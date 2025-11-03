import 'dart:convert';
import 'package:flagship/Targeting/targeting_manager.dart';
import 'package:flagship/dataUsage/data_usage_tracking.dart';
import 'package:flagship/emotionAi/emotion_tools.dart';
import 'package:flagship/emotionAi/fs_emotion.dart';
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

  Future<void> _sendActivate(
    Modification modification,
    bool isDuplicated,
  ) async {
    // Get config and callback
    final config = Flagship.sharedInstance().getConfiguration();
    final onExposed = config?.onVisitorExposed;

    // Prepare exposure object
    ExposedFlag? exposedFlag;
    VisitorExposed? exposedVisitor;
    if (onExposed != null) {
      exposedFlag = ExposedFlag(
        modification.key,
        modification.value,
        modification.defaultValue,
        FlagMetadata.withMap(modification.toJsonInformation()),
      );
      exposedVisitor = VisitorExposed(
        visitor.visitorId,
        visitor.anonymousId,
        visitor.getContext(),
      );
    }

    // When deduplicated
    if (isDuplicated) {
      if (onExposed != null && exposedFlag != null && exposedVisitor != null) {
        exposedFlag.alreadyActivatedCampaign = true;
        onExposed(exposedVisitor, exposedFlag);
      }
      Flagship.logger(Level.INFO, " The campaign's flag already activated ");
      return;
    }

    // When not duplicated
    final String? flagJson =
        exposedFlag != null ? jsonEncode(exposedFlag) : null;
    final String? visitorJson =
        exposedVisitor != null ? jsonEncode(exposedVisitor) : null;

    final activateHit = Activate(
      modification,
      visitor.visitorId,
      visitor.anonymousId,
      Flagship.sharedInstance().envId ?? '',
      flagJson,
      visitorJson,
    );

    // Send troubleshooting
    DataUsageTracking.sharedInstance().processTroubleShootingHits(
      CriticalPoints.VISITOR_SEND_ACTIVATE.name,
      visitor,
      activateHit,
    );

    // Send Activate hit
    try {
      final response = await visitor.trackingManager?.sendActivate(activateHit);
      final status = response?.statusCode ?? -1;
      if (status < 200 || status >= 300) {
        Flagship.logger(
          Level.ERROR,
          'ACTIVATE_FAILED: status code = $status',
        );
      }
    } catch (e, stack) {
      Flagship.logger(
        Level.ERROR,
        'ACTIVATE_FAILED: exception = $e\n$stack',
      );
    }
  }

  @override
  Future<void> activateFlag(Modification pModification,
      {bool isDuplicated = false}) async {
    return _sendActivate(pModification, isDuplicated);
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
          this._sendActivate(modification, false);
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
    var score = await _prepareEmotionAI();
    if (score != null) {
      this.visitor.emotionScoreAI = score;
      this.visitor.updateContext("eai::eas", score);
    }
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
      String visitorCacheData =
          jsonEncode(VisitorCache.fromVisitor(this.visitor).toJson());
      cacheVisitor(visitor.visitorId, visitorCacheData);
      // In bucketing mode, if anonymousId exists and no cache exists for it, cache the same data
      if (visitor.config.decisionMode == Mode.BUCKETING &&
          visitor.anonymousId != null) {
        // Check if cache exists for anonymousId
        bool anonymousExists = await visitor.config.visitorCacheImp
                ?.visitorExists(visitor.anonymousId ?? "") ??
            false;

        if (!anonymousExists) {
          // Cache the same visitor data with anonymousId as key
          cacheVisitor(visitor.anonymousId!, visitorCacheData);
          Flagship.logger(Level.DEBUG,
              "Cached visitor data for anonymousId: ${visitor.anonymousId} in bucketing mode");
        }
      }
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
    if (visitor.anonymousId == null) {
      visitor.anonymousId = visitor.visitorId;
      visitor.visitorId = pVisitorId;
      // Update fs_users
      visitor.updateContext(FS_USERS, pVisitorId);
    }

    DataUsageTracking.sharedInstance()
        .processTSXpc(CriticalPoints.VISITOR_AUTHENTICATE.name, this.visitor);

    // Update the xpc info for the emotionAI
    this
        .visitor
        .emotion_ai
        ?.updateTupleId(this.visitor.visitorId, this.visitor.anonymousId);
  }

  @override
  unAuthenticateVisitor() {
    if (visitor.anonymousId != null) {
      visitor.visitorId = visitor.anonymousId as String;
      visitor.anonymousId = null;
      // Update fs_users in context
      visitor.updateContext(FS_USERS, visitor.visitorId);
    }
    DataUsageTracking.sharedInstance()
        .processTSXpc(CriticalPoints.VISITOR_UNAUTHENTICATE.name, this.visitor);

    // Update the xpc info for the emotionAI
    this
        .visitor
        .emotion_ai
        ?.updateTupleId(this.visitor.visitorId, this.visitor.anonymousId);
  }

  @override
  void cacheVisitor(String pVisitorId, String jsonString) {
    visitor.config.visitorCacheImp?.cacheVisitor(pVisitorId, jsonString);
  }

  @override
  // Called right at visitor creation, return a jsonString corresponding to visitor. Return a jsonString
  Future<bool> lookupVisitor(String visitorId) async {
    var resultFromCacheBis = await visitor.config.visitorCacheImp
        ?.lookupVisitor(visitorId)
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
        // 3- Update the Score
        this.visitor.emotionScoreAI = cachedVisitor.getFromCacheEAIScore();
        this.visitor.eaiVisitorScored =
            (this.visitor.emotionScoreAI == null) ? false : true;

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

  @override
  FlagStatus getFlagStatus(String key) {
    if (this.visitor.modifications.containsKey(key)) {
      return this.visitor.flagStatus;
    } else {
      return FlagStatus.NOT_FOUND;
    }
  }

  @override
  collectEmotionsAIEvents(String screenName) {
    // if the emotion_ai is null create
    if (this.visitor.emotion_ai == null) {
      this.visitor.emotion_ai =
          EmotionAI(this.visitor.visitorId, this.visitor.anonymousId);
      this.visitor.emotion_ai?.delegate = this.visitor;
    }
    _prepareEmotionAI().then((score) {
      if (score != null) {
        Flagship.logger(Level.DEBUG,
            "Since the visitor ${visitor.visitorId} is already scored with $score the emotionAI process is skiped");
        // Update the score
        this.visitor.emotionScoreAI = score;
        this.visitor.eaiVisitorScored = true; // See later if we need this
        // Update the context
        // Save the response for the visitor database
        cacheVisitor(visitor.visitorId,
            jsonEncode(VisitorCache.fromVisitor(this.visitor).toJson()));
      } else {
        // Start the collect emotions
        this.visitor.emotion_ai?.startEAICollectForView(screenName);
      }
    });
  }

  // Prepare Emotions
  Future<String?> _prepareEmotionAI() async {
    // EAIActivation is enabled
    if (Flagship.sharedInstance().eaiActivationEnabled) {
      if (this.visitor.eaiVisitorScored) {
        // If the user is already scored, check local cache first.
        if (this.visitor.emotionScoreAI != null) {
          Flagship.logger(Level.INFO,
              "This user has an existing score: + $this.visitor.emotionScoreAI +  in local cache");
          DataUsageTracking.sharedInstance().processEaiGetScore(
              CriticalPoints.EMOTIONS_AI_SCORE_FROM_LOCAL_CACHE.name,
              visitor,
              null,
              this.visitor.emotionScoreAI);
          return this.visitor.emotionScoreAI;
        }
      } else {
        // Not scored: check remotely for an existing score
        var scoreObject =
            await EmotionAITools().fetchScore(this.visitor.visitorId);

        if (scoreObject.statusCode == 200) {
          Flagship.logger(Level.INFO,
              "The visitor ${this.visitor.visitorId} is already scored 🚀 🚀 🚀 🚀 🚀 🚀 ............");
          return scoreObject.score;
        } else if (scoreObject.statusCode == 204) {
          Flagship.logger(Level.INFO,
              "The visitor ${this.visitor.visitorId} is not scored 😕 😕 😕 😕 😕 😕 ............");
          return null;
        } else {
          return null;
        }
      }
    }
    // If eaiActivationEnabled is false, complete without a score.
    return null;
  }

  @override
  onAppScreenChange(String screenName) {
    this.visitor.emotion_ai?.onAppScreenChange(screenName);
  }
}
