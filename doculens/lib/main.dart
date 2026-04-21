import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:doculens/screens/home_screen.dart';
import 'package:doculens/theme/app_theme.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const DocuLensApp());
}

class DocuLensApp extends StatelessWidget {
  const DocuLensApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DocuLens',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeScreen(),
    );
  }
}