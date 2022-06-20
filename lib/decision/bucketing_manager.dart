import 'dart:convert';
import 'dart:io';
import 'package:flagship/Targeting/targeting_manager.dart';
import 'package:flagship/api/endpoints.dart';
import 'package:flagship/api/service.dart';
import 'package:flagship/decision/decision_manager.dart';
import 'package:flagship/decision/polling/polling.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/model/bucketing.dart';
import 'package:flagship/model/campaign.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/model/variation.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:murmurhash/murmurhash.dart';

class BucketingManager extends DecisionManager {
  final int intervalPolling;
  Polling? polling;
  bool fileExists = true;

  late Future<SharedPreferences> _prefs;
  late Campaigns campaigns;

  String lastModfiedKey = "FSLastModifiedScript";
  String bucketingFolder = "/flagship/Bucketing/";
  String fileName = "bucketing.json";

  BucketingManager(Service service, this.intervalPolling) : super(service) {
    _prefs = SharedPreferences.getInstance();
  }

//@@@@@@@@@@@@@@@@@@@@
  @override
  Future<Campaigns> getCampaigns(String envId, String visitorId, Map<String, Object> context) async {
    /// Read File before
    String jsonString = await _readFile().catchError((error) {
      Flagship.logger(Level.ALL, "Error on reading the saved bucketing file");
    });

    Bucketing bucketingObject = Bucketing.fromJson(json.decode(jsonString));

    return bucketVariations(visitorId, bucketingObject, context);
  }

  _downloadScript() async {
    SharedPreferences prefs = await _prefs;
    // Create url
    String urlString = Endpoints.BucketingScript.replaceFirst("%s", Flagship.sharedInstance().envId ?? "");

    var response = await this.service.sendHttpRequest(
        // {"if-modified-since": prefs.getString(lastModfiedKey) ?? ""}
        RequestType.Get,
        urlString,
        {},
        null,
        timeoutMs: Flagship.sharedInstance().getConfiguration()?.timeout ?? TIMEOUT);
    switch (response.statusCode) {
      case 200:
        Flagship.logger(Level.ALL, response.body, isJsonString: true);
        String? lastModified = response.headers["last-modified"];
        if (lastModified != null) {
          prefs.setString(lastModfiedKey, lastModified);
        }
        // Save response body
        _saveFile(response.body);
        break;
      case 304:
        Flagship.logger(Level.ALL, "The bucketing script is not modified since last download");
        break;
      default:
        Flagship.logger(Level.ALL, "Failed to download script for bucketing");
        throw Exception('Flagship, Failed on getting bucketing script');
    }
  }

  @override
  void startPolling() {
    // Create and launch the polling process here...
    this.polling = Polling(intervalPolling, () async {
      await _downloadScript();
    });
    this.polling?.start();
  }

  // Save the response into the file
  _saveFile(String body) async {
    final directory = await getApplicationDocumentsDirectory();
    Directory bucketingDirectory =
        await Directory.fromUri(Uri.file(directory.path + bucketingFolder)).create(recursive: true).catchError((error) {
      print("Enable to create the directory to save the buckting file ");
    });
    // We got the path to save the json file
    File jsonFile = File(bucketingDirectory.path + fileName);
    jsonFile.writeAsString(body);
  }

// Read the file saved
  Future<String> _readFile() async {
    final directory = await getApplicationDocumentsDirectory();
    File jsonFile = File(directory.path + bucketingFolder + fileName);
    if (jsonFile.existsSync() == true) {
      return jsonFile.readAsStringSync();
    } else {
      throw Exception('Flagship, Failed to read bucketing script');
    }
  }

  /// This is the entry for bucketing , that give the campaign infos as we do in api decesion
  Campaigns bucketVariations(String visitorId, Bucketing scriptBucket, Map<String, dynamic> context) {
    /// Check the panic mode
    if (scriptBucket.panic == true) {
      return Campaigns(visitorId, true, []);
    }

    // check if the user exist in the cache , if yes then read his own modification from the cache

    // If not extract the variations

    // check the targetings and filter the variation he can run

    // Match before
    Campaigns result = processBucketing(visitorId, scriptBucket, context);

    return result;

    // Save My bucketing
    // resultBucketCache.saveMe()

    // Fill Campaign with value to be read by singleton
    // return FSCampaigns(resultBucketCache);
  }

  Campaigns processBucketing(String visitorId, Bucketing scriptBucket, Map<String, dynamic> context) {
    Campaigns result = Campaigns(visitorId, false, []);
    TargetingManager targetManager = TargetingManager(visitorId, context);

    // Campaign
    for (BucketCampaign itemCamp in scriptBucket.campaigns) {
      // Variation group
      for (VariationGroup itemVarGroup in itemCamp.variationGroups) {
        // Check the targeting
        if (targetManager.isTargetingGroupIsOkay(itemVarGroup.targeting) == true) {
          print("The Targeting for " + itemVarGroup.idVariationGroup + "is OKAY 👍");

          String? varId = selectVariationWithMurMurHash(visitorId, itemVarGroup);

          if (varId != null) {
            // Create variation group
            Campaign camp = Campaign(itemCamp.idCampaign, itemVarGroup.idVariationGroup, itemCamp.type, itemCamp.slug);
            print("##### The variation choosen is $varId ###########");

            for (Variation itemVar in itemVarGroup.variations) {
              if (itemVar.idVariation == varId) {
                camp.variation = itemVar;
              }
            }

            /// Add this camp to the result
            result.campaigns.add(camp);
          }
        } else {
          print("The Targeting for " + itemVarGroup.idVariationGroup + "is KO 👎");
        }
      }
    }
    return result;
  }

  String? selectVariationWithMurMurHash(String visitorId, VariationGroup varGroup) {
    int hashAlloc;

    // We calculate the Hash allocation by the combonation of : visitorId + idVariationGroup
    String combinedId = varGroup.idVariationGroup + visitorId;

    // Calculate the murmurHash algorithm

    print(" ########## ${MurmurHash.v3(combinedId, 0)} ############");
    hashAlloc = (MurmurHash.v3(combinedId, 0) % 100);
    print("########### The MurMur fot the combined " + combinedId + " is : $hashAlloc #############");

    int offsetAlloc = 0;
    for (Variation itemVar in varGroup.variations) {
      if (hashAlloc < itemVar.allocation + offsetAlloc) {
        return itemVar.idVariation;
      }
      offsetAlloc += itemVar.allocation;
    }
    return null;
  }
}
