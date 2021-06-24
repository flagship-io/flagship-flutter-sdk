import 'package:flagship/utils/logger/log_manager.dart';

// class FlagshipLogManager extends LogManager {
//   // internal Singelton
//   static final FlagshipLogManager _singleton = FlagshipLogManager._internal();

//   factory FlagshipLogManager.sharedInstance() {
//     return _singleton;
//   }

//   FlagshipLogManager._internal() {
//     /// implement later
//     print("internal logger init");
//   }

//   static void log(String msg, Level level) {
//     print("Print from FlagshipLogManager");
//   }

//   @override
//   void onLog(Level level, String tag, String message) {
//     print("onLog from FlagshipLogManager ");
//   }

//   @override
//   void onException(Exception e) {
//     print(e);
//   }
// }
