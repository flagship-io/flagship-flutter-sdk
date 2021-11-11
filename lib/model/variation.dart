import 'modification.dart';

class Variation {
  String idVariation;
  Modifications modifications;
  int allocation;
  bool reference;

  Variation.fromJson(Map<String, dynamic> json)
      : idVariation = (json['id'] ?? "") as String,
        allocation = (json['allocation'] ?? 0) as int,
        reference = (json['reference'] ?? false) as bool,
        modifications = Modifications.fromJson(
            json['modifications'] as Map<String, dynamic>);
}
