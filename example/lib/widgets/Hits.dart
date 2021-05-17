import 'package:flutter/material.dart';
import './subWidget/event.dart';
import './subWidget/screen.dart';
import './subWidget/transaction.dart';
import './subWidget/item.dart';

class Hits extends StatefulWidget {
  Hits();
  @override
  _HitsState createState() => _HitsState();
}

class _HitsState extends State<Hits> {
  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    double _spaceBetweenElements = 10;

    return Container(
      height: mediaQuery.size.height,
      width: mediaQuery.size.width,
      color: Color.fromRGBO(39, 39, 39, 1),
      padding: EdgeInsets.only(
          left: 20,
          top: mediaQuery.viewPadding.top + _spaceBetweenElements,
          right: 20,
          bottom: 0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "HITS",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: _spaceBetweenElements),
            ScreenHit(),
            SizedBox(height: _spaceBetweenElements * 2),
            EventHit(),
            SizedBox(height: _spaceBetweenElements * 2),
            TransactionHit(),
            SizedBox(height: _spaceBetweenElements * 2),
            ItemHit(),
          ],
        ),
      ),
    );
  }
}
