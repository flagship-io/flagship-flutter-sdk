import 'package:flutter/material.dart';
import '../FSinputField.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/fs_transaction.dart';
import 'package:flagship/hits/fs_item.dart';

class Transaction extends StatefulWidget {
  @override
  _TransactionState createState() => _TransactionState();
}

class _TransactionState extends State<Transaction> {
  List<Map<String, Object>> listInputs;

  TextEditingController _textControllerId;
  TextEditingController _textControllerAffiliation;
  TextEditingController _textControllerRevenue;
  TextEditingController _textControllerShipping;
  TextEditingController _textControllerTax;
  TextEditingController _textControllerCurrency;
  TextEditingController _textControllerCoupon;
  TextEditingController _textControllerPaymentMethod;
  TextEditingController _textControllerShippingMethod;
  TextEditingController _textControllerItemCount;

  @override
  void initState() {
    super.initState();
    _textControllerId = TextEditingController(text: 'flutter_TransactioId');
    _textControllerAffiliation =
        TextEditingController(text: 'flutter_transaction');
    _textControllerCoupon = TextEditingController(text: 'coupon');
    _textControllerCurrency = TextEditingController(text: 'EUR');
    _textControllerItemCount = TextEditingController(text: '5');
    _textControllerPaymentMethod = TextEditingController(text: 'CB');
    _textControllerRevenue = TextEditingController(text: '100');
    _textControllerShipping = TextEditingController(text: '10');
    _textControllerShippingMethod = TextEditingController(text: 'colissimo');
    _textControllerTax = TextEditingController(text: '5');

    listInputs = [
      {"label": "id", "type": TextInputType.text, 'ctrl': _textControllerId},
      {
        "label": "Affiliation",
        "type": TextInputType.text,
        'ctrl': _textControllerAffiliation
      },
      {
        "label": "Revenue",
        "type": TextInputType.number,
        'ctrl': _textControllerRevenue
      },
      {
        "label": "Shipping",
        "type": TextInputType.number,
        'ctrl': _textControllerShipping
      },
      {
        "label": "Tax",
        "type": TextInputType.number,
        'ctrl': _textControllerTax
      },
      {
        "label": "Currency",
        "type": TextInputType.text,
        'ctrl': _textControllerCurrency
      },
      {
        "label": "Coupon",
        "type": TextInputType.text,
        'ctrl': _textControllerCoupon
      },
      {
        "label": "Payment Method",
        "type": TextInputType.text,
        'ctrl': _textControllerPaymentMethod
      },
      {
        "label": "Shipping Method",
        "type": TextInputType.text,
        'ctrl': _textControllerShippingMethod
      },
      {
        "label": "Item Count",
        "type": TextInputType.number,
        'ctrl': _textControllerItemCount
      },
    ];
  }

  _onSendTransaction() async {
    var transacEvent = FSTransaction(
        transactionId: _textControllerId.text,
        affiliation: _textControllerAffiliation.text);

    transacEvent.revenue = double.tryParse(_textControllerRevenue.text) ?? 0;
    transacEvent.couponCode = _textControllerCoupon.text;
    transacEvent.currency = _textControllerCoupon.text;
    transacEvent.shipping = double.tryParse(_textControllerShipping.text) ?? 0;
    transacEvent.ctax = double.tryParse(_textControllerRevenue.text) ?? 0;
    transacEvent.paymentMethod = _textControllerPaymentMethod.text;
    transacEvent.shippingMethod = _textControllerShippingMethod.text;
    transacEvent.itemCount = int.tryParse(_textControllerItemCount.text) ?? 0;

    print(transacEvent);

    var text = "Transaction sent";
    var subText = "Transaction has been sent";
    try {
      await Flagship.getCurrentVisitor().sendHit(transacEvent);

      /// send item  // a revoir
      var itemEvent =
          FSItem(transactionId: "12121212", name: "flutter_name", code: 'code');
      await Flagship.getCurrentVisitor().sendHit(itemEvent);
    } catch (e) {
      text = "Transaction send error";
      subText = e.toString();
    }
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return new AlertDialog(
            title: new Text(text),
            content: new Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(subText),
              ],
            ),
            actions: <Widget>[
              new TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          );
        });
  }

  final double _verticalSpace = 20;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Text(
          "Transaction",
          style: TextStyle(color: Colors.white),
        ),
        SizedBox(height: _verticalSpace),
        Column(
          children: listInputs.map((e) {
            return Container(
                padding: EdgeInsets.all(10),
                child: FSInputField(e["label"], e['ctrl'], e['type']));
          }).toList(),
        ),
        SizedBox(height: _verticalSpace),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            child: Text("Transaction"),
            onPressed: _onSendTransaction,
          ),
        ),
      ],
    );
  }
}
