import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;

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
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load user data: $e')),
      );
    }

    // After setting userData
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

  // Update the profile details in Firestore


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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
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
            // Name and Email Fields (ListTile)
            ListTile(
              title: Text('Name'),
              subtitle: Text(_fullName ?? 'Loading...'),
              trailing: Icon(Icons.edit),
              onTap: () {
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
                          onPressed: () {
                            setState(() {
                              _fullName = nameController.text;
                            });
                            Navigator.pop(context);
                          },
                          child: Text('Save'),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            ListTile(
              title: Text('Email'),
              subtitle: Text(_userEmail ?? 'Loading...'),
              enabled: false, // Email is non-editable
            ),
            SizedBox(height: 20),
            // Update Password Button
            ListTile(
              title: Text('Update Password'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: _showPasswordUpdateDialog,
            ),
          ],
        ),
      ),
    );
  }
}
