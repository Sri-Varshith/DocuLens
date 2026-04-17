import 'package:flutter/material.dart';
import 'package:doculens/screens/home_screen.dart';

void main() {
  runApp(const DocuLensApp());
}

class DocuLensApp extends StatelessWidget {
  const DocuLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocuLens',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}