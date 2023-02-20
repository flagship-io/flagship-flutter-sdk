import 'dart:io';

import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/hits/screen.dart';
import 'package:flagship/tracking/tracking_manager_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship_qa/Providers/fs_data.dart';
import 'package:flagship_qa/mixins/dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import './FSinputField.dart';
import 'dart:math';
import '../widgets/context_screen.dart';
import 'package:path_provider/path_provider.dart';

// My package

// ignore: must_be_immutable
class Configuration extends StatefulWidget {
  bool isSdkReady = false;

  @override
  _ConfigurationState createState() => _ConfigurationState();
}

class _ConfigurationState extends State<Configuration> with ShowDialog {
  final int defaultPollingTime = 60;
  final envIdController = TextEditingController();
  final apiKeyController = TextEditingController();
  final timeoutController = TextEditingController();
  final visitorIdController = TextEditingController();
  final pollingTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  Map<String, Object> visitorContext = {};

  /// Reset filed
  _resetConfig() {
    setState(() {
      print("Reset to default values fields");
      //timeoutController.text = widget.defaultTimeout.toString();
      pollingTimeController.text = defaultPollingTime.toString();
      visitorIdController.text = _createRandomUser();
      Flagship.sharedInstance().onUpdateState(Status.NOT_INITIALIZED);
    });
  }

  /////////////// start sdk ////////////////////
//start SDK

  _startSdk() async {
    // To localize the path of simulator
    Directory tempDir = await getTemporaryDirectory();
    print(tempDir.path);

    Flagship.sharedInstance().onUpdateState(Status.NOT_INITIALIZED);
    FSData fsData = Provider.of<FSData>(context, listen: false);

    /// we did this to allow start(S)
    Flagship.logger(
        Level.ALL, '--------- Start with $visitorIdController.text ---------');

    FlagshipConfig config = ConfigBuilder()
        .withLogLevel(Level.ALL)
        .withMode(fsData.sdkMode)
        .withStatusListener((newStatus) {
          print('--------- Callback with $newStatus ---------');
          //var newVisitor;
          if (newStatus == Status.READY) {
            setState(() {
              widget.isSdkReady = ((newStatus == Status.PANIC_ON) ||
                      (newStatus == Status.READY))
                  ? true
                  : false;
            });
          }
        })
        .withTimeout(int.tryParse(timeoutController.text) ?? fsData.timeout)
        .withTrackingConfig(TrackingManagerConfig(
            batchIntervals: 10, poolMaxSize: 5, batchStrategy: fsData.strategy))
        .build();
    Flagship.start(envIdController.text, apiKeyController.text, config: config);
  }

  _createVisitor() {
    UserData fsUser = Provider.of<UserData>(context, listen: false);
    visitorIdController.text = fsUser.visitorId;
    var newVisitor;
    newVisitor = Flagship.newVisitor(fsUser.visitorId)
        .withContext(fsUser.context)
        .hasConsented(fsUser.hasConsented)
        .isAuthenticated(fsUser.isAuthenticated)
        .build();
    // Set current visitor singleton instance for future use
    Flagship.setCurrentVisitor(newVisitor);
  }

// Fetch flags
  _fetchFalgs() {
    var titleMsg = '';
    Flagship.getCurrentVisitor()?.fetchFlags().whenComplete(() {
      switch (Flagship.getStatus()) {
        case Status.PANIC_ON:
          titleMsg = "SDK is on panic mode, will use default value";
          break;
        case Status.READY:
          titleMsg = "SDK is ready to use";
          break;
        default:
      }
      showBasicDialog(titleMsg, '');
    });
  }

  _onChangeStrategy(FSData pFsData, String value) {
    switch (value) {
      case "CONTINOUS":
        pFsData.updateStrategy(BatchCachingStrategy.BATCH_CONTINUOUS_CACHING);
        break;
      case "PERIODIC":
        pFsData.updateStrategy(BatchCachingStrategy.BATCH_PERIODIC_CACHING);
        break;
      case "NO_STRATEGY":
        pFsData.updateStrategy(
            BatchCachingStrategy.NO_BATCHING_CONTINUOUS_CACHING_STRATEGY);
        break;
    }
    print(
        " ------------- The choosen strategy is ${pFsData.strategy} ----------------");
  }

