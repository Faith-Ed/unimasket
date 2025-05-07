// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'package:redofyp/auth/login_user.dart';
//
// class RegisterScreen extends StatefulWidget {
//   @override
//   _RegisterScreenState createState() => _RegisterScreenState();
// }
//
// class _RegisterScreenState extends State<RegisterScreen> {
//   final _auth = FirebaseAuth.instance;
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _fullnameController = TextEditingController();
//   final _contactNumberController = TextEditingController();
//
//   // Error message variables for each field
//   String? emailError;
//   String? passwordError;
//   String? contactNumberError;
//   String? fullnameError;
//   bool _passwordVisible = false;
//
//   // Email validation
//   bool _validateEmail(String email) {
//     return email.endsWith('@unimas.my') || email.endsWith('@siswa.unimas.my');
//   }
//
//   // Password validation (at least 8 characters, contains letters, numbers, and special characters)
//   bool _validatePassword(String password) {
//     return password.length >= 8 && RegExp(r'^(?=.*[A-Za-z])(?=.*\d)').hasMatch(password);
//   }
//
//   // Contact number validation (only digits and 10-11 digits long)
//   bool _validateContactNumber(String contactNumber) {
//     return RegExp(r'^\d{10,11}$').hasMatch(contactNumber);
//   }
//
//   // Register function
//   Future<void> _register() async {
//     setState(() {
//       emailError = null;
//       passwordError = null;
//       contactNumberError = null;
//       fullnameError = null;
//     });
//
//     String fullname = _fullnameController.text;
//     String email = _emailController.text;
//     String password = _passwordController.text;
//     String contactNumber = _contactNumberController.text;
//
//     // Check for empty fields and show appropriate error messages
//     if (fullname.isEmpty) {
//       setState(() {
//         fullnameError = 'Full Name cannot be empty';
//       });
//       return;
//     }
//
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
//     if (contactNumber.isEmpty) {
//       setState(() {
//         contactNumberError = 'Contact Number cannot be empty';
//       });
//       return;
//     }
//
//     // Validate email
//     if (!_validateEmail(email)) {
//       setState(() {
//         emailError =
//         'Please enter a valid email address (@unimas.my or @siswa.unimas.my)';
//       });
//       return;
//     }
//
//     // Validate password
//     if (!_validatePassword(password)) {
//       setState(() {
//         passwordError =
//         'Password must be at least 8 characters long and contain both letters and numbers';
//       });
//       return;
//     }
//
//     // Validate contact number
//     if (!_validateContactNumber(contactNumber)) {
//       setState(() {
//         contactNumberError =
//         'Contact number must be 10 to 11 digits long and contain only numbers';
//       });
//       return;
//     }
//
//     try {
//       // Create a new user with email and password
//       UserCredential userCredential = await _auth
//           .createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//
//       // Get user details
//       User? user = userCredential.user;
//
//       if (user != null) {
//         // Store user data in Firestore
//         await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
//           'fullname': fullname,
//           'email': email,
//           'contact_number': contactNumber,
//           'uid': user.uid,
//         });
//
//         // Send verification email
//         await user.sendEmailVerification();
//
//         // Show a dialog box informing the user to check their email
//         _showEmailVerificationDialog();
//
//       }
//     } catch (e) {
//       setState(() {
//         emailError = e.toString(); // General error for the registration process
//       });
//     }
//   }
//
// // Dialog box to inform the user to check their email
//   void _showEmailVerificationDialog() {
//     showDialog(
//       context: context,
//       builder: (_) => AlertDialog(
//         title: Text("Registration Successful!"),
//         content: Text("Please check your email for the verification link."),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context); // Close the dialog
//               // Navigate to login screen after user clicks OK
//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(builder: (context) => LoginScreen()),
//               );
//             },
//             child: Text("OK"),
//           ),
//         ],
//       ),
//     );
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
//             errorText: null,
//             // Remove the default errorText here
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
//                 color: hasError ? Colors.red : Colors.black,
//                 // Apply red border only if error exists
//                 width: 1,
//               ),
//             ),
//             suffixIcon: suffixIcon,
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
//       resizeToAvoidBottomInset: true,
//       // Ensure the keyboard doesn't push widgets out of the screen
//       body: Container(
//         height: MediaQuery
//             .of(context)
//             .size
//             .height, // Full screen height
//         decoration: BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage('assets/unimas.png'), // Background image
//             fit: BoxFit.cover, // Cover the whole screen
//           ),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(5.0),
//           child: Center(
//             child: Container(
//               height: 600,
//               width: 350,
//               // Fixed width for the container to make it smaller
//               padding: EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white.withOpacity(0.9),
//                 // Semi-transparent background
//                 borderRadius: BorderRadius.circular(10),
//               ),
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.start, // Align at the top
//                 children: [
//                   Image.asset(
//                       'assets/unimas_logo.png', height: 150, width: 150),
//                   Align(
//                     alignment: Alignment.centerLeft, // Align it to the left
//                     child: Text(
//                       'Sign Up',
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.blue,
//                       ),
//                     ),
//                   ),
//                   SizedBox(height: 10),
// // Use Expanded to allow dynamic resizing for each text field and button
//                   Expanded(
//                     child: SingleChildScrollView( // Use scroll view for keyboard adjustment
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.start,
//                         children: [
//                           _buildTextField(
//                             controller: _fullnameController,
//                             labelText: 'Full Name',
//                             obscureText: false,
//                             errorText: fullnameError,
//                           ),
//                           SizedBox(height: 10),
//
//                           _buildTextField(
//                             controller: _emailController,
//                             labelText: 'Email',
//                             obscureText: false,
//                             errorText: emailError,
//                           ),
//                           SizedBox(height: 10),
//                           _buildTextField(
//                             controller: _passwordController,
//                             labelText: 'Password',
//                             obscureText: !_passwordVisible,
//                             errorText: passwordError,
//                             suffixIcon: IconButton(
//                               icon: Icon(
//                                 _passwordVisible
//                                     ? Icons.visibility
//                                     : Icons.visibility_off,
//                               ),
//                               onPressed: () {
//                                 setState(() {
//                                   _passwordVisible = !_passwordVisible;
//                                 });
//                               },
//                             ),
//                           ),
//                           SizedBox(height: 10),
//
//                           _buildTextField(
//                             controller: _contactNumberController,
//                             labelText: 'Contact Number',
//                             obscureText: false,
//                             errorText: contactNumberError,
//                           ),
//                           SizedBox(height: 20),
//
//                           // Register button
//                           ElevatedButton(
//                             style: ButtonStyle(
//                               backgroundColor: MaterialStateProperty.all(
//                                   Colors.red),
//                               padding: MaterialStateProperty.all(
//                                 EdgeInsets.symmetric(
//                                     horizontal: 100, vertical: 15),
//                               ),
//                               shape: MaterialStateProperty.all(
//                                 RoundedRectangleBorder(
//                                   borderRadius: BorderRadius.circular(5),
//                                 ),
//                               ),
//                             ),
//                             onPressed: _register,
//                             child: Text('Register',
//                                 style: TextStyle(color: Colors.white)),
//                           ),
//                           SizedBox(height: 5),
//
//                           // Login text button
//                           TextButton(
//                             onPressed: () {
//                               Navigator.pushReplacement(
//                                 context,
//                                 MaterialPageRoute(
//                                     builder: (context) => LoginScreen()),
//                               );
//                             },
//                             child: RichText(
//                               text: TextSpan(
//                                 children: [
//                                   TextSpan(
//                                     text: 'Already have an account? ',
//                                     style: TextStyle(
//                                         color: Colors.black, fontSize: 12),
//                                   ),
//                                   TextSpan(
//                                     text: 'Login',
//                                     style: TextStyle(
//                                         color: Colors.red, fontSize: 12),
//                                   ),
//                                 ],
//                               ),
//                             ),
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
