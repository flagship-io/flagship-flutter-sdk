import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// ignore: must_be_immutable
class FSInputField extends StatelessWidget {
  final String label;

  TextEditingController inputController;

  Function? onChangeInput;

  final TextInputType keyboardType;

  FSInputField(this.label, this.inputController, this.keyboardType,
      {this.onChangeInput});
  @override
  Widget build(BuildContext context) {
    var appleWidget = CupertinoTextField(
      controller: inputController,
      placeholder: label,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 12, color: Color.fromARGB(221, 13, 13, 13)),
      onChanged: (newText) {
        if (onChangeInput != null) {
          onChangeInput!(newText);
        }
      },
    );

    return Container(
      child: Row(
        //mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white),
              textAlign: TextAlign.left,
            ),
          ),
          Expanded(
            child: Platform.isIOS
                ? appleWidget
                : TextField(
                    autocorrect: false,
                    enableSuggestions: false,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        labelText: label,
                        labelStyle: TextStyle(color: Colors.grey)),
                    controller: inputController,
                    keyboardType: keyboardType,
                    onSubmitted: (_) => {},
                  ),
          )
        ],
      ),
    );
  }
}
