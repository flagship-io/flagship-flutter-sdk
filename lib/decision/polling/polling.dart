import 'dart:async';

import 'package:flutter/animation.dart';

class Polling {
  final int intervalTimePolling;

  Future<void> Function() getScript;

  late Timer timer;

  Polling(this.intervalTimePolling, this.getScript) {
    start();
  }

  start() {
    getScript().whenComplete(() {
      timer = Timer.periodic(Duration(seconds: intervalTimePolling), (Timer t) async {
        await getScript();
      });
    });
  }

  stop() {
    print("stop polling");
    timer.cancel();
  }
}
