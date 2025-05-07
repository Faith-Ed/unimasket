import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:redofyp/page/toApprove.dart';
import 'order.dart';

class OrderUpdatesScreen extends StatefulWidget {
  @override
  _OrderUpdatesScreenState createState() => _OrderUpdatesScreenState();
}

class _OrderUpdatesScreenState extends State<OrderUpdatesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Updates'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_user.uid)
              .collection('notifications')
              .where('type', whereIn: ['order_placed', 'new_order']) // Fetch both order types
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error fetching notifications'));
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
                var status = notification['status'] ?? 'Pending';
                var timestamp = notification['timestamp'];
                var notificationType = notification['type'] ?? '';
                String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate());

                // Debug prints
                print('Notification ID: $notificationId');
                print('Listing ID: $listingId');
                print('Message: $message');
                print('Status: $status');
                print('Notification Type: $notificationType');
                print('Timestamp: $formattedTime');

                // Fetch product details from order collection using listingId
                return StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user.uid) // Reference to the current user's document
                      .collection('notifications') // Notifications subcollection under the user
                      .doc(notificationId) // Reference to the specific notification document
                      .snapshots(),
                  builder: (context, notificationSnapshot) {
                    if (notificationSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(title: Text('Loading notification details...'));
                    }
                    if (notificationSnapshot.hasError) {
                      return ListTile(title: Text('Error fetching notification details'));
                    }

                    if (!notificationSnapshot.hasData || !notificationSnapshot.data!.exists) {
                      return ListTile(title: Text('No data found for this notification.'));
                    }

                    var notificationData = notificationSnapshot.data!.data() as Map<String, dynamic>;

                    var message = notificationData['message'] ?? 'No message available.';
                    var notificationType = notificationData['type'] ?? '';
                    var listingId = notificationData['listingId'] ?? '';

                    // Fetch product details from the listings collection using listingId
                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance.collection('listings').doc(listingId).get(),
                      builder: (context, listingSnapshot) {
                        if (listingSnapshot.connectionState == ConnectionState.waiting) {
                          return ListTile(title: Text('Loading listing details...'));
                        }
                        if (listingSnapshot.hasError) {
                          return ListTile(title: Text('Error fetching listing details'));
                        }

                        if (!listingSnapshot.hasData || !listingSnapshot.data!.exists) {
                          return ListTile(title: Text('No data found for this listing.'));
                        }

                        var listingData = listingSnapshot.data!.data() as Map<String, dynamic>;

                        var itemImage = listingData['image'] ?? 'https://via.placeholder.com/150';
                        var status = listingData['status'] ?? 'Pending';

                        String formattedTime = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());

                        return ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 10.0),
                          leading: Image.network(itemImage, width: 50, height: 50, fit: BoxFit.cover),
                          title: Text('Order $status'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(message),
                              Text(
                                formattedTime,
                                style: TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.arrow_forward_ios),
                            onPressed: () {
                              // Navigate based on notification type
                              if (notificationType == 'order_placed') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => OrderScreen(orderId: listingId),
                                  ),
                                );
                              } else if (notificationType == 'new_order') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ToApproveScreen(orderId: listingId),
                                  ),
                                );
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
