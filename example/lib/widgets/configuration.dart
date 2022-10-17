import 'package:flagship/flagshipContext/flagship_context.dart';
import 'package:flagship/flagship_config.dart';
import 'package:flagship/utils/constants.dart';
import 'package:flagship/utils/logger/log_manager.dart';
import 'package:flagship/visitor.dart';
import 'package:flagship_qa/mixins/dialog.dart';
import 'package:flutter/material.dart';
import './FSinputField.dart';
import 'dart:math';
import '../widgets/context_screen.dart';
// My package
import 'package:flagship/flagship.dart';

class Configuration extends StatefulWidget {
  bool isApiMode = true;
  bool isAuthenticate = false;
  bool isConsented = true;

  @override
  _ConfigurationState createState() => _ConfigurationState();
}

class _ConfigurationState extends State<Configuration> with ShowDialog {
  // keys
  String apiKey = "DxAcxlnRB9yFBZYtLDue1q01dcXZCw6aM49CQB23";
  String envId = "bkk9glocmjcg0vtmdlng";

  final int defaultTimeout = 2000;
  final int defaultPollingTime = 60;

  final envIdController = TextEditingController();
  final apiKeyController = TextEditingController();
  final timeoutController = TextEditingController();
  final visitorIdController = TextEditingController();
  final pollingTimeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    visitorContext = Map<String, Object>.from(initialVisitorContext);
    visitorIdController.text = _createRandomUser();
  }

  final Map<String, Object> initialVisitorContext = {
    "isVipClient": true,
    "qa_getflag": true,
    "bucketingKey": "condition1",
    "QA": true,
    "qaKeyString": "beta",
    "qaKeyNumber": 2222
  };

  Map<String, Object> visitorContext = {};

  /// Reset filed
  _resetConfig() {
    setState(() {
      print("Reset to default values fields");
      timeoutController.text = defaultTimeout.toString();
      pollingTimeController.text = defaultPollingTime.toString();
      visitorIdController.text = _createRandomUser();
      visitorContext = initialVisitorContext;
      widget.isApiMode = true;
      Flagship.sharedInstance().onUpdateState(Status.NOT_INITIALIZED);
    });
  }

  /////////////// start sdk ////////////////////
//start SDK

  _startSdk() {
    Flagship.sharedInstance().onUpdateState(Status.NOT_INITIALIZED);

    /// we did this to allow start(S)
    Flagship.logger(Level.ALL, '--------- Start with $visitorIdController.text ---------');

    FlagshipConfig config = ConfigBuilder()
        .withMode(widget.isApiMode ? Mode.DECISION_API : Mode.BUCKETING)
        .withStatusListener((newStatus) {
          print('--------- Callback with $newStatus ---------');
          var titleMsg = '';
          var newVisitor;
          if (newStatus == Status.READY) {
            //Get the visitor
            // visitor = Flagship.getCurrentVisitor();
            // if (visitor == null) {
            // Create visitor if null
            newVisitor = Flagship.newVisitor(visitorIdController.text)
                .withContext(visitorContext)
                .hasConsented(widget.isConsented)
                .isAuthenticated(widget.isAuthenticate)
                .build();
            // Set current visitor singleton instance for future use
            Flagship.setCurrentVisitor(newVisitor);
            // }

            newVisitor.fetchFlags().whenComplete(() {
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
        })
        .withTimeout(int.tryParse(timeoutController.text) ?? defaultTimeout)
        .build();
    Flagship.start(envIdController.text, apiKeyController.text, config: config);
  }

// Change Mode
  _changeMode() {
    setState(() {
      widget.isApiMode = !widget.isApiMode;
    });
  }

  // Consent Mode
  _consent() {
    // For now, disabled bucketing mode
    setState(() {
      widget.isConsented = !widget.isConsented;
    });
    Flagship.getCurrentVisitor()?.setConsent(widget.isConsented);
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
    double _spaceBetweenInput = 10;
    envIdController.text = envId;
    apiKeyController.text = apiKey;
    timeoutController.text = defaultTimeout.toString();
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
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),
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
              FSInputField("Timeout(ms)", timeoutController, TextInputType.number),
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
                          onPressed: () => {_changeMode()}, child: Text(widget.isApiMode ? "API" : "BUCKETING")))
                ],
              ),
              (widget.isApiMode == true)
                  ? SizedBox(height: _spaceBetweenInput)
                  : FSInputField("Polling Interval(s)", pollingTimeController, TextInputType.number),
              SizedBox(height: _spaceBetweenInput),
              SizedBox(height: _spaceBetweenInput),
              FSInputField("VisitorId", visitorIdController, TextInputType.text),
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
                          onPressed: () => {_consent()},
                          child: Text(widget.isConsented ? "Consented" : "Not Consented")))
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
                    value: widget.isAuthenticate,
                    onChanged: (val) {
                      setState(() {
                        widget.isAuthenticate = val;
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
              Container(
                  width: double.infinity,
                  child: ElevatedButton(
                    child: Text("Update context & synchronize"),
                    onPressed: () => {_onTapContext(context)},
                  )),
            ],
          ),
        ),
      ),
    );
  }

  String _createRandomUser() {
    return 'user_' + Random().nextInt(100).toString();
  }

  doMe() {
// Create a visitor

    Visitor visitor = Flagship.newVisitor("random_Id").withContext({"isVip": true}).build();

// Call the authenticate function

    visitor.authenticate("random_Id");

// Fetch the flags to update the visitor decision

    visitor.fetchFlags().whenComplete(() {
      // ... Do things ....
    });

// If you want to unauthenticate the visitor

    visitor.unauthenticate();

// Fetch the flags to update the visitor decision

    visitor.fetchFlags().whenComplete(() {
      // ... Do things ....
    });

    // Update the location country
    visitor.updateFlagshipContext(FlagshipContext.LOCATION_COUNTRY, "FRANCE");
    // Update the carrier name
    visitor.updateFlagshipContext(FlagshipContext.CARRIER_NAME, "SFR");

//////////////////////////////////////////////
/////// Start sdk with default options ///////
//////////////////////////////////////////////

    Flagship.start("your_env_id", "your_api_key");

//////////////////////////////////////////////
/////// Start sdk with custom options  ///////
//////////////////////////////////////////////

// - timeout   = 1500 ms
// - level     = warning message
// - activated = true
// - statusListener callback

// create a config :

//////////////////////////////////////////////
/////// Start SDK with custom options  ///////
//////////////////////////////////////////////

// - timeout   = 1500 ms
// - level     = warning message
// - statusListener callback

    FlagshipConfig customConfig = ConfigBuilder()
        .withMode(Mode.DECISION_API)
        .withStatusListener((newStatus) {
          // Do things when status change ...
        })
        .withTimeout(1500)
        .withLogLevel(Level.WARNING)
        .build();

// Start SDK
    Flagship.start("envId", "apiKey", config: customConfig);
  }
}
