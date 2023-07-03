import 'dart:async';
import 'dart:io';

import 'package:flagship/decision/polling/polling.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/visitor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Generate a MockClient using the Mockito package.
// Create new instances of this class in each test.

void getScriptTest() async {}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});

  bool isCalled = false;
  void getScriptTest() async {
    isCalled = true;

    print("---- getScriptTest ---- ");
  }

  test("Polling Test Start", () async {
    Polling tp = Polling(1, () async {
      getScriptTest();
    });
    tp.start();

    sleep(Duration(seconds: 2));
    expect(isCalled, true);

    tp.getScript().whenComplete(() {
      tp.stop();
      expect(tp.timer.isActive, false);
    });
  });
}
