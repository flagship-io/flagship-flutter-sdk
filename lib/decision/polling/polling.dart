import 'dart:async';

import 'package:flagship/model/campaign.dart';
import 'package:flutter/animation.dart';

import '../../model/campaigns.dart';

class Polling {
  final int intervalTimePolling;

  Function() getScript;

  late Timer timer;

  Polling(this.intervalTimePolling, this.getScript);

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
