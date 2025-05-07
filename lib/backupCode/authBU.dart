// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:redofyp/auth/login_user.dart';
// import 'package:redofyp/page/home.dart';
//
// class AuthChecker extends StatefulWidget {
//   @override
//   _AuthCheckerState createState() => _AuthCheckerState();
// }
//
// class _AuthCheckerState extends State<AuthChecker> {
//   final _auth = FirebaseAuth.instance;
//
//   @override
//   void initState() {
//     super.initState();
//     // Listen for authentication state changes
//     _auth.authStateChanges().listen((User? user) {
//       if (!mounted) return;
//       if (user != null) {
//         // If user is authenticated, navigate to home screen
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => HomeScreen()),
//         );
//       } else {
//         // If no user is authenticated, navigate to login screen
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => LoginScreen()),
//         );
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Center(child: CircularProgressIndicator()),
//     );
//   }
// }