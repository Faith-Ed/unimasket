import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../widgets/pageDesign.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;
  String? _fullName;
  String? _userEmail;
  String? _profileImageUrl;
  String? _contactNumber;
  String? _qrCodeUrl; // Store the QR Code URL
  TextEditingController _oldPasswordController = TextEditingController();
  TextEditingController _newPasswordController = TextEditingController();
  TextEditingController _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _getUserData();
  }

  // Fetch user data from Firestore
  Future<void> _getUserData() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _fullName = userDoc['fullname']; // Full name of the user
          _userEmail = userDoc['email'];   // Email of the user
          _contactNumber = userDoc['contact_number']; // Contact number of the user
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    }

    // Fetch Profile Image URL and QR Code URL
    final photoDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('photo_profile')
        .doc('profile')
        .get();

    if (photoDoc.exists) {
      setState(() {
        _profileImageUrl = photoDoc['url'];
      });
    }

    final qrCodeDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('qr_codes')
        .doc('profile')
        .get();

    if (qrCodeDoc.exists) {
      setState(() {
        _qrCodeUrl = qrCodeDoc['url'];
      });
    }
  }

  // Update Full Name
  Future<void> _updateFullName(String newName) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({'fullname': newName});
      await _getUserData(); // Fetch updated user data
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Name updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update name: $e')));
    }
  }

  // Show Edit Name Dialog
  void _showEditNameDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController nameController = TextEditingController(text: _fullName);
        return AlertDialog(
          title: Text('Edit Name'),
          content: TextField(
            controller: nameController,
            decoration: InputDecoration(labelText: 'New Name'),
          ),
          actions: [
            TextButton(
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue), // Button color
                padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 40, vertical: 15)), // Padding
                shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), // Rounded corners
              ),
              onPressed: () {
                _updateFullName(nameController.text.trim());
                Navigator.pop(context);
              },
              child: Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // Update Contact Number
  Future<void> _updateContactNumber(String newNumber) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .update({'contact_number': newNumber});
      await _getUserData(); // Fetch updated user data
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contact number updated successfully')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update contact number: $e')));
    }
  }

// Show Edit Contact Number Dialog
  void _showEditContactNumberDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        TextEditingController contactController = TextEditingController(text: _contactNumber);
        String? errorMessage; // Variable to hold the error message

        return StatefulBuilder(
          builder: (BuildContext context, setState) {
            return AlertDialog(
              title: Text('Edit Contact Number'),
              content: Column(
                mainAxisSize: MainAxisSize.min, // Ensure the column takes minimum space
                children: [
                  TextField(
                    controller: contactController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'New Contact Number',
                      suffixIcon: errorMessage != null
                          ? Icon(
                        Icons.error,
                        color: Colors.red,  // Red error icon
                      )
                          : null,  // Show error icon only if there's an error
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                      border: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.black, width: 1),
                      ),
                    ),
                  ),
                  SizedBox(height: 10), // Space between the TextField and the error message
                  // Only display the error message if it's not null
                  if (errorMessage != null)
                    Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red), // Error message in red
                    ),
                ],
              ),
              actions: [
                TextButton(
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue), // Button color
                    padding: MaterialStateProperty.all(EdgeInsets.symmetric(horizontal: 40, vertical: 15)), // Padding
                    shape: MaterialStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), // Rounded corners
                  ),
                  onPressed: () {
                    // Get the contact number input and trim any spaces
                    String newContactNumber = contactController.text.trim();

                    // Validate the length of the contact number
                    if (newContactNumber.length < 10 || newContactNumber.length > 11) {
                      // If the length is not between 10 and 11, show an error message below the TextField
                      setState(() {
                        errorMessage = 'Please enter a valid contact number (10 to 11 digits).';
                      });
                    } else {
                      // If validation passes, update the contact number in the database
                      setState(() {
                        errorMessage = null; // Clear error message if valid
                      });
                      _updateContactNumber(newContactNumber);
                      Navigator.pop(context); // Close the dialog
                    }
                  },
                  child: Text('Save', style: TextStyle(color: Colors.white)), // Text color inside the button
                ),
              ],
            );
          },
        );
      },
    );
  }

  // Pick a new image from gallery
  Future<void> _uploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      final cloudinaryUploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/dgou42nni/image/upload');

      final request = http.MultipartRequest('POST', cloudinaryUploadUrl)
        ..fields['upload_preset'] = 'flutter_unsigned'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      try {
        final response = await request.send();

        if (response.statusCode == 200) {
          final resStr = await response.stream.bytesToString();
          final resJson = json.decode(resStr);
          final downloadUrl = resJson['secure_url'];

          // Save Cloudinary image URL to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user.uid)
              .collection('photo_profile')
              .doc('profile')
              .set({'url': downloadUrl});

          setState(() {
            _profileImageUrl = downloadUrl;
          });

          // Return the new profile image URL to the calling screen (MeMenuScreen)
          Navigator.pop(context, downloadUrl); // This line is important to return the URL
        } else {
          print("Cloudinary upload failed with status: ${response.statusCode}");
        }
      } catch (e) {
        print("Image upload error: $e");
      }
    }
  }

  // Update Password
  Future<void> _updatePassword() async {
    try {
      // Check if old password is correct
      User? user = _auth.currentUser;
      AuthCredential credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: _oldPasswordController.text,
      );

      // Reauthenticate user
      await user.reauthenticateWithCredential(credential);

      // Check if new password matches confirm password
      if (_newPasswordController.text == _confirmPasswordController.text) {
        // Update password
        await user.updatePassword(_newPasswordController.text);

        // Clear the password fields after successful update
        _oldPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password updated successfully')),
        );
        Navigator.pop(context);  // Close the dialog
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Passwords do not match')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Incorrect old password')),
      );
    }
  }

  // Show Password Update Dialog
  void _showPasswordUpdateDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Password"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _oldPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Old Password'),
              ),
              TextField(
                controller: _newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'New Password'),
              ),
              TextField(
                controller: _confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Confirm New Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: _updatePassword,
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

// Upload QR code image
  Future<void> _uploadQRCode() async {
    // Set loading state to true while the upload is in progress
    setState(() {
      _isUploading = true;
    });

    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      final cloudinaryUploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/dgou42nni/image/upload');

      final request = http.MultipartRequest('POST', cloudinaryUploadUrl)
        ..fields['upload_preset'] = 'flutter_unsigned'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      try {
        final response = await request.send();

        if (response.statusCode == 200) {
          final resStr = await response.stream.bytesToString();
          final resJson = json.decode(resStr);
          final downloadUrl = resJson['secure_url'];

          // Save Cloudinary QR code URL to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user.uid)
              .collection('qr_codes')
              .doc('profile')
              .set({'url': downloadUrl});

          setState(() {
            _qrCodeUrl = downloadUrl; // Update the QR code URL
            _isUploading = false; // Set loading state to false after upload is complete
          });

          // Close the current dialog and reopen it to display the new QR code immediately
          Navigator.pop(context);  // Close the dialog
          _showQRCodeDialog(); // Reopen the dialog to show the new QR code

        } else {
          print("Cloudinary upload failed with status: ${response.statusCode}");
          setState(() {
            _isUploading = false; // Set loading state to false in case of error
          });
        }
      } catch (e) {
        print("QR Code upload error: $e");
        setState(() {
          _isUploading = false; // Set loading state to false in case of error
        });
      }
    }
  }

