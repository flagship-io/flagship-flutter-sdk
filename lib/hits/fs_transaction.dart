import 'package:flagship/hits/fs_hit.dart';

class FSTransaction extends Hit {
  /// Transaction unique identifier.
  String transactionId;

  /// Transaction name. Name of the goal in the reporting.
  String affiliation;

  /// Total revenue associated with the transaction. This value should include any shipping or tax costs
  double? revenue;

  /// Specifies the total shipping cost of the transaction.
  double? shipping;

  /// Specifies the total taxes of the transaction.
  double? ctax;

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

  FSTransaction(
      {required this.transactionId,
      required this.affiliation,
      this.revenue,
      this.couponCode,
      this.ctax,
      this.currency,
      this.itemCount,
      this.paymentMethod,
      this.shipping,
      this.shippingMethod})
      : super() {
    type = Type.TRANSACTION;
  }

  @override
  Map<String, Object> get bodyTrack {
    var customBody = new Map<String, Object>();
    customBody
        .addAll({"t": typeOfEvent, 'tid': transactionId, 'ta': affiliation});

    // Add revenue
    if (revenue != null) customBody['tr'] = revenue ?? 0;
    // Add shipping
    if (shipping != null) customBody['ts'] = shipping ?? 0;
    // Add Tax
    if (ctax != null) customBody['tt'] = ctax ?? 0;
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
