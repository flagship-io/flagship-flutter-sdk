import 'dart:io';

import 'package:flagship/flagship.dart';
import 'package:flagship_qa/widgets/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './widgets/configuration.dart';
import './widgets/Modifications.dart';
import './widgets/Hits.dart';
import './widgets/context_screen.dart';
import './widgets/modifications_json_screen.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
  HttpOverrides.global = MyHttpOverrides();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MainScreen(title: "FlagshipQA"),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.pink).copyWith(secondary: Colors.amber),
      ),
      initialRoute: '/',
      routes: {
        ContextScreen.routeName: (ctx) => ContextScreen(),
        ModificationsJSONScreen.routeName: (ctx) => ModificationsJSONScreen()
      },
    );
  }
}

class MainScreen extends StatefulWidget {
  MainScreen({title = ""});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  User xpcUser = User(null);

  /// List of widget
  late List<Widget> listWidgets;
  @override
  void initState() {
    listWidgets = [Configuration(), xpcUser, Modifications(), Hits()];
    super.initState();
  }

  int _selectedIndex = 0;

  void _onTap(int newIndex) {
    setState(() {
      _selectedIndex = newIndex;

      if (_selectedIndex == 1) {
        /// The user item for xpc
        xpcUser.update(Flagship.sharedInstance().currentVisitor);
      }
    });
  }

  List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: "configuration",
      backgroundColor: Colors.blueGrey,
    ),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: "User", backgroundColor: Colors.blueGrey),
    BottomNavigationBarItem(icon: Icon(Icons.flag), label: "Modifications", backgroundColor: Colors.blueGrey),
    BottomNavigationBarItem(icon: Icon(Icons.api), label: "Hits", backgroundColor: Colors.blueGrey)
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        showUnselectedLabels: false,
        showSelectedLabels: true,
        items: items,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.red[800],
        onTap: _onTap,
      ),
      body: Center(child: listWidgets.elementAt(_selectedIndex)
          // child: IndexedStack(
          //   children: listWidgets,
          //   index: _selectedIndex,
          // ),
          ),
    );
  }
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    HttpClient htClient = super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return htClient;
  }
}
