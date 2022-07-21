import 'dart:async';

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
    if (timer.isActive) {
      timer.cancel();
    }
  }
}
