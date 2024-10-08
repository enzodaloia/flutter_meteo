import 'package:flutter/material.dart';
import 'ui/get_started.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Méteo France',
      home: GetStarted(),
      debugShowCheckedModeBanner: false,
    );
  }
}
