import 'package:flutter/material.dart';
import 'ui/get_started.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Météo france',
      home: GetStarted(),
      debugShowCheckedModeBanner: false,
    );
  }
}
