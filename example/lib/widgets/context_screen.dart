import 'dart:convert';
import 'package:flagship/visitor.dart';
import 'package:flutter/material.dart';
import 'package:flagship/flagship.dart';
import '../tools/fs_tools.dart';

class ContextScreen extends StatefulWidget {
  static const routeName = './ContextScreen';

  @override
  _ContextScreenState createState() => _ContextScreenState();
}

class _ContextScreenState extends State<ContextScreen> {
  Visitor currentClient = Flagship.getCurrentVisitor();
  TextEditingController ctxInput = TextEditingController();

  @override
  void dispose() {
    ctxInput.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ctxInput.text = FSTools.getMyPrettyContext();

    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text("Update context"),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
                color: Colors.black,
                width: double.infinity,
                height: (mediaQuery.size.height - mediaQuery.padding.top) * 0.5,
                child: EditableText(
                  maxLines: null,
                  controller: ctxInput,
                  focusNode: FocusNode(),
                  style: TextStyle(color: Colors.white),
                  cursorColor: Colors.red,
                  backgroundCursorColor: Colors.red,
                  onChanged: (newVal) {},
                )),
            SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  child: Text("Validate"),
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
      Map<String, Object> ret = jsonDecode(ctxInput.text);
      currentClient.updateContextWithMap(ret);
      subMsg = "Context updated";

      /// Synchronize
      currentClient.synchronizeModifications().then((state) {
        if (state == FSStatus.Ready) {
          subMsg = "Context updated and synchronized";
        } else {
          subMsg = "Context updated but the synchronized failed";
        }
        _showDialog("Context validation", subMsg);
      });
    } catch (error) {
      subMsg = "Validation failed : $error";
      print(error);
      _showDialog("Context validation", subMsg);
    }
  }

  /// Show dialog
  _showDialog(String titleMsg, String subTitle) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text(titleMsg),
            content: new Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(subTitle),
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
}
