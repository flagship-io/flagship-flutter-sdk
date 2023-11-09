import 'modification.dart';

class Variation {
  String idVariation = "";
  Modifications? modifications;
  int allocation = 0;
  bool reference = false;
  String name = "";

  Variation(
      this.idVariation, this.modifications, this.reference, this.allocation);

  Variation.fromJson(Map<String, dynamic> json) {
    if (json.containsKey("id")) {
      idVariation = (json['id'] ?? "") as String;
    }

    if (json.containsKey("allocation")) {
      allocation = (json['allocation'] ?? 0) as int;
    }

    if (json.containsKey("reference")) {
      reference = (json['reference'] ?? false) as bool;
    }

    if (json.containsKey("name")) {
      name = (json['name'] ?? "") as String;
    }
    modifications = Modifications.fromJson(json['modifications'] ?? {});
  }
}
