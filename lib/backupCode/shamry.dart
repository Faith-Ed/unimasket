// // Method to handle declining the order
// void _showDeclineDialog() {
//   showDialog(
//     context: context,
//     builder: (context) {
//       return AlertDialog(
//         title: Text("Provide Reason for Decline"),
//         content: TextField(
//           controller: _declineReasonController,
//           decoration: InputDecoration(hintText: "Enter reason here..."),
//           maxLines: 4,
//         ),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context); // Close the dialog
//             },
//             child: Text("Cancel"),
//           ),
//           TextButton(
//             onPressed: () {
//               // Validate decline reason
//               if (_declineReasonController.text.isNotEmpty) {
//                 // Get receiverId from order data
//                 _declineOrder();
//               } else {
//                 ScaffoldMessenger.of(context).showSnackBar(
//                   SnackBar(content: Text('Please provide a reason for declining.')),
//                 );
//               }
//             },
//             child: Text("Send"),
//           ),
//         ],
//       );
//     },
//   );
// }
//
// Future<void> _declineOrder() async {
//   try {
//     // Get receiverId from order data
//     final orderSnapshot = await FirebaseFirestore.instance
//         .collection('orders')
//         .doc(widget.orderId)
//         .get();
//     final receiverId = orderSnapshot.data()!['userId'];
//
//     // Get the current user's ID
//     final currentUserId = FirebaseAuth.instance.currentUser!.uid;
//
//     // Ensure that we get the same messageId regardless of the order of senderId and receiverId
//     String messageId = _getMessageId(currentUserId, receiverId);
//
//     // Get products array from the order
//     final List<dynamic> products = orderSnapshot.data()?['products'] ?? [];
//
//     // Update product status to 'Declined'
//     for (var i = 0; i < products.length; i++) {
//       if (products[i]['creatorId'] == currentUserId) {
//         // Update the product's status if the product's creatorId matches the current user's id
//         products[i]['status'] = 'Declined';
//       }
//     }
//
//     // Update the products array in the Firestore order document
//     await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
//       'status': 'Declined',  // Set the overall order status to Declined
//       'products': products,  // Update the products array with the modified product statuses
//     });
//
//     // Create a message in the 'messages' collection for this order
//     final currentTime = FieldValue.serverTimestamp();
//     final messageRef = FirebaseFirestore.instance.collection('messages').doc(messageId);
//
//     // Set or update the last message in the 'messages' collection
//     await messageRef.set({
//       'senderId': currentUserId,
//       'receiverId': receiverId,
//       'lastMessage': _declineReasonController.text,
//       'lastUpdated': currentTime,
//     }, SetOptions(merge: true));
//
//     // Add the decline message to the 'chats' subcollection under the 'messages' collection
//     await messageRef.collection('chats').add({
//       'senderId': currentUserId,
//       'receiverId': receiverId,
//       'content': _declineReasonController.text,
//       'timestamp': currentTime,
//       'isDeleted': false, // mark as not deleted initially
//       'orderId': widget.orderId,
//     });
//
//     // Save the decline reason in the decline_reason subcollection under orders
//     await FirebaseFirestore.instance
//         .collection('orders')
//         .doc(widget.orderId)
//         .collection('decline_reason')
//         .doc('reason')
//         .set({
//       'reason': _declineReasonController.text,
//       'declinedBy': currentUserId,
//       'timestamp': currentTime,
//     });
//
//     // Close the dialog after the message has been saved
//     Navigator.pop(context);
//   } catch (e) {
//     print("Error declining order: $e");
//   }
// }