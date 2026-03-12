import 'dart:io';
import 'package:flagship/cache/interface_cache.dart';
import 'package:flagship/flagship.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/hits/event.dart';
import 'package:flagship/hits/item.dart';
import 'package:flagship/hits/screen.dart';
import 'package:flagship/hits/transaction.dart';
import 'package:flagship/status.dart';
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
      Flagship.sharedInstance().onUpdateState(FSSdkStatus.SDK_NOT_INITIALIZED);
    });
  }

  /////////////// start sdk ////////////////////
//start SDK

  _startSdk() async {
    // To localize the path of simulator
    Directory tempDir = await getTemporaryDirectory();
    print(tempDir.path);

    Flagship.sharedInstance().onUpdateState(FSSdkStatus.SDK_NOT_INITIALIZED);
    FSData fsData = Provider.of<FSData>(context, listen: false);

    /// we did this to allow start(S)
    Flagship.logger(
        Level.ALL, '--------- Start with $visitorIdController.text ---------');

    FlagshipConfig config = ConfigBuilder()
        .withLogLevel(Level.ALL)
        .withMode(fsData.sdkMode)
        .onSdkStatusChanged((newStatus) {
          print('--------- Callback with $newStatus ---------');
          //var newVisitor;
          if (newStatus == FSSdkStatus.SDK_INITIALIZED) {
            setState(() {
              widget.isSdkReady = ((newStatus == FSSdkStatus.SDK_PANIC) ||
                      (newStatus == FSSdkStatus.SDK_INITIALIZED))
                  ? true
                  : false;
            });
          }
        })
        .withTimeout(int.tryParse(timeoutController.text) ?? fsData.timeout)
        .withTrackingConfig(TrackingManagerConfig(
            batchIntervals: 5000,
            poolMaxSize: 10,
            batchStrategy: fsData.strategy))
        .withOnVisitorExposed((visitorExposed, fromFlag) {
          print("-------- On user Exposed callback ----------- ");
          print(fromFlag.toJson());
          print(visitorExposed.toJson());
        })
        .build();
    Flagship.start(envIdController.text, apiKeyController.text, config: config);
  }

  _createVisitor() {
    UserData fsUser = Provider.of<UserData>(context, listen: false);
    visitorIdController.text = fsUser.visitorId;
    var newVisitor;
    newVisitor = Flagship.newVisitor(
            visitorId: fsUser.visitorId, hasConsented: fsUser.hasConsented)
        .withContext(fsUser.context)
        .withOnFlagStatusFetched(() {
          //  print(" @@@@@@@@@@ withOnFlagStatusFetched is called @@@@@@@@@@");
        })
        .withOnFlagStatusFetchRequired((newReason) {
          // withOnFlagStatusFetchRequired
          //  print("#############@ withOnFlagStatusFetchRequired is called with " +
          //  (newReason.toString()) +
          //    " ##############");
        })
        .withOnFlagStatusChanged((newState) {
          // withOnFlagStatusChanged
          // print(" &&&&&&&&&&&&&& withOnFlagStatusChanged is called with " +
          //     newState.toString() +
          //     " &&&&&&&&&&&&&&&&&");
        })
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
        case FSSdkStatus.SDK_PANIC:
          titleMsg = "SDK is on panic mode, will use default value";
          break;
        case FSSdkStatus.SDK_INITIALIZED:
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
    UserData fsUser = Provider.of<UserData>(context, listen: true);
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
              FSInputField("VisitorId", visitorIdController, TextInputType.text,
                  onChangeInput: (newText) {
                fsUser.updateVisitorId(newText);
              }),
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
    for (int i = 0; i < 50; i++) {
      Visitor vA = Flagship.newVisitor(visitorId: "user", hasConsented: true)
          .withContext({"condition1": "test"})
          .isAuthenticated(false)
          .build();

      vA.fetchFlags().whenComplete(() {
        //Activate
        var value = vA.getFlag("btnColor").value("defaultValue");
        print("the vlaue of flag is " + value);
        vA.sendHit(Screen(location: "screenQA"));

        vA.sendHit(Event(
            action: "testEvent", category: EventCategory.Action_Tracking));

        vA.sendHit(Transaction(affiliation: "test", transactionId: "123"));

        vA.sendHit(
            Item(transactionId: "123", name: "nameItem", code: "codeItem"));
        Flagship.sharedInstance().close();
      });
    }
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
