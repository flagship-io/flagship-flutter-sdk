import './log_manager.dart';

abstract class FlagshipFilter {
  FlagshipFilter();

  bool allowDisplay(Level pLevel);
}

class FlagshipFilterDebug extends FlagshipFilter {
  @override
  bool allowDisplay(Level pLevel) {
    return (pLevel.index <= LogManager.level.index);
  }
}
