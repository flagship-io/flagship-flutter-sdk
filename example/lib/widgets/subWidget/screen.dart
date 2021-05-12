import 'package:flagship_qa/widgets/FSinputField.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flagship/hits/fs_screen.dart';
import 'package:flagship/flagship.dart';

class Screen extends StatefulWidget {
  @override
  _ScreenState createState() => _ScreenState();
}

class _ScreenState extends State<Screen> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: 'flutter_screen');
  }

  _onSendScreenHit() async {
    FSScreen screenEvent = FSScreen(location: _textController.text);
    var text = "Screen hit sent";
    var subText = "Screen hit has been sent";
    try {
      await Flagship.getCurrentVisitor()?.sendHit(screenEvent);
    } catch (e) {
      text = "Screen send error";
      subText = e.toString();
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text(text),
            content: new Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(subText),
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

  final double _vertcialSpace = 20;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: _vertcialSpace),
        Text(
          "Hit Screen",
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: _vertcialSpace),
        FSInputField("Screen name", _textController, TextInputType.text),
        SizedBox(height: _vertcialSpace),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            child: Text("Screen"),
            onPressed: () {
              _onSendScreenHit();
            },
          ),
        ),
      ],
    );
  }
}
