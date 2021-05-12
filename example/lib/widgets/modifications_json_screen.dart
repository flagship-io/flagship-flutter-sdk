import 'package:flagship_qa/tools/fs_tools.dart';
import 'package:flutter/material.dart';
import 'package:flagship/flagship.dart';

class ModificationsJSONScreen extends StatefulWidget {
  static const routeName = './ModificationsJSONScreen';

  @override
  _ModificationsJSONScreenState createState() =>
      _ModificationsJSONScreenState();
}

class _ModificationsJSONScreenState extends State<ModificationsJSONScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Modification JSON view"),
        ),
        body: SingleChildScrollView(
            child: Column(children: [
          Center(
            child: Column(
              children: [
                SizedBox(
                  height: 20,
                ),
                Text(FSTools.encoder
                    .convert(Flagship.getCurrentVisitor()?.modifications)),
              ],
            ),
          )
        ])));
  }
}
