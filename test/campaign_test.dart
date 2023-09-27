import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flagship/model/campaign.dart';
import 'package:flagship/model/campaigns.dart';
import 'package:flagship/model/modification.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  test("Campaign", () {
    Map<String, dynamic> inputs = {};

    Campaign itemCamp = Campaign.fromJson(inputs);
    expect(itemCamp.idCampaign, "");
    expect(itemCamp.variationGroupId, "");
    expect(itemCamp.variation, null);
  });

  test("CampaignS", () {
    Map<String, dynamic> inputs = {};

    Campaigns itemCamps = Campaigns.fromJson(inputs);
    expect(itemCamps.visitorId, "");
    expect(itemCamps.panic, false);
    expect(itemCamps.campaigns.length, 0);

    Map<String, dynamic> inputsBis = {
      "visitorId": "2020072318165329233",
      "campaigns": [
        {
          "id": "bsffhle242b2l3igq4dgb",
          "variationGroupId": "bsffhle242b2l3igq4egaab",
          "variation": {
            "id": "bsffhle242b2l3igq4f0b",
            "modifications": {
              "type": "JSON",
              "value": {"key1": "val1", "key2": 12}
            },
            "reference": false
          }
        }
      ]
    };

    Campaigns itemCampsBis = Campaigns.fromJson(inputsBis);
    expect(itemCampsBis.visitorId, "2020072318165329233");
    expect(itemCampsBis.panic, false);
    expect(itemCampsBis.campaigns.length, 1);

    var allModifs = itemCampsBis.getAllModification();
    expect(allModifs.length, 2);
    expect(allModifs["key1"], "val1");
  });

  test("Modification", () {
    Modification itemModif = Modification(
        "key1",
        "campaignId",
        "campName",
        "variationGroupId",
        "vargName",
        "variationId",
        "varName",
        true,
        "ab",
        "slug",
        12);

    expect(itemModif.toJson().length, 6);
    expect(itemModif.value, 12);
    expect(itemModif.toJsonInformation().length, 6);
  });
}
