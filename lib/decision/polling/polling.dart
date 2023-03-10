import 'dart:async';

import 'package:flagship/flagship.dart';
import 'package:flagship/utils/logger/log_manager.dart';

class Polling {
  final int intervalTimePolling;

  Function() getScript;
  late Timer timer;

  Polling(this.intervalTimePolling, this.getScript);

  start() {
    getScript().whenComplete(() {
      timer = Timer.periodic(Duration(seconds: intervalTimePolling),
          (Timer t) async {
        await getScript();
      });
    });
  }

  stop() {
    Flagship.logger(Level.DEBUG, "Stop polling");
    if (timer.isActive) {
      timer.cancel();
    }
  }
}
