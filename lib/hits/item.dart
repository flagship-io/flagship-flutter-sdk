import 'hit.dart';

class Item extends BaseHit {
  /// TransactionId allows an item to be linked to a transaction with a matching Transaction ID. The maximum permitted length is 500 Bytes.
  late String transactionId;

  /// Specifies the name of an item. The maximum permitted length is 500 Bytes.
  late String name;

  /// Specifies an item's SKU or product bar code. The maximum permitted length is 500 Bytes.
  late String code;

  /// Specifies the item price
  double? price;

  /// Indicates the number of units of an item that are purchased.
  int? quantity;

  /// Specifies the product category that an item belongs to. The maximum permitted length is 500 Bytes.
  String? category;

  Item(
      {required this.transactionId,
      required this.name,
      required this.code,
      this.price,
      this.category,
      this.quantity})
      : super() {
    type = HitCategory.ITEM;
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

  Item.fromMap(String oldId, Map body) : super.fromMap(oldId, body) {
    this.type = HitCategory.ITEM;
    this.transactionId = body['tid'] ?? "";
    this.name = body['in'] ?? "";
    this.code = body['ic'] ?? "";
    this.price = body['ip'];
    this.quantity = body['iq'];
    this.category = body['iv'];
  }
}
