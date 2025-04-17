import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:redofyp/auth/auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter App',
      home: AuthChecker(),
    );
  }
}
