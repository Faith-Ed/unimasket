import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redofyp/page/profile_page.dart';
import '../auth/login_user.dart';
import 'home.dart'; // Make sure you have the HomeScreen route

class MeMenuScreen extends StatefulWidget {
  @override
  _MeMenuScreenState createState() => _MeMenuScreenState();
}

class _MeMenuScreenState extends State<MeMenuScreen> {
  final _auth = FirebaseAuth.instance;
  bool _isAiChatbotEnabled = true; // Default value for AI Chatbot toggle
  int _currentIndex = 3; // Set initial index for 'Me' tab
  String? _profileImageUrl;
  String? _userName;
  late User _user;

  // Logout functionality
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()), // Navigate to LoginScreen after logout
    );
  }

  // Fetch user data from Firestore
  Future<void> _getUserData() async {
    _user = _auth.currentUser!;

      // Fetching the user's document from Firestore
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          // Extract user's name from Firestore document
          _userName =
          userDoc['fullname'];
        });

    // Fetching the profile image URL from Firestore
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
  }

  // Navigation functionality
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()), // Navigate to HomeScreen
              (Route<dynamic> route) => false, // Remove previous screens from the stack
        );
      } else if (index == 1) {
        // Navigate to Chats screen
      } else if (index == 2) {
        // Navigate to Notifications screen
      }
    });
  }

  // Update the profile image URL after it's uploaded
  void _updateProfileImageUrl(String newImageUrl) {
    setState(() {
      _profileImageUrl = newImageUrl;
    });
  }

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _getUserData(); // Fetch user data when MeMenuScreen is first loaded
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Cart and Notification Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: Icon(Icons.shopping_cart),
                  onPressed: () {
                    // Navigate to the shopping cart page if you have one
                  },
                ),
                IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    // Navigate to the notifications page
                  },
                ),
              ],
            ),
            // Profile Section
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundImage: _profileImageUrl != null
                    ? NetworkImage(_profileImageUrl!)
                    : AssetImage('assets/default_avatar.png') as ImageProvider,
                child: _profileImageUrl == null
                    ? Icon(Icons.person, size: 50, color: Colors.indigo[900])
                    : null,
              ),
            ),
            SizedBox(height: 8),
            Center(
              child: Text(
                _userName ?? 'Loading...',  // Display the user's name or 'Loading...' if it's not available
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            SizedBox(height: 20),

            // Profile and Transaction History Links
            ListTile(
              title: Text('Profile'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () async {
                // Navigate to the Profile page and wait for the new image URL after the update
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage()),
                );

                // If the result is not null, update the profile image URL
                if (result != null) {
                  _updateProfileImageUrl(result);
                }
              },
            ),
            ListTile(
              title: Text('Transaction History'),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Navigate to the Transaction History page
              },
            ),

            // AI Chatbot Toggle
            ListTile(
              title: Text('AI Chatbot'),
              trailing: Switch(
                value: _isAiChatbotEnabled,
                onChanged: (value) {
                  setState(() {
                    _isAiChatbotEnabled = value;
                  });
                },
              ),
            ),

            // Log Out Button
            ListTile(
              title: Text('Log Out'),
              textColor: Colors.red,
              onTap: _logout,
            ),

            SizedBox(height: 20),

            // "Go Shopping Now!" Button
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()), // Navigate to home or shopping page
                      (Route<dynamic> route) => false,
                );
              },
              child: Text('Go Shopping Now!'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white, backgroundColor: Colors.black, minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.blue, // Set background color to blue
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Me',
            backgroundColor: Colors.blue, // Set background color to blue
          ),
        ],
        selectedItemColor: Colors.yellow, // Set selected item text and icon color to white
        unselectedItemColor: Colors.white, // Set unselected item text and icon color to white
        showUnselectedLabels: true, // Ensure unselected labels are visible
        type: BottomNavigationBarType.fixed, // Prevent icon shifting by keeping them fixed
        iconSize: 30.0, // Set icon size to a consistent value for all items
        backgroundColor: Colors.blue,
      ),
    );
  }
}