  void _onTapContext(BuildContext ctx) {
    if (Flagship.getCurrentVisitor() == null) {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return new AlertDialog(
              title: new Text("Visitor not created yet"),
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
      return;
    }
    Navigator.of(ctx).pushNamed(ContextScreen.routeName, arguments: {
      // 'id':id,
    });
  }

  @override
  Widget build(BuildContext context) {
    FSData fsData = Provider.of<FSData>(context, listen: true);
    UserData fsUser = Provider.of<UserData>(context, listen: false);
    List<String> strategyArray = ["CONTINOUS", "PERIODIC", "NO_STRATEGY"];
    double _spaceBetweenInput = 10;
    envIdController.text = fsData.envId;
    apiKeyController.text = fsData.apiKey;
    timeoutController.text = fsData.timeout.toString();
    visitorIdController.text = fsUser.visitorId;
    bool isApiMode = (fsData.sdkMode == Mode.DECISION_API) ? true : false;
    pollingTimeController.text = defaultPollingTime.toString();

    final mediaQuery = MediaQuery.of(context);
    return Container(
      height: mediaQuery.size.height,
      width: mediaQuery.size.width,
      color: Color.fromRGBO(39, 39, 39, 1),
      child: Padding(
        padding: const EdgeInsets.only(left: 20, top: 0, right: 20, bottom: 0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: mediaQuery.viewPadding.top + _spaceBetweenInput,
              ),
              Text(
                "Configuration",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 25),
              ),
              Container(
                child: ElevatedButton(
                  onPressed: _resetConfig,
                  child: Text("Reset"),
                ),
                alignment: Alignment.topRight,
              ),
              SizedBox(height: _spaceBetweenInput),
              FSInputField("EnvId", envIdController, TextInputType.text),
              SizedBox(height: _spaceBetweenInput),
              FSInputField("ApiKey", apiKeyController, TextInputType.text),
              SizedBox(height: _spaceBetweenInput),
              FSInputField(
                "Timeout(ms)",
                timeoutController,
                TextInputType.number,
                onChangeInput: (newText) =>
                    {fsData.updaeTimeout(int.tryParse(newText) ?? 2000)},
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text(
                    "Mode",
                    style: TextStyle(color: Colors.white),
                  )),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => {
                                fsData.updateSdkMode(!isApiMode
                                    ? Mode.DECISION_API
                                    : Mode.BUCKETING)
                              },
                          child: Text((fsData.sdkMode == Mode.DECISION_API)
                              ? "API"
                              : "BUCKETING")))
                ],
              ),
              (fsData.sdkMode == Mode.DECISION_API)
                  ? SizedBox(height: _spaceBetweenInput)
                  : FSInputField("Polling Interval(s)", pollingTimeController,
                      TextInputType.number),
              SizedBox(height: _spaceBetweenInput),
              SizedBox(height: _spaceBetweenInput),
              FSInputField(
                "VisitorId",
                visitorIdController,
                TextInputType.text,
                onChangeInput: (newText) => {fsUser.updateVisitorId(newText)},
              ),
              SizedBox(height: _spaceBetweenInput),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text(
                    "Consent",
                    style: TextStyle(color: Colors.white),
                  )),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () => {
                                fsUser.updateConsent(!fsUser.hasConsented),
                                Flagship.getCurrentVisitor()
                                    ?.setConsent(fsUser.hasConsented),
                                // _consent()
                              },
                          child: Text(fsUser.hasConsented
                              ? "Consented"
                              : "Not Consented")))
                ],
              ),
              SizedBox(height: _spaceBetweenInput),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text(
                    "Strategy",
                    style: TextStyle(color: Colors.white),
                  )),
                  Expanded(
                      child: CupertinoPicker.builder(
                          scrollController: FixedExtentScrollController(
                              initialItem: fsData.strategy.index),
                          itemExtent: 30,
                          childCount: 3,
                          backgroundColor: Color.fromARGB(255, 165, 31, 49),
                          onSelectedItemChanged: (range) =>
                              {_onChangeStrategy(fsData, strategyArray[range])},
                          itemBuilder: (context, range) {
                            return Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                strategyArray[range],
                                style: TextStyle(
                                    color: Colors.white, fontSize: 14),
                              ),
                            );
                          }))
                ],
              ),
              SizedBox(height: _spaceBetweenInput),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: Text(
                    "Authenticate",
                    style: TextStyle(color: Colors.white),
                  )),
                  Container(
                      child: Switch.adaptive(
                    value: fsUser.isAuthenticated,
                    onChanged: (val) {
                      setState(() {
                        fsUser.updateIsAuthenticated(val);
                      });
                    },
                  )),
                ],
              ),
              SizedBox(height: _spaceBetweenInput * 10),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("START"),
                    onPressed: () => {_startSdk()},
                  )),
              SizedBox(height: _spaceBetweenInput),
              SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("CREATE VISITOR"),
                    onPressed: () => {
                      //fsUser.updateVisitorId(_createRandomUser()),
                      _createVisitor()
                    },
                  )),
              SizedBox(height: _spaceBetweenInput),
              Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("FETCH FLAGS"),
                    onPressed: widget.isSdkReady ? () => {_fetchFalgs()} : null,
                  )),
              SizedBox(height: _spaceBetweenInput),
              Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("UPDATE CONTEXT"),
                    onPressed: widget.isSdkReady
                        ? () => {_onTapContext(context)}
                        : null,
                  )),
              SizedBox(height: _spaceBetweenInput),
              Container(
                  width: double.infinity,
                  child: ElevatedButton(
                      child: Text("CUSTOM SCENARIOS"),
                      onPressed: () {
                        _customTest();
                      })),
            ],
          ),
        ),
      ),
    );
  }

  String _createRandomUser() {
    return 'visitor-A' + Random().nextInt(100).toString();
  }

  _customTest() async {
    Visitor vA = Flagship.newVisitor("visitor_A")
        .withContext({"testing_tracking_manager": true})
        .isAuthenticated(true)
        .build();

    vA.fetchFlags().whenComplete(() {
      print("stop");
      //Activate
      var value = vA.getFlag("btnTitle", "defaultValue").value();
      print("the vlaue of flag is " + value);
      vA.sendHit(Screen(location: "screenQA"));
      print("stop"); // to go online mode

      Flagship.sharedInstance().close();
    });
    // to go offline mode

    // Flagship.sharedInstance().close();

    /// mode online

    // var vB = Flagship.newVisitor("visitorB")
    //     .withContext({"testing_tracking_manager": true}).build();

    // await vB.fetchFlags();
    // //Activate
    // var valueBis = vB.getFlag("my_flag", "defaultValue").value();
    // print(valueBis);
    // vB.sendHit(Screen(location: "screenQA"));
  }
}

class CustomCacheHit with IHitCacheImplementation {
  @override
  void cacheHits(Map<String, Map<String, Object>> hits) {
    print("-------------- CUSTOM ------------");
  }

  @override
  void flushAllHits() {
    print("-------------- CUSTOM ------------");
  }

  @override
  void flushHits(List<String> hitIds) {
    print("-------------- CUSTOM ------------");
  }

  @override
  Future<List<Map>> lookupHits() {
    print("-------------- CUSTOM ------------");
    return Future.value([]);
  }
}

class CustomVisitorCache with IVisitorCacheImplementation {
  @override
  void cacheVisitor(String visitorId, String jsonString) {
    print("-------------- CUSTOM VISITOR CACHE------------");
  }

  @override
  void flushVisitor(String visitorId) {
    print("--------------  CUSTOM VISITOR CACHE- ------------");
  }

  @override
  Future<String> lookupVisitor(String visitoId) async {
    Future.delayed(Duration(milliseconds: 200));
    print("--------------  CUSTOM VISITOR CACHE- ------------");
    return Future.value("");
  }
}
