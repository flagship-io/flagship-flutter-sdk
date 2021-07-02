import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class FSInputField extends StatelessWidget {
  final String label;

  TextEditingController inputController;

  final TextInputType keyboardType;

  FSInputField(this.label, this.inputController, this.keyboardType);
  @override
  Widget build(BuildContext context) {
    var appleWidget = CupertinoTextField(
      controller: inputController,
      placeholder: label,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 12, color: Colors.black87),
      onChanged: (newText) {},
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
