import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/ai_chatbot_state.dart';
import '../../widgets/floatingButton.dart';
import 'OrderUpdatesScreen.dart';
import '../../widgets/bottomNavigationBar.dart';
import '../cart/cart.dart';
import '../chatBot.dart';
import '../listing/create_listing.dart';
import '../main/home.dart';
import 'listingUpdates.dart'; // Assuming you have a chatBot page
import 'dart:async';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _auth = FirebaseAuth.instance;
  late User _user;
  int _newListingNotificationsCount = 0;
  int _newOrderNotificationsCount = 0;
  int _currentIndex = 2;

  late StreamSubscription<QuerySnapshot> _listingNotifSub;
  late StreamSubscription<QuerySnapshot> _orderNotifSub;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
    _subscribeToNotifications();
  }

  void _subscribeToNotifications() {
    // Listen for new_listing notifications (flat structure)
    _listingNotifSub = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('notifications')
        .where('type', isEqualTo: 'new_listing')
        .where('isSeen', isEqualTo: false)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _newListingNotificationsCount = snapshot.docs.length;
      });
    });

    // Listen for order-related notifications (order_placed + new_order)
    _orderNotifSub = FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('notifications')
        .where('isSeen', isEqualTo: false)
        .where('type', whereIn: [
      'order_accepted',
      'order_declined',
      'order_completed',
      'new_order', // keep new_order if needed, add others as well
      'order_placed',
    ])
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _newOrderNotificationsCount = snapshot.docs.length;
      });
    });
  }

  @override
  void dispose() {
    _listingNotifSub.cancel();
    _orderNotifSub.cancel();
    super.dispose();
  }

  Future<void> _markListingNotificationsRead() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('notifications')
        .where('type', isEqualTo: 'new_listing')
        .where('isSeen', isEqualTo: false)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.update({'isSeen': true});
    }
  }

  Future<void> _markOrderNotificationsRead() async {
    final batch = FirebaseFirestore.instance.batch();

    final orderTypes = [
      'order_placed',
      'new_order',
      'order_accepted',
      'order_declined',
      'order_completed',
    ];
    for (var type in orderTypes) {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('notifications')
          .where('type', isEqualTo: type)
          .where('isSeen', isEqualTo: false)
          .get();

      for (var doc in snapshot.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }
    }

    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          child: AppBar(
            toolbarHeight: 80,
            title: Text('Notifications', style: TextStyle(color: Colors.white)),
            backgroundColor: CupertinoColors.systemYellow,
            actions: [
              IconButton(
                icon: Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CartScreen(userId: _user.uid),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Tooltip(
                  message: 'Sell',
                  child: IconButton(
                    icon: Icon(Icons.sell, size: 22),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => CreateListingScreen()),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Listing Updates Container
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: Icon(Icons.list, color: Colors.white, size: 30),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Listing Updates",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),

                  // Badge for unread new listing notifications
                  if (_newListingNotificationsCount > 0)
                    Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _newListingNotificationsCount.toString(),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),

                  SizedBox(width: 8),

                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 20),
                    onPressed: () async {
                      await _markListingNotificationsRead();
                      setState(() {
                        _newListingNotificationsCount = 0;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ListingUpdatesScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 10),

            // Order Updates Container (unchanged)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.green,
                    ),
                    child:
                    Icon(Icons.shopping_cart, color: Colors.white, size: 30),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "Order Updates",
                      style:
                      TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_newOrderNotificationsCount > 0)
                    Container(
                      padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _newOrderNotificationsCount.toString(),
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.arrow_forward_ios, size: 20),
                    onPressed: () async {
                      await _markOrderNotificationsRead();
                      setState(() {
                        _newOrderNotificationsCount = 0;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => OrderUpdatesScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),

            SizedBox(height: 50),

            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                      (route) => false,
                );
              },
              child: Text('Go Shopping Now!'),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.black,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),

      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: AiChatbotState().isEnabled,
        builder: (context, isEnabled, _) {
          return isEnabled ? CustomFloatingActionButton() : SizedBox.shrink();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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

