import './log_manager.dart';

abstract class FlagshipFilter {
  FlagshipFilter();
  Level? level;

  bool allowDisplay(Level pLevel);
}

class FlagshipFilterDebug extends FlagshipFilter {
  @override
  bool allowDisplay(Level pLevel) {
    return (pLevel.index <= level!.index);
  }
}
