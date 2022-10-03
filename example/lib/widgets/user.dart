import 'package:flagship/flagship.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship_qa/widgets/FSinputField.dart';
import 'package:flagship_qa/widgets/FSoutputField.dart';
import 'package:flutter/material.dart';

class User extends StatefulWidget {
  late Visitor? currentVisitor;
  User(this.currentVisitor);

  @override
  _UserState createState() => _UserState();

  update(Visitor? newVisitor) {
    currentVisitor = newVisitor;
    print("Hello update visitor");
  }
}

class _UserState extends State<User> {
  final visitorIdController = TextEditingController();
  final anonymousIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double _spaceBetweenInput = 10;
    double _marginFromTop = 100;

    visitorIdController.text = "";
    final mediaQuery = MediaQuery.of(context);
    return Container(
      height: mediaQuery.size.height,
      width: mediaQuery.size.width,
      color: Color.fromRGBO(39, 39, 39, 1),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: mediaQuery.viewPadding.top + _spaceBetweenInput,
              ),
              Text(
                "Visitor",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
              ),
              SizedBox(height: _marginFromTop),
              FSOutputField("Visitor Id", widget.currentVisitor?.visitorId ?? ""),
              SizedBox(height: _spaceBetweenInput),
              FSOutputField("Anonymous Id", widget.currentVisitor?.anonymousId ?? ""),
              SizedBox(height: _spaceBetweenInput + 2 * _marginFromTop),
              FSInputField("New authenticated id", visitorIdController, TextInputType.text),
              SizedBox(height: _spaceBetweenInput + 2 * _marginFromTop / 6),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("AUTHENTICATE"),
                    onPressed: () => {_authenticate()},
                  )),
              SizedBox(height: _spaceBetweenInput),
              Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("UN AUTHENTICATE"),
                    onPressed: () => {_unAuthenticate()},
                  )),
              SizedBox(height: _spaceBetweenInput),
              Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("FETCH FLAGS"),
                    onPressed: () => {_fetchFlags()},
                  )),
            ],
          ),
        ),
      ),
    );
  }

  _authenticate() {
    if (visitorIdController.text.length >= 3) {
      widget.currentVisitor?.authenticate(visitorIdController.text);
      setState(() {
        visitorIdController.text = widget.currentVisitor?.visitorId ?? "";
        anonymousIdController.text = widget.currentVisitor?.anonymousId ?? "";
      });
    } else {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return new AlertDialog(
              title: new Text("Authenticate id must contain at least 3 characters"),
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

  _unAuthenticate() {
    widget.currentVisitor?.unauthenticate();
    setState(() {
      visitorIdController.text = widget.currentVisitor?.visitorId ?? "";
      anonymousIdController.text = widget.currentVisitor?.anonymousId ?? "";
    });
  }

  _fetchFlags() {
    widget.currentVisitor?.fetchFlags().whenComplete(() {});
  }
}
