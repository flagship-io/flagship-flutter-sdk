import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/fs_event.dart';

import '../FSinputField.dart';

class Event extends StatefulWidget {
  @override
  _EventState createState() => _EventState();
}

class _EventState extends State<Event> {
  late TextEditingController _eventActionController;
  late TextEditingController _eventValueController;

  @override
  void initState() {
    super.initState();
    _eventActionController = TextEditingController(text: 'flutter_event');
    _eventValueController = TextEditingController(text: '10');
  }

  double _verticalSpace = 20;

  bool _isActionTracking = true;

  _onSendEventHit() async {
    print("On send event hits");
    var currentVisitor = Flagship.getCurrentVisitor();
    FSEvent event = FSEvent(
        action: _eventActionController.text,
        category: _isActionTracking
            ? FSCategoryEvent.Action_Tracking
            : FSCategoryEvent.User_Engagement);
    event.label = "flutter_label";
    event.sessionNumber = 12;
    event.value = int.tryParse(_eventValueController.text) ?? 0;

    var text = "Event sent";
    var subText = "Event has been sent";
    try {
      await currentVisitor?.sendHit(event);
    } catch (e) {
      text = "Event send error";
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

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hit Event",
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: _verticalSpace),
          FSInputField(
              "Event action", _eventActionController, TextInputType.text),
          FSInputField(
              "Event value", _eventValueController, TextInputType.text),
          SizedBox(height: _verticalSpace),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Container(
                  alignment: Alignment.centerLeft,
                  child: Switch.adaptive(
                      value: _isActionTracking,
                      onChanged: (val) {
                        setState(() {
                          _isActionTracking = val;
                        });
                      }),
                ),
              ),
              Expanded(
                  child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white),
                  color: Colors.green,
                ),
                padding: EdgeInsets.all(8),
                alignment: Alignment.center,
                // color: Colors.orange,

                child: Text(
                  _isActionTracking ? "Action Tracking" : "User Engagemnt",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ))
            ],
          ),
          SizedBox(height: _verticalSpace),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              child: Text("Event"),
              onPressed: () {
                _onSendEventHit();
              },
            ),
          ),
        ],
      ),
    );
  }
}
