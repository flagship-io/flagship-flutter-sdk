import 'package:flagship/flagship.dart';
import 'package:flagship/hits/event.dart';
import 'package:flagship/hits/item.dart';
import 'package:flagship/hits/page.dart';
import 'package:flagship/hits/screen.dart';
import 'package:flagship/hits/transaction.dart';
import 'package:flagship/utils/flagship_tools.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test("Test hitsToMap", () {
    // Create Event
    Event testEvent =
        Event(action: "convertToMap", category: EventCategory.Action_Tracking);
    testEvent.visitorId = "userToMap";
    testEvent.id = "id1";

    // Create Screen
    Screen testScreen = Screen(location: "locationToMap");
    testScreen.visitorId = "userToMap";
    testScreen.id = "id2";

    // Create Transation
    Transaction testTransac = Transaction(
        transactionId: "transactionId", affiliation: "convertToMap");
    testTransac.visitorId = "userToMap";
    testTransac.id = "id3";

    // Create PAGEVIEW
    Page testPage = Page(location: "convertToMap");
    testPage.visitorId = "userToMap";
    testPage.id = "id4";

    // Create Item
    Item testItem =
        Item(transactionId: "transactionId", name: "name", code: "code");
    testItem.visitorId = "userToMap";
    testItem.id = "id5";

    // Covert to map
    var mapResult = FlagshipTools.hitsToMap(
        [testEvent, testScreen, testTransac, testPage, testItem]);

    expect(mapResult.length, 5);
    expect(mapResult.keys.contains("id1"), true);

    var ob1 = mapResult["id1"];
    var ob2 = mapResult["id2"];
    expect(ob1?["t"], "EVENT");
    expect(ob2?["dl"], "locationToMap");
  });

  test("converMapToListOfHits", () {
    String itemJson =
        '{ "cid": "bkk9glocmjcg0vtmdlng","createdAt": "2023-07-03 11:26:43.962185","ds": "APP", "ic": "code", "in": "flutter_name","qt": 0,"t": "ITEM","tid": "12121212","vid": "flutterUser"}';

    String transacJson =
        '{"cid": "bkk9glocmjcg0vtmdlng","createdAt": "2023-07-03 11:26:43.961209","ds": "APP","icn": 5,"pm": "CB","qt": 0,"sm": "colissimo","t": "TRANSACTION","ta": "transac_v3","tc": "coupon","tcc": "coupon","tid": "transac_v3","tr": 100.0,"ts": 10.0,"tt": 100.0,"vid": "flutterUser"}';

    String eventJson =
        '{"cid": "bkk9glocmjcg0vtmdlng","createdAt": "2023-07-03 11:26:06.527702","ds": "APP","ea": "event_0603","ec": "Action Tracking","el": "flutter_label","ev": 10,"qt": 0,"sn": 12,"t": "EVENT","vid": "flutterUser"}';

    String screenJson =
        '{"cid": "bkk9glocmjcg0vtmdlng","createdAt": "2023-07-03 11:24:05.312372","dl": "flutter_screen","ds": "APP","qt": 0,"t": "SCREENVIEW","vid": "flutterUser"}';

    String pageJson =
        '{"cid": "bkk9glocmjcg0vtmdlng", "createdAt": "2023-07-03 11:24:05.312950","dl": "https://github.com/","ds": "APP","qt": 0,"t": "PAGEVIEW","vid": "flutterUser"}';

    List<Map> list = [
      {"data_hit": itemJson, 'id': "idTest1"},
      {"data_hit": transacJson, 'id': "idTest2"},
      {"data_hit": eventJson, 'id': "idTest3"},
      {"data_hit": screenJson, 'id': "idTest4"},
      {"data_hit": pageJson, 'id': "idTest5"},
    ];
    var listBase = FlagshipTools.converMapToListOfHits(list);
    // List should have 5 items
    expect(listBase.length, 5);
  });
}
