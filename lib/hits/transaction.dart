import 'package:flagship/hits/hit.dart';

class Transaction extends BaseHit {
  /// Transaction unique identifier.
  String transactionId;

  /// Transaction name. Name of the goal in the reporting.
  String affiliation;

  /// Total revenue associated with the transaction. This value should include any shipping or tax costs
  double? revenue;

  /// Specifies the total shipping cost of the transaction.
  double? shipping;

  /// Specifies the total taxes of the transaction.
  double? tax;

  /// Specifies the currency used for all transaction currency values. Value should be a valid ISO 4217 currency code.
  String? currency;

  /// Specifies the coupon code used by the customer for the transaction.
  String? couponCode;

  /// Specifies the payment method for the transaction.
  String? paymentMethod;

  /// Specifies the shipping method of the transaction.
  String? shippingMethod;

  /// Specifies the number of items for the transaction.
  int? itemCount;

  Transaction(
      {required this.transactionId,
      required this.affiliation,
      this.revenue,
      this.couponCode,
      this.tax,
      this.currency,
      this.itemCount,
      this.paymentMethod,
      this.shipping,
      this.shippingMethod})
      : super() {
    type = HitCategory.TRANSACTION;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody.addAll({"t": typeOfEvent, 'tid': transactionId, 'ta': affiliation});

    // Add revenue
    if (revenue != null) customBody['tr'] = revenue ?? 0;
    // Add shipping
    if (shipping != null) customBody['ts'] = shipping ?? 0;
    // Add Tax
    if (tax != null) customBody['tt'] = tax ?? 0;
    // Add currency
    if (currency != null) customBody['tc'] = currency ?? "";
    // Add coupon code
    if (couponCode != null) customBody['tcc'] = couponCode ?? "";
    // Add paymentMethod
    if (paymentMethod != null) customBody['pm'] = paymentMethod ?? "";
    // Add shippingMethod
    if (shippingMethod != null) customBody['sm'] = shippingMethod ?? "";
    // Add item count
    if (itemCount != null) customBody['icn'] = itemCount ?? 0;

    // Add commun data
    customBody.addAll(super.communBodyTrack);
    return customBody;
  }
}
