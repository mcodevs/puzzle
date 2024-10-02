import 'package:flutter/material.dart';
import 'package:puzzle/variants/v1.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(),
        body: const V1(),
      ),
    );
  }
}
