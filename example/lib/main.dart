import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import './widgets/configuration.dart';
import './widgets/Modifications.dart';
import './widgets/Hits.dart';
import './widgets/context_screen.dart';
import './widgets/modifications_json_screen.dart';

void main() {
  SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
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
  /// List of widget
  final List<Widget> listWidgets = [
    Configuration(),
    // User(),
    Modifications(),
    Hits()
  ];

  MainScreen({title = ""});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onTap(int newIndex) {
    setState(() {
      _selectedIndex = newIndex;
    });
  }

  final List<BottomNavigationBarItem> items = [
    BottomNavigationBarItem(
      icon: Icon(Icons.settings),
      label: "configuration",
      backgroundColor: Colors.blueGrey,
    ),
    // BottomNavigationBarItem(icon: Icon(Icons.person), label: "User", backgroundColor: Colors.blueGrey),
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
      body: Center(
        child: IndexedStack(
          children: widget.listWidgets,
          index: _selectedIndex,
        ),
      ),
    );
  }
}
