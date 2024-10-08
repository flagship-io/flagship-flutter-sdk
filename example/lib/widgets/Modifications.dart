import 'dart:convert';

import 'package:flagship/model/flag.dart';
import 'package:flagship/status.dart';
import 'package:flagship_qa/widgets/FSinputField.dart';
import 'package:flagship_qa/widgets/modifications_json_screen.dart';
import 'package:flutter/material.dart';
import './FSoutputField.dart';
import 'package:flagship/flagship.dart';

class Modifications extends StatefulWidget {
  Modifications();

  @override
  _ModificationsState createState() => _ModificationsState();
}

class _ModificationsState extends State<Modifications> {
  var flagType = "string";
  var defaultValueBool = false;
  final keyFlagController = TextEditingController(text: "btnColor");

  final defaultValueFlagController = TextEditingController(text: "");

  String variationId = "None";
  String variationName = "None";

  String variationGroupId = "None";
  String variationGroupName = "None";

  String campaignId = "None";
  String campaignName = "None";

  bool isReference = false;

  String valueForFlag = "None";
  String slug = "None";
  String campaignType = "None";
  FlagStatus status = FlagStatus.NOT_FOUND;
  FetchFlagsRequiredStatusReason reason = FetchFlagsRequiredStatusReason.NONE;

  double _spaceBetweenElements = 10;

  Flag? myFlag;

  _getModification() {
    var currentVisitor = Flagship.getCurrentVisitor();

    dynamic defaultValue = defaultValueFlagController.text;

    if (flagType == "boolean") {
      defaultValue = defaultValueBool.toString();
    }
    if (flagType == "number") {
      defaultValue = double.parse(defaultValueFlagController.text);
    }
    if (flagType == "array" || flagType == "object") {
      defaultValue = jsonDecode(defaultValueFlagController.text);
    }

    myFlag = currentVisitor?.getFlag(keyFlagController.text);

    var ret = myFlag?.value(defaultValue);

    setState(() {
      valueForFlag = ret.toString();
      status = myFlag?.getFlagStatus() ?? FlagStatus.NOT_FOUND;
      reason =
          currentVisitor?.fetchReasons ?? FetchFlagsRequiredStatusReason.NONE;
    });

    var mapResult = myFlag?.metadata().toJson();
    // var mapResult = currentVisitor?.getModificationInfo(keyFlagController.text);
    _resetField();
    if (mapResult != null) {
      setState(() {
        variationId = (mapResult['variationId'] ?? "None") as String;
        variationGroupId = (mapResult['variationGroupId'] ?? "None") as String;
        campaignId = (mapResult['campaignId'] ?? "None") as String;
        isReference = (mapResult['isReference'] ?? false) as bool;
        slug = (mapResult['slug'] ?? "None") as String;
        campaignType = (mapResult['campaignType'] ?? "None") as String;

        variationName = (mapResult['variationName'] ?? "None") as String;
        campaignName = (mapResult['campaignName'] ?? "None") as String;
        variationGroupName =
            (mapResult['variationGroupName'] ?? "None") as String;
      });
    } else {
      setState(() {
        variationId = "None";
        variationGroupId = "None";
        campaignId = "None";
        isReference = false;
      });
    }
  }

  // Activate
  _activate() async {
    // var currentVisitor = Flagship.getCurrentVisitor();
    await myFlag?.visitorExposed();
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text("Activation sent"),
            content: new Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text("Activation has been sent if modification key exists"),
              ],
            ),
            actions: <Widget>[
              new TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        });
  }

  // Get json view
  _getJsonView(BuildContext ctx) {
    Navigator.of(ctx)
        .pushNamed(ModificationsJSONScreen.routeName, arguments: {});
  }

  // _getCollection() {
  //   Visitor? v1 = Flagship.getCurrentVisitor();

  //   if (v1 != null) {
  //     FSFlagCollection flagCollection = v1.getFlags();

  //     var flag = flagCollection['btnColor'];

  //     flag.value(12121);

  //     flag.visitorExposed();
  //   }
  // }

  void _resetField() {
    variationId = "None";
    variationGroupId = "None";
    campaignId = "None";
    isReference = false;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Container(
      color: Color.fromRGBO(39, 39, 39, 1),
      height: mediaQuery.size.height,
      width: mediaQuery.size.width,
      padding: EdgeInsets.only(
          left: 20,
          top: mediaQuery.viewPadding.top + _spaceBetweenElements,
          right: 20,
          bottom: 0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Modifications",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                )),
            SizedBox(height: _spaceBetweenElements),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: FSInputField("Key", keyFlagController, TextInputType.text),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Row(
                  //mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        "Type",
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.left,
                      ),
                    ),
                    Expanded(
                      child: DropdownButton<String>(
                        value: flagType,
                        onChanged: (String? newValue) {
                          defaultValueFlagController.text =
                              newValue == 'number' ? '0' : 'defaultValue';
                          setState(() {
                            flagType = newValue ?? "";
                          });
                        },
                        dropdownColor: Colors.black,
                        style: const TextStyle(color: Colors.white),
                        items: <String>[
                          'boolean',
                          'number',
                          'string',
                          'array',
                          'object'
                        ].map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    )
                  ]),
            ),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: flagType == "boolean"
                  ? Row(
                      //mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                          Expanded(
                            child: Text(
                              "Default value",
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.left,
                            ),
                          ),
                          Switch(
                              value: defaultValueBool,
                              onChanged: (bool newValue) {
                                setState(() {
                                  defaultValueBool = newValue;
                                });
                              })
                        ])
                  : FSInputField(
                      "Default value",
                      defaultValueFlagController,
                      flagType == "number"
                          ? TextInputType.number
                          : TextInputType.text),
            ),
            SizedBox(height: _spaceBetweenElements),
            FSOutputField("Value", valueForFlag),
            SizedBox(height: _spaceBetweenElements),
            // Variation
            FSOutputField("VariationId", variationId),
            FSOutputField("VariationName", variationName),
            SizedBox(height: _spaceBetweenElements),
            // Campaign
            FSOutputField("CampaignId", campaignId),
            FSOutputField("CampaignName", campaignName),
            SizedBox(height: _spaceBetweenElements),
            // Variation Group
            FSOutputField("VariationGroupId", variationGroupId),
            FSOutputField("VariationGroupName", variationGroupName),
            SizedBox(height: _spaceBetweenElements),
            FSOutputField("IsReference", isReference.toString()),
            SizedBox(height: _spaceBetweenElements),
            FSOutputField("Slug", slug),
            SizedBox(height: _spaceBetweenElements),
            FSOutputField("campaignType", campaignType),
            SizedBox(height: _spaceBetweenElements),
            FSOutputField("Status for Flag", status.name),
            SizedBox(height: _spaceBetweenElements),
            FSOutputField("Fetch Reason", reason.name),
            SizedBox(height: _spaceBetweenElements),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text("GET"),
                onPressed: () {
                  _getModification();
                },
              ),
            ),
            SizedBox(height: _spaceBetweenElements),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text("ACTIVATE"),
                onPressed: () {
                  _activate();
                },
              ),
            ),
            SizedBox(height: _spaceBetweenElements),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: Text("JSON VIEW"),
                onPressed: () {
                  _getJsonView(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
