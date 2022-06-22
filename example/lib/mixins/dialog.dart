import 'package:flutter/material.dart';

mixin ShowDialog<T extends StatefulWidget> on State<T> {
  showBasicDialog(String titleMsg, String? subTitle) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text(titleMsg),
            content: new Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: subTitle == null
                  ? <Widget>[]
                  : <Widget>[
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
