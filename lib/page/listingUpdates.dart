import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:redofyp/page/viewListingDetails.dart';

class ListingUpdatesScreen extends StatefulWidget {
  @override
  _ListingUpdatesScreenState createState() => _ListingUpdatesScreenState();
}

class _ListingUpdatesScreenState extends State<ListingUpdatesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  String? _profileImageUrl;
  String? _userName;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
  }

  // Save the selected state of a tile to Firestore in the notifications subcollection
  Future<void> _saveTileSelectionState(String notificationId) async {
    if (notificationId.isEmpty) {
      print('Error: notificationId is empty or null');
      return;  // Exit if notificationId is invalid
    }

    try {
      // Update the 'isSelected' field to true in the user's notifications subcollection when the notification is clicked
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid) // Reference to the current user's document
          .collection('notifications') // Notifications subcollection under the user
          .doc(notificationId) // Reference to the specific notification document
          .update({
        'isSelected': true, // Mark as selected (read)
      });

      print('Notification with ID: $notificationId is successfully marked as selected.');
    } catch (e) {
      print('Error saving tile selection state: $e');
    }
  }

  Future<Map<String, dynamic>> _getUserDetails(String listingId) async {
    try {
      DocumentSnapshot listingDoc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .get();

      if (listingDoc.exists) {
        var listingData = listingDoc.data() as Map<String, dynamic>;
        String userId = listingData['userId'];

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          var userData = userDoc.data() as Map<String, dynamic>;
          String fullName = userData['fullname'] ?? 'No name';
          String profileImageUrl = '';

          final photoDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('photo_profile')
              .doc('profile')
              .get();

          if (photoDoc.exists && photoDoc['url'] != null) {
            profileImageUrl = photoDoc['url'] ?? '';
          }

          return {'fullName': fullName, 'profileImage': profileImageUrl};
        }
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }

    return {'fullName': 'Unknown', 'profileImage': ''};
  }


  // Function to build the notification list
  Widget _buildNotificationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid) // Reference to the current user's document
          .collection('notifications') // Notifications subcollection under the user
          .where('type', isEqualTo: 'new_listing')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading notifications'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No new notifications'));
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            var notification = notifications[index].data() as Map<String, dynamic>;
            var notificationId = notifications[index].id;
            var listingId = notification['listingId'] ?? '';
            var message = notification['message'] ?? 'No message';
            var timestamp = notification['timestamp'];
            String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());
            bool isSelected = notification['isSelected'] ?? false;

            // Fetch listing name using listingId
            return FutureBuilder<Map<String, dynamic>>(
              future: FirebaseFirestore.instance
                  .collection('listings')
                  .doc(listingId)
                  .get()
                  .then((listingDoc) {
                return {'listingName': listingDoc['name'] ?? 'Unnamed Listing'};
              }),
              builder: (context, listingSnapshot) {
                if (listingSnapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: Text('Loading listing name...'),
                  );
                }
                if (listingSnapshot.hasError) {
                  return ListTile(
                    title: Text('Error fetching listing name'),
                  );
                }

                String listingName = listingSnapshot.data?['listingName'] ?? 'Unknown Listing';

                return FutureBuilder<Map<String, dynamic>>(
                  future: _getUserDetails(_user.uid),
                  builder: (context, userSnapshot) {
                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: Text('Loading user info...'),
                      );
                    }
                    if (userSnapshot.hasError) {
                      return ListTile(
                        title: Text('Error fetching user info'),
                      );
                    }

                    String fullName = userSnapshot.data?['fullname'] ?? 'No Name';
                    String profileImageUrl = userSnapshot.data?['profileImage'] ?? '';

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : null,
                      ),
                      title: Text(fullName),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message),
                          Text(
                            listingName,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            formattedTime,
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      tileColor: isSelected ? Colors.white : Colors.red[100], // Change color based on selection
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        // Mark the notification as read and update the selection in Firestore
                        _saveTileSelectionState(notificationId);

                        // Navigate to the specific listing details page
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ViewListingDetailsScreen(listingId: listingId),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listing Updates'),
      ),
      body: _buildNotificationList(),
    );
  }
}

