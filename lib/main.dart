import 'package:flutter/material.dart';
import 'package:serial_history_viewer/screens/scan_screen.dart';

void main() {
  runApp(const SerialHistoryViewerApp());
}

class SerialHistoryViewerApp extends StatefulWidget {
  const SerialHistoryViewerApp({Key? key}) : super(key: key);

  @override
  _SerialHistoryViewerAppState createState() => _SerialHistoryViewerAppState();
}

class _SerialHistoryViewerAppState extends State<SerialHistoryViewerApp> {
  bool _isDarkMode = false;

  void toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serial History Viewer',
      theme: ThemeData(
        brightness: _isDarkMode ? Brightness.dark : Brightness.light,
        primarySwatch: Colors.blue,
      ),
      home: ScanScreen(onToggleTheme: toggleTheme),
      debugShowCheckedModeBanner: false,
    );
  }
}
