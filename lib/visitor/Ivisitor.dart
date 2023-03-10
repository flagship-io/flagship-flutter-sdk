import 'package:flagship/hits/hit.dart';
import 'package:flagship/model/modification.dart';

abstract class IVisitor {
// Update Context
  void updateContext<T>(String key, T value);
// Get Modification
  T getModification<T>(String key, T defaultValue, {bool activate = false});
// Get Modificatoin info
  Map<String, dynamic>? getModificationInfo(String key);
// Synchronize modifications
  Future<void> synchronizeModifications();
// Activate modification
  Future<void> activateModification(String key);
// Activate flag
  Future<void> activateFlag(Modification pModification);
// Send Hits
  Future<void> sendHit(BaseHit hit);
// send Consent
  void setConsent(bool isConsent);

// Get Modification object, use for Flag class
  Modification? getFlagModification(String key);
// authenticateVisitor
  authenticateVisitor(String visitorId);

// unAuthenticateVisitor
  unAuthenticateVisitor();

  // void cache visitor
  void cacheVisitor(String visitorId, String jsonString);

  // Called right at visitor creation, return a jsonString corresponding to visitor. Return a jsonString
  void lookupVisitor(String visitoId);

// Lookup Hits
  void lookupHits();

  // onExposure
  void onExposure(Modification pModification);
}
