import 'package:flagship/flagship.dart';
import 'package:flagship/status.dart';

mixin FlagshipDelegate {
  // Delegate on update state for the skd after synchronize
  void onUpdateState(FSSdkStatus state);
}
