import 'package:flutter/material.dart';

class FSOutputField extends StatelessWidget {
  final String label;
  final String outputValue;

  FSOutputField(this.label, this.outputValue);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 45,
      child: Row(
        // crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Container(
              alignment: Alignment.centerLeft,
              padding: EdgeInsets.all(10),
              child: Text(
                label,
                style: TextStyle(color: Colors.white, fontSize: 14),
                textAlign: TextAlign.left,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                color: Colors.green,
              ),
              alignment: Alignment.center,
              height: 40,
              child: Text(
                outputValue,
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
