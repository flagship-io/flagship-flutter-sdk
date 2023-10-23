import 'dart:convert';

import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/dataUsage/data_usage_tracking.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/batch.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/tracking/tracking_manager.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';

extension TrackingManagerBatch on TrackingManager {
  // send hit batch
  Future<void> sendBatch(List<Hit> listOfHitToSend) async {
    // Create url
    String urlString = Endpoints.EVENT;
    Flagship.logger(Level.DEBUG, 'Sending hits using batch : ' + urlString);

    try {
      var response = await service.sendHttpRequest(
          RequestType.Post,
          urlString,
          Endpoints.getFSHeader(this.apiKey),
          jsonEncode(Batch(listOfHitToSend).bodyTrack),
          timeoutMs: TIMEOUT_REQUEST);
      switch (response.statusCode) {
        case 200:
        case 204:
        case 201:
          Flagship.logger(Level.INFO, HIT_SUCCESS);
          onSendBatchWithSuccess(listOfHitToSend);
          break;
        default:
          Flagship.logger(Level.ERROR, HIT_FAILED);
          hitDelegate?.onFailedToSendBatch(listOfHitToSend);
          DataUsageTracking.sharedInstance().processTroubleShootingHttp(
              CriticalPoints.SEND_BATCH_HIT_ROUTE_RESPONSE_ERROR.name,
              response);
      }
    } catch (error) {
      DataUsageTracking.sharedInstance()
          .processTroubleShootingException(null, error);
      hitDelegate?.onFailedToSendBatch(listOfHitToSend);
      Flagship.logger(
          Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$error") + urlString);
      Flagship.logger(Level.ERROR, HIT_FAILED);
    }
  }

  // Send activate batch
  Future<int> sendActivateBatch(List<Hit> listOfActivate) async {
    // Create url
    String urlString = Endpoints.DECISION_API + Endpoints.ACTIVATION;
    // Create an activate batch object
    ActivateBatch activateBatch = ActivateBatch(listOfActivate);
    // Encode batch before send it
    try {
      Object? objectToSend = jsonEncode(activateBatch.toJson());
      var response = await service.sendHttpRequest(RequestType.Post, urlString,
          Endpoints.getFSHeader(this.apiKey), objectToSend,
          timeoutMs: TIMEOUT_REQUEST);
      switch (response.statusCode) {
        case 200:
        case 204:
          Flagship.logger(Level.INFO, ACTIVATE_SUCCESS + ": $objectToSend");
          onSendActivateBatchWithSuccess(listOfActivate);
          return response.statusCode;
        default:
          Flagship.logger(Level.ERROR, HIT_FAILED);
          DataUsageTracking.sharedInstance().processTroubleShootingHttp(
              CriticalPoints.SEND_ACTIVATE_HIT_ROUTE_ERROR.name, response);

          return response.statusCode;
      }
    } on Exception catch (e) {
      DataUsageTracking.sharedInstance()
          .processTroubleShootingException(null, e);
      activateDelegate?.onFailedToSendBatch(listOfActivate);
      Flagship.logger(
          Level.EXCEPTIONS, EXCEPTION.replaceFirst("%s", "$e") + urlString);
      Flagship.logger(Level.ERROR, HIT_FAILED);
      return 500;
    }
  }
}
