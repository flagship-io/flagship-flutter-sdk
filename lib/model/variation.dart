import 'modification.dart';

class Variation {
  String idVariation;
  Modifications modifications;
  int allocation;
  bool reference;
  String name = "";

  Variation(
      this.idVariation, this.modifications, this.reference, this.allocation);

  Variation.fromJson(Map<String, dynamic> json)
      : idVariation = (json['id'] ?? "") as String,
        allocation = (json['allocation'] ?? 0) as int,
        reference = (json['reference'] ?? false) as bool,
        name = (json['name'] ?? false) as String,
        modifications = Modifications.fromJson(
            json['modifications'] as Map<String, dynamic>);
}
