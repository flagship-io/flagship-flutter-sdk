import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/modification.dart';

abstract class IVisitor {
// Update Context
  void updateContext<T>(String key, T value);
// Get Modification
  T getModification<T>(String key, T defaultValue, {bool activate = false});
// Get Modificatoin info
  Map<String, Object>? getModificationInfo(String key);
// Synchronize modifications
  Future<void> synchronizeModifications();
// Activate modification
  Future<void> activateModification(String key);
// Send Hits
  Future<void> sendHit(BaseHit hit);
// send Consent
  void setConsent(bool isConsent);

// Get Modification object, use for Flag class
  Modification? getFlagModification(String key);
}
