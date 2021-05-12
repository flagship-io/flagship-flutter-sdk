import 'package:flagship/flagship.dart';
import 'dart:convert';

class FSTools {
  /// Get my context in pretty format
  static JsonEncoder encoder = new JsonEncoder.withIndent("   ");

  static String getMyPrettyContext() {
    try {
      var ctx = Flagship.getCurrentVisitor()?.getCurrentContext() ?? {};
      return encoder.convert(ctx);
    } catch (e) {
      return e.toString();
    }
  }
}
