import 'dart:convert';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/exposed_flag.dart';
import 'package:flagship/model/flag.dart';
import 'package:flagship/model/modification.dart';
import 'package:flagship/model/visitor_exposed.dart';
import 'package:flagship/utils/logger/log_manager.dart';

String internal_exposure_flag = "internal_exposure_flag";
String internal_exposure_visitor = "internal_exposure_visitor";

class Activate extends BaseHit {
  Modification? modification;
  String? anonymousId;
  String envId = "";

  // Exposed flag information
  String? exposure_flag;
  String? exposure_visitor;

  Activate(this.modification, String visitorId, this.anonymousId, this.envId,
      String? exposedFlag, String? exposedVisitor)
      : super() {
    this.visitorId = visitorId;
    type = HitCategory.ACTIVATION;
    this.exposure_flag = exposedFlag;
    this.exposure_visitor = exposedVisitor;
  }

// This is used to read an activate from the cache
  Activate.fromMap(String oldId, Map body) {
    // Set the type
    this.type = HitCategory.ACTIVATION;
    // Set the visitor
    super.visitorId = body["vid"] ?? "";
    // Set the aid if exist
    if (body["aid"] != null) {
      this.anonymousId = body["aid"];
    }
    // Set the old id
    this.id = oldId;
    // Set the client Id
    this.envId = body["cid"] ?? "";

    try {
      // Set the createdAt
      this.createdAt = DateTime.parse(body['createdAt']);
    } catch (e) {
      Flagship.logger(Level.EXCEPTIONS, e.toString());
      this.createdAt = DateTime.now();
    }

    // Create the modification object to set the "caid" & "vaid"
    if ((body["caid"] != null) && (body["vaid"] != null)) {
      modification = Modification("", "", "", body["caid"], "", body["vaid"],
          "", false, "campaignType", "slug", null);
    }
  }

  Map<String, Object> toJson() {
    Map<String, Object> result;

    result = {
      "vaid": modification?.variationId ?? "",
      "caid": modification?.variationGroupId ?? "",
      "vid": visitorId,
      "cid": envId
    };

    if (this.anonymousId != null) {
      result.addEntries({"aid": anonymousId ?? ""}.entries);
    }

    /// Add qt entries
    /// Time difference between when the activate hit was created and when it about to send it
    if (this.createdAt != null) {
      result.addEntries({
        "qt": DateTime.now()
            .difference(createdAt ?? DateTime.now())
            .inMilliseconds
      }.entries);
    }
    return result;
  }

  @override
  Map<String, Object> get bodyTrack {
    // Create with basic information
    var customBody = new Map<String, Object>();
    customBody.addEntries(this.toJson().entries);
    // Add Type t , to identify this hit as activate from the lookup hits
    customBody.addEntries({'t': typeOfEvent}.entries);

    // Set exposed flag info
    if (this.exposure_flag != null) {
      customBody.addEntries(
          {internal_exposure_flag: this.exposure_flag ?? ""}.entries);
    }
    // Set visitor expos info
    if (this.exposure_visitor != null) {
      customBody.addEntries(
          {internal_exposure_visitor: this.exposure_visitor ?? ""}.entries);
    }
    return customBody;
  }

  @override
  bool isValid() {
    return (this.visitorId.isNotEmpty &&
        this.envId.isNotEmpty &&
        this.modification != null);
  }

  FSExposedInfo? getExposedInfo() {
    if (this.exposure_flag != null) {
      // Create map for exposeFlag
      Map mapFlag = json.decode(this.exposure_flag ?? "");
      // create Expose Flag
      var p1 = ExposedFlag(mapFlag["key"], mapFlag["value"],
          mapFlag["defaultValue"], FlagMetadata.withMap(mapFlag["metadata"]));

      if (this.exposure_visitor != null) {
        // Create map for visitor expose
        Map mapVisitorExposure = json.decode(this.exposure_visitor ?? "");

        // Create visitor Expose
        var p2 = VisitorExposed(mapVisitorExposure["id"],
            mapVisitorExposure["anonymousId"], mapVisitorExposure["context"]);

        // Return the final object
        return FSExposedInfo(exposedFlag: p1, visitorExposed: p2);
      }
    }

    return null;
  }
}
