import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';

abstract class IVisitor {
  void updateContext<T>(String key, T value);

  T getModification<T>(String key, T defaultValue, {bool activate = false});

  Map<String, Object>? getModificationInfo(String key);

  Future<Status> synchronizeModifications();

  Future<void> activateModification(String key);

  Future<void> sendHit(BaseHit hit);
}