// Add a flag to track the uploading state
  bool _isUploading = false; // Variable to track if uploading is in progress

// Show QR Code Dialog (new feature)
  void _showQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0), // Rounded corners for the dialog
          ),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.8,  // 80% of screen width
            height: MediaQuery.of(context).size.height * 0.6,  // 60% of screen height
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Close button (top-right corner)
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.black45),
                    onPressed: () {
                      Navigator.pop(context); // Close the dialog
                    },
                  ),
                ),
                // Title at the top center of the dialog
                Center(
                  child: Text(
                    "Your QR Code",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
                SizedBox(height: 16), // Space between title and image

                // Show the loading spinner while uploading
                _isUploading
                    ? Center(child: CircularProgressIndicator()) // Show loading indicator if uploading
                    : (_qrCodeUrl == null
                    ? Center(child: Text("QR Code for your account is not uploaded yet. Please upload one."))
                    : Expanded(
                  child: Center(
                    child: Image.network(
                      _qrCodeUrl!,
                      fit: BoxFit.contain, // Ensure the image scales while maintaining the aspect ratio
                    ),
                  ),
                )), // Display QR code if uploaded
                SizedBox(height: 20),

                // Square-shaped button for Upload QR Code or Update QR Code
                Center(
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadQRCode, // Disable the button while uploading
                    child: Text(
                      _qrCodeUrl == null ? "Upload QR Code" : "Update QR Code",
                      style: TextStyle(color: Colors.white), // Change text color here
                    ),
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,  // No rounded corners for a square button
                      ), backgroundColor: Colors.blueAccent,  // Button background color
                      minimumSize: Size(300, 50),  // Make the button square (width and height are the same)
                      padding: EdgeInsets.symmetric(vertical: 16),  // Adjust padding for square button
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,  // Set the background color to yellow
      appBar: customAppBar('Profile'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Profile Picture
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  child: _profileImageUrl == null
                      ? Icon(Icons.person, size: 50, color: Colors.indigo[900])
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  onPressed: _uploadProfileImage,
                  padding: const EdgeInsets.all(0),
                  constraints: const BoxConstraints(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: const CircleBorder(),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            ListTile(
              title: Text('Name'),
              subtitle: Text(_fullName ?? 'Loading...'),
              trailing: Icon(Icons.edit),
              onTap: _showEditNameDialog,
            ),
            Divider(color: Colors.yellowAccent.shade200.withOpacity(0.4)),
            ListTile(
              title: Text(
                'Email',
                style: TextStyle(color: Colors.black), // Change color here
              ),
              subtitle: Text(
                _userEmail ?? 'Loading...',
              ),
              enabled: false, // Email is non-editable
            ),
            Divider(color: Colors.yellowAccent.shade200.withOpacity(0.4)),
            ListTile(
              title: Text('Contact Number'),
              subtitle: Text(_contactNumber ?? 'Loading...'),
              trailing: Icon(Icons.edit),
              onTap: _showEditContactNumberDialog,
            ),
            SizedBox(height: 20),
            Divider(color: Colors.yellowAccent.shade200.withOpacity(0.4)),
            // Update Password Button
            ListTile(
              title: Text('Update Password'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: _showPasswordUpdateDialog,
            ),
            SizedBox(height: 20),
            Divider(color: Colors.yellowAccent.shade200.withOpacity(0.4)),
            // Add Your QR Code ListTile
            ListTile(
              title: Text('Your QR Code'),
              trailing: Icon(Icons.upload),
              onTap: _showQRCodeDialog,
            ),
          ],
        ),
      ),
    );
  }
}
