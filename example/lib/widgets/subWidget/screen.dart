import 'package:flagship_qa/widgets/FSinputField.dart';
import 'package:flutter/material.dart';
import 'package:flagship/hits/screen.dart';
import 'package:flagship/flagship.dart';

class ScreenHit extends StatefulWidget {
  @override
  _ScreenState createState() => _ScreenState();
}

class _ScreenState extends State<ScreenHit> {
  late TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: 'flutter_screen');
  }

  _onSendScreenHit() async {
    var currentVisitor = Flagship.getCurrentVisitor();
    try {
      Screen screenEvent = Screen(location: _textController.text);
      await currentVisitor?.sendHit(screenEvent);
    } catch (e) {
      print(e.toString());
    }
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
