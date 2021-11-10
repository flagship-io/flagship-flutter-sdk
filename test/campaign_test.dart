import 'package:flutter_test/flutter_test.dart';
import 'package:flagship/model/campaign.dart';

void main() {
  test("Campaign", () {
    Map<String, dynamic> inputs = {};

    Campaign itemCamp = Campaign.fromJson(inputs);
    expect(itemCamp.idCampaign, "");
    expect(itemCamp.variationGroupId, "");
    expect(itemCamp.variation, null);
  });
}
