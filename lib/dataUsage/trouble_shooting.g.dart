part of 'data_usage_tracking.dart';

Map<String, String> _createTRFlagsInfo(
    Map<String, Modification> modifications) {
  Map<String, String> ret = {};

  modifications.forEach((flagKey, flagModification) {
    ret.addEntries({
      "visitor.flags.[$flagKey].key": flagKey,
      "visitor.flags.[$flagKey].value": flagModification.value.toString(),
      "visitor.flags.[$flagKey].metadata.campaignId":
          flagModification.campaignId,
      "visitor.flags.[$flagKey].metadata.variationGroupId":
          flagModification.variationGroupId,
      "visitor.flags.[$flagKey].metadata.variationGroupName":
          flagModification.variationGroupName,
      "visitor.flags.[$flagKey].metadata.variationId":
          flagModification.variationId,
      "visitor.flags.[$flagKey].metadata.variationName":
          flagModification.variationName,
      "visitor.flags.[$flagKey].metadata.isReference":
          flagModification.isReference.toString(),
      "visitor.flags.[$flagKey].metadata.campaignType":
          flagModification.campaignType,
      "visitor.flags.[$flagKey].metadata.campaignName":
          flagModification.campaignName,
      "visitor.flags.[$flagKey].metadata.slug": flagModification.slug ?? ""
    }.entries);
  });

  return ret;
}

Map<String, String> _createTRContext(Visitor v) {
  Map<String, Object> ctx = v.getContext();

  Map<String, String> ret = {};
  ctx.forEach((ctxKey, ctxValue) {
    ret.addEntries({"visitor.context.[$ctxKey]": ctxValue.toString()}.entries);
  });
  return ret;
}

// For the XPC
Map<String, String> _createTSxpc(Visitor v) {
  return _createTRContext(v);
}

// For the hit and activate
Map<String, String> _createTSendHit(Visitor v, Hit h) {
  Map<String, String> contentHit = {};
  h.bodyTrack.forEach((key, value) {
    contentHit.addEntries({"hit.$key": value.toString()}.entries);
  });
  return contentHit;
}

// For HTTP & Buckeitng
Map<String, String> _createTSHttp(BaseRequest? r, Response resp) {
  return {
    "http.request.headers": r?.headers.toString() ?? "",
    "http.request.method": r?.method ?? "",
    "http.request.url": r?.url.path ?? "",
    "http.response.body": resp.body.toString(),
    "http.response.headers": resp.headers.toString(),
    "http.response.code": resp.statusCode.toString(),
  };
}

Map<String, String> createTroubleShooitngFlag(Flag f, Visitor v) {
  return {
    "flag.key": f.key,
    "flag.defaultValue": f.defaultValue.toString(),
  };
}

Map<String, String> _createSdkConfig(FlagshipConfig? sdkConfig) {
  return {
    /// SDK
    "sdk.config.usingOnVisitorExposed":
        (sdkConfig?.onVisitorExposed != null).toString(),
    "sdk.config.usingCustomVisitorCache":
        (!(sdkConfig?.visitorCacheImp is DefaultCacheVisitorImp)).toString(),
    "sdk.config.usingCustomHitCache":
        (!(sdkConfig?.hitCacheImp is DefaultCacheHitImp)).toString(),
    "sdk.config.trackingManager.strategy":
        sdkConfig?.trackingManagerConfig.batchStrategy.name ?? "",
    "sdk.config.trackingManager.batchIntervals":
        ((sdkConfig?.trackingManagerConfig.batchIntervals ?? 0) * 1000)
            .toString(),
    "sdk.config.timeout": sdkConfig?.timeout.toString() ?? "",
    "sdk.config.pollingTime": ((sdkConfig?.pollingTime ?? 0) * 1000).toString(),
    "sdk.config.mode": sdkConfig?.decisionMode.name ?? "",
    "sdk.config.trackingManager.poolMaxSize":
        sdkConfig?.trackingManagerConfig.poolMaxSize.toString() ?? "",

    "sdk.config.decisionApiUrl": Endpoints.DECISION_API,
    "sdk.status": Flagship.getStatus().name,
    "sdk.lastInitializationTimestamp":
        Flagship.sharedInstance().lastInitializationTimestamp,
    "sdk.config.logLevel":
        Flagship.sharedInstance().getConfiguration()?.getLevel().name ?? ""
  };
}
