import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'OrderUpdatesScreen.dart';
import 'bottomNavigationBar.dart';
import 'cart.dart';
import 'chatBot.dart';
import 'create_listing.dart';
import 'home.dart';
import 'listingUpdates.dart'; // Assuming you have a chatBot page

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _auth = FirebaseAuth.instance;
  late User _user;
  int _newNotificationsCount = 0;
  int _newOrderNotificationsCount = 0;
  int _currentIndex = 2;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _fetchNotificationsCount();
  }

  // Fetch the number of new 'new_listing' notifications
  Future<void> _fetchNotificationsCount() async {
    // Query the 'notifications' subcollection under the current user to get the count of new listings
    FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)  // Reference to the current user's document
        .collection('notifications')  // 'notifications' subcollection
        .where('type', isEqualTo: 'new_listing')
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _newNotificationsCount = snapshot.docs.length; // Update the count
      });
    });

    // Query the 'notifications' subcollection for order updates
    FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)  // Reference to the current user's document
        .collection('notifications')  // 'notifications' subcollection
        .where('type', isEqualTo: 'order_placed')
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _newOrderNotificationsCount = snapshot.docs.length; // Update the count for order updates
      });
    });

    // Fetch notifications for 'new_order'
    FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)  // Reference to the current user's document
        .collection('notifications')  // 'notifications' subcollection
        .where('type', isEqualTo: 'new_order')
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _newOrderNotificationsCount += snapshot.docs.length; // Update the count for new_order notifications
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to the CartScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(userId: FirebaseAuth.instance.currentUser!.uid),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 15),
            child: Tooltip(
              message: 'Sell',  // The label to show when user taps/hover
              child: IconButton(
                icon: Icon(
                  Icons.sell, // Use sell icon for the button
                  size: 22,
                ),
                onPressed: () {
                  // Navigate to CreateListingScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CreateListingScreen()),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Notification Container
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  // Round Shape Image with Listing Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue, // Background color for the circle
                    ),
                    child: Icon(
                      Icons.list,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Label "Listing Updates"
                  Expanded(
                    child: Text(
                      "Listing Updates",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Number of new notifications
                  _newNotificationsCount > 0
                      ? Text(
                    _newNotificationsCount.toString(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                      : Container(),
                  SizedBox(width: 8),
                  // Right Arrow Icon with Navigation
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 20),
                    onPressed: () async {
                      // Reset the notifications count in Firestore (mark them as read or clear them)
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(_user.uid)  // Reference to the current user's document
                          .collection('notifications')  // Notifications subcollection
                          .where('type', isEqualTo: 'new_listing')
                          .get()
                          .then((snapshot) {
                        for (var doc in snapshot.docs) {
                          doc.reference.update({'isSeen': true}); // Mark as read
                        }
                      });

                      // Update the UI to reflect that there are no new notifications
                      setState(() {
                        _newNotificationsCount = 0; // Reset notification count
                      });

                      // Navigate to Listing Updates Page when right arrow is clicked
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ListingUpdatesScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),

            // Notification Container for Order Updates (newly added container)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  // Round Shape Image with Order Icon
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green, // Background color for the circle
                    ),
                    child: Icon(
                      Icons.shopping_cart,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  SizedBox(width: 12),
                  // Label "Order Updates"
                  Expanded(
                    child: Text(
                      "Order Updates",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Number of new notifications
                  _newOrderNotificationsCount > 0
                      ? Text(
                    _newOrderNotificationsCount.toString(),
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  )
                      : Container(),
                  SizedBox(width: 8),
                  // Right Arrow Icon with Navigation
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 20),
                    onPressed: () async {
                      try {
                        // Mark 'order_placed' notifications as read
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user.uid)  // Reference to the current user's document
                            .collection('notifications')  // Notifications subcollection
                            .where('type', isEqualTo: 'order_placed')
                            .get()
                            .then((snapshot) {
                          for (var doc in snapshot.docs) {
                            doc.reference.update({'isSeen': true}); // Mark as read
                          }
                        });

                        // Mark 'new_order' notifications as read
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(_user.uid)  // Reference to the current user's document
                            .collection('notifications')  // Notifications subcollection
                            .where('type', isEqualTo: 'new_order')
                            .get()
                            .then((snapshot) {
                          for (var doc in snapshot.docs) {
                            doc.reference.update({'isSeen': true}); // Mark as read
                          }
                        });

                        // Update the UI to reflect that there are no new notifications
                        setState(() {
                          _newOrderNotificationsCount = 0; // Reset notification count
                        });

                        // Navigate to the Order Updates Page when the right arrow is clicked
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => OrderUpdatesScreen(),
                          ),
                        );
                      } catch (e) {
                        print("Error marking notifications as read: $e");
                      }
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 50),

            // "Go Shopping Now" Button
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
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open Chatbot
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatBot()),
          );
        },
        child: Icon(Icons.flutter_dash),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
