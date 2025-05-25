import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../page/seller/sellerDecline.dart';
import '../services/notification_service.dart';

class DeclineButton extends StatelessWidget {
  final String orderId;

  DeclineButton({Key? key, required this.orderId}) : super(key: key);

  final TextEditingController _declineReasonController = TextEditingController();
  late String _currentUserId;

  // Generate chatId by sorting user IDs and joining with underscore
  String _generateChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // Show Decline Reason Dialog
  void _showDeclineDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Provide Reason for Decline"),
          content: TextField(
            controller: _declineReasonController,
            decoration: InputDecoration(hintText: "Enter reason here..."),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                if (_declineReasonController.text.isNotEmpty) {
                  // Trigger the decline order function
                  _declineOrder(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide a reason for declining.')),
                  );
                }
              },
              child: Text("Send"),
            ),
          ],
        );
      },
    );
  }

  // Decline Order Method
  Future<void> _declineOrder(BuildContext context) async {
    try {
      final orderSnapshot = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      final orderData = orderSnapshot.data()!;
      final receiverId = orderData['userId'] as String;
      _currentUserId = FirebaseAuth.instance.currentUser!.uid;

      String chatId = _generateChatId(_currentUserId, receiverId);

      final List<dynamic> products = orderData['products'] ?? [];

      // Update product status to 'Declined'
      for (var product in products) {
        if (product['creatorId'] == _currentUserId) {
          product['status'] = 'Declined';
        }
      }

      // Update the products array in the Firestore order document
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'Declined',
        'products': products,
      });

      // Reset isSeen = false for notifications of current user related to this order
      final currentUserNotifQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)
          .collection('notifications')
          .where('orderId', isEqualTo: orderId)
          .get();

      for (var doc in currentUserNotifQuery.docs) {
        await doc.reference.update({'isSeen': false});
      }

// Send notification using NotificationService for the receiver (buyer)
      await NotificationService.sendNotificationToUser(
        userId: receiverId,
        orderId: orderId,
        type: 'order_declined',
      );

      final currentTime = FieldValue.serverTimestamp();
      final messageRef = FirebaseFirestore.instance.collection('messages').doc(chatId);

      // Update chat document with last message
      await messageRef.set({
        'participants': [_currentUserId, receiverId],
        'lastMessage': _declineReasonController.text,
        'lastUpdated': currentTime,
      }, SetOptions(merge: true));

      // Add decline reason message to messages subcollection
      await messageRef.collection('messages').add({
        'senderId': _currentUserId,
        'message': _declineReasonController.text,
        'timestamp': currentTime,
        'isDeleted': false,
        'orderId': orderId,
        'seenBy': [_currentUserId],
      });

      // Save decline reason in orders subcollection
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('decline_reason')
          .doc('reason')
          .set({
        'reason': _declineReasonController.text,
        'declinedBy': _currentUserId,
        'timestamp': currentTime,
      });

      Navigator.pop(context);

      // Navigate to SellerDeclineScreen, passing the orderId
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DeclineOrderScreen(orderId: orderId),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order declined and information sent.')),
      );
    } catch (e) {
      print("Error declining order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to decline order. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        _showDeclineDialog(context); // Show the decline dialog when the button is pressed
      },
      child: Text('Decline'),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(5.0),
        ),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }
}
