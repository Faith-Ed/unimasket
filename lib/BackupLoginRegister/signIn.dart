// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:redofyp/auth/register_user.dart';
// import 'package:redofyp/page/home.dart';
//
// class LoginScreen extends StatefulWidget {
//   @override
//   _LoginScreenState createState() => _LoginScreenState();
// }
//
// class _LoginScreenState extends State<LoginScreen> {
//   final _auth = FirebaseAuth.instance;
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   String emailError = '';
//   String passwordError = '';
//   bool _passwordVisible = false;
//
//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: Colors.black,
//         duration: Duration(seconds: 10),
//       ),
//     );
//   }
//
//   Future<void> _login() async {
//     setState(() {
//       emailError = '';
//       passwordError = '';
//     });
//
//     String email = _emailController.text;
//     String password = _passwordController.text;
//
//     // Check for empty fields and show appropriate error messages
//     if (email.isEmpty) {
//       setState(() {
//         emailError = 'Email cannot be empty';
//       });
//       return;
//     }
//
//     if (password.isEmpty) {
//       setState(() {
//         passwordError = 'Password cannot be empty';
//       });
//       return;
//     }
//
//     try {
//       // Check if the email is already registered before attempting to sign in
//       final signInMethods = await _auth.fetchSignInMethodsForEmail(email);
//
//       if (signInMethods.isEmpty) {
//         // If the email is not found, show an error and redirect to the Register screen
//         _showErrorSnackBar('Email is not registered. Please sign up first.');
//         // Redirect to register screen
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => RegisterScreen()),
//         );
//         return; // Stop further execution
//       }
//
//       UserCredential userCredential = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       User? user = userCredential.user;
//
//       // Check if email is verified
//       if (user != null && !user.emailVerified) {
//         // If email is not verified, show a message and ask to verify
//         await user.sendEmailVerification();
//         showDialog(
//           context: context,
//           builder: (_) => AlertDialog(
//             title: Text("Email not verified"),
//             content: Text("Please check your inbox for the verification link."),
//             actions: [
//               TextButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                 },
//                 child: Text("OK"),
//               ),
//             ],
//           ),
//         );
//       } else {
//         // If email is verified, go to home screen
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => HomeScreen()),
//         );
//       }
//     } catch (e) {
//       setState(() {
//         emailError = 'Invalid email or password';
//         passwordError = '';
//       });
//     }
//   }
//
//   // Create a custom TextField with error handling
//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String labelText,
//     required bool obscureText,
//     String? errorText,
//     Widget? suffixIcon,
//   }) {
//     bool hasError = errorText != null && errorText.isNotEmpty;
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TextField(
//           controller: controller,
//           obscureText: obscureText,
//           decoration: InputDecoration(
//             labelText: labelText,
//             errorText: null, // Remove the default errorText here
//             errorBorder: OutlineInputBorder(
//               borderSide: BorderSide(color: Colors.red, width: 1),
//             ),
//             focusedErrorBorder: OutlineInputBorder(
//               borderSide: BorderSide(color: Colors.red, width: 1),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderSide: BorderSide(color: Colors.blue, width: 2),
//             ),
//             border: OutlineInputBorder(
//               borderSide: BorderSide(
//                 color: hasError ? Colors.red : Colors.black, // Apply red border only if error exists
//                 width: 1,
//               ),
//             ),
//             suffixIcon: hasError
//                 ? Icon(
//               Icons.error,
//               color: Colors.red,
//             )
//                 : suffixIcon, // Show error icon if there's an error, otherwise show eye icon
//           ),
//         ),
//         // Show error message only if there's an error
//         if (errorText != null && errorText.isNotEmpty)
//           Padding(
//             padding: const EdgeInsets.only(top: 4.0),
//             child: Text(
//               errorText,
//               style: TextStyle(color: Colors.red, fontSize: 12),
//             ),
//           ),
//       ],
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       resizeToAvoidBottomInset: true, // Allow resizing when keyboard appears
//       body: Container(
//         height: MediaQuery.of(context).size.height, // Full screen height
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('assets/unimas.png'), // Background image
//             fit: BoxFit.cover, // Cover the whole screen
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Center(
//             child: Container(
//               height: 600,
//               width: 350, // Fixed width for the container to make it smaller
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.9), // Semi-transparent background
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center, // Center content vertically
//                 children: [
//                   // Logo at the top
//                   Image.asset('assets/unimas_logo.png', height: 180, width: 180),
//                   SizedBox(height: 5),
//                   Align(
//                     alignment: Alignment.centerLeft,  // Align it to the left
//                     child: Text(
//                       'Sign Up',
//                       style: TextStyle(
//                         fontSize: 22,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 20),
//
//                   // Use Flexible to make TextFields and Buttons dynamically resize
//                   _buildTextField(
//                     controller: _emailController,
//                     labelText: 'Email',
//                     obscureText: false,
//                     errorText: emailError.isEmpty ? null : emailError,
//                   ),
//                   SizedBox(height: 20),
//
//                   _buildTextField(
//                     controller: _passwordController,
//                     labelText: 'Password',
//                     obscureText: !_passwordVisible,  // Password visibility toggle
//                     errorText: passwordError.isEmpty ? null : passwordError,
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _passwordVisible ? Icons.visibility : Icons.visibility_off,
//                       ),
//                       onPressed: () {
//                         setState(() {
//                           _passwordVisible = !_passwordVisible;
//                         });
//                       },
//                     ),
//                   ),
//                   SizedBox(height: 20),
//
//                   // Login Button
//                   ElevatedButton(
//                     style: ButtonStyle(
//                       backgroundColor: MaterialStateProperty.all(Colors.red),
//                       padding: MaterialStateProperty.all(
//                         EdgeInsets.symmetric(horizontal: 100, vertical: 15),
//                       ),
//                       shape: MaterialStateProperty.all(
//                         RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(5), // Less rounded corners
//                         ),
//                       ),
//                     ),
//                     onPressed: _login,
//                     child: Text('Login', style: TextStyle(color: Colors.white)),
//                   ),
//                   SizedBox(height: 20),
//
//                   // Register TextButton
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pushReplacement(
//                         context,
//                         MaterialPageRoute(builder: (context) => RegisterScreen()),
//                       );
//                     },
//                     child: RichText(
//                       text: TextSpan(
//                         children: [
//                           TextSpan(
//                             text: 'Don\'t have an account?',
//                             style: TextStyle(color: Colors.black, fontSize: 12),
//                           ),
//                           TextSpan(
//                             text: ' Register',
//                             style: TextStyle(color: Colors.red, fontSize: 12),
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
