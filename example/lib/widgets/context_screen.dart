import 'dart:convert';
import 'package:flagship/visitor.dart';
import 'package:flagship_qa/mixins/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flagship/flagship.dart';
import '../tools/fs_tools.dart';

class ContextScreen extends StatefulWidget {
  static const routeName = './ContextScreen';

  @override
  _ContextScreenState createState() => _ContextScreenState();
}

class _ContextScreenState extends State<ContextScreen> with ShowDialog {
  TextEditingController ctxInput = TextEditingController();

  @override
  void dispose() {
    ctxInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ctxInput.text = FSTools.getMyPrettyContext();

    return Scaffold(
      appBar: AppBar(
        title: Text("Update context"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
                color: Colors.black,
                child: TextField(
                  style: TextStyle(
                      color: Colors.white, backgroundColor: Colors.black),
                  controller: ctxInput,
                  decoration: null,
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  smartQuotesType: SmartQuotesType.enabled,
                )),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text("Validate & Synchronize"),
                  onPressed: _onValidate,
                )),
          ],
        ),
      ),
    );
  }

  _onValidate() {
    String subMsg;
    try {
      Visitor? currentClient = Flagship.getCurrentVisitor();
      if (currentClient == null) {
        throw new Exception("Visitor not initialized");
      }
      Map<String, dynamic> ret = jsonDecode(ctxInput.text);
      //currentClient.clearContext();
      currentClient.updateContextWithMap(Map<String, Object>.from(ret));
      subMsg = "Context updated";

      /// Synchronize
      //ignore: deprecated_member_use
      //currentClient.fetchFlags().then((_) {
      subMsg = "Context updated and synchronized"; //(state == Status.READY)?

      // : "Context updated but the synchronized failed";
      showBasicDialog("Context validation", subMsg);
      //});
      showBasicDialog("Context validation", subMsg);
    } catch (error) {
      subMsg = "Validation failed : $error";
      showBasicDialog("Context validation", subMsg);
    }
  }
}
