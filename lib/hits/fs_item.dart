import 'fs_hit.dart';

class FSItem extends Hit {
  /// Transaction unique identifier
  String transactionId;

  /// Product name
  String name;

  /// Specifies the item code or SKU
  String code;

  /// Specifies the item price
  double? price;

  /// Specifies the item quantity
  int? quantity;

  /// Specifies the item category
  String? category;

  FSItem({required this.transactionId, required this.name, required this.code})
      : super() {
    type = Type.ITEM;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll(
        {"t": typeOfEvent, "tid": transactionId, "in": name, "ic": code});

    // Add price
    if (price != null) customBody['ip'] = price ?? 0;
    // Add quantity
    if (quantity != null) customBody['iq'] = quantity ?? 0;
    // Add category
    if (category != null) customBody['iv'] = category ?? 0;

    // Add commun body
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }
}
