import 'package:flagship/flagship.dart';
import 'package:flagship/hits/hit.dart';

abstract class IVisitor {
// Update Context
  void updateContext<T>(String key, T value);
// Get Modification
  T getModification<T>(String key, T defaultValue, {bool activate = false});
// Get Modificatoin info
  Map<String, Object>? getModificationInfo(String key);
// Synchronize modifications
  Future<Status> synchronizeModifications();
// Activate modification
  Future<void> activateModification(String key);
// Send Hits
  Future<void> sendHit(BaseHit hit);
// send Consent
  void setConsent(bool isConsent);
}
