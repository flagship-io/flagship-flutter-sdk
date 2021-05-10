import 'package:flutter/material.dart';
import '../FSinputField.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/hits/fs_item.dart';

class Item extends StatefulWidget {
  @override
  _ItemState createState() => _ItemState();
}

class _ItemState extends State<Item> {
  List<Map<String, Object>> listInputs;

  TextEditingController _textControllerTransactionId;
  TextEditingController _textControllerName;
  TextEditingController _textControllerCode;
  TextEditingController _textControllerPrice;
  TextEditingController _textControllerQuantity;
  TextEditingController _textControllerCategory;

  @override
  void initState() {
    super.initState();
    _textControllerTransactionId =
        TextEditingController(text: 'flutter_TransactionId');
    _textControllerName = TextEditingController(text: 'name');
    _textControllerCode = TextEditingController(text: 'code');
    _textControllerPrice = TextEditingController(text: '9.5');
    _textControllerQuantity = TextEditingController(text: '5');
    _textControllerCategory = TextEditingController(text: 'category');

    listInputs = [
      {
        "label": "Transaction ID",
        "type": TextInputType.text,
        'ctrl': _textControllerTransactionId
      },
      {
        "label": "Name",
        "type": TextInputType.text,
        'ctrl': _textControllerName
      },
      {
        "label": "Code",
        "type": TextInputType.text,
        'ctrl': _textControllerCode
      },
      {
        "label": "Price",
        "type": TextInputType.number,
        'ctrl': _textControllerPrice
      },
      {
        "label": "Quantity",
        "type": TextInputType.number,
        'ctrl': _textControllerQuantity
      },
      {
        "label": "Category",
        "type": TextInputType.text,
        'ctrl': _textControllerCategory
      },
    ];
  }

  _onSendTransaction() async {
    var itemEvent = FSItem(
        transactionId: _textControllerTransactionId.text,
        name: _textControllerName.text,
        code: _textControllerCode.text);

    itemEvent.price = double.tryParse(_textControllerPrice.text) ?? 0;
    itemEvent.quantity = int.tryParse(_textControllerQuantity.text) ?? 1;
    itemEvent.category = _textControllerCategory.text;

    print(itemEvent);

    var text = "Item sent";
    var subText = "Item has been sent";
    try {
      await Flagship.getCurrentVisitor().sendHit(itemEvent);
    } catch (e) {
      text = "Item sent error";
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
          "Item",
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
            child: Text("Item"),
            onPressed: _onSendTransaction,
          ),
        ),
      ],
    );
  }
}
