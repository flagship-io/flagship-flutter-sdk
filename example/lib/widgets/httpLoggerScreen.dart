import 'package:flutter/material.dart';

class HttpLoggerScreen extends StatefulWidget {
  @override
  _HttpLoggerScreenState createState() => _HttpLoggerScreenState();
}

class _HttpLoggerScreenState extends State<HttpLoggerScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Container(
      height: mediaQuery.size.height,
      width: mediaQuery.size.width,
      color: Color.fromRGBO(39, 39, 39, 1),
    );
  }
}
