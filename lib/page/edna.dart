// Future<void> _saveServiceOrder() async {
//   final firestore = FirebaseFirestore.instance;
//
//   try {
//     // Create a new order document
//     DocumentReference orderRef = await firestore.collection('orders').add({
//       'buyerId': widget.userId,
//       'createdAt': Timestamp.now(),
//       'type': 'service',
//       'status': 'Pending for Approval',
//     });
//
//     // Save each selected item under the order
//     for (var item in widget.selectedItems) {
//       final listingId = item['id'];
//
//       // Fetch the original listing data for additional details
//       DocumentSnapshot listingSnapshot =
//       await firestore.collection('listings').doc(listingId).get();
//
//       if (!listingSnapshot.exists) continue;
//
//       final listingData = listingSnapshot.data() as Map<String, dynamic>;
//
//       final itemData = {
//         'orderId': orderRef.id,
//         'listingId': listingId,
//         'listingCreatorId': listingData['userId'] ?? '',
//         'buyerId': widget.userId,
//         'status': 'Pending for Approval',
//         'orderTime': Timestamp.now(),
//         'itemImage': item['image'] ?? '',
//         'itemName': item['name'] ?? '',
//         'itemDetails': listingData['description'] ?? '',
//         'serviceTime': item['serviceTime'] ?? '',
//         'messageForSeller': _message,
//         'location': _locationController.text.trim(),
//         'destination': _destinationController.text.trim(),
//         'additionalNotes': _additionalInfoController.text.trim(),
//         'orderQuantity': item['quantity'] ?? 1,
//         'totalPrice': (item['price'] ?? 0) * (item['quantity'] ?? 1),
//       };
//
//       // Store each service item under the order
//       await orderRef.collection('service_order').add(itemData);
//     }
//
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text('Order placed successfully!')),
//     );
//
//     Navigator.pushReplacement(
//       context,
//       MaterialPageRoute(
//         builder: (context) => OrderScreen(orderId: orderRef.id),
//       ),
//     );
//   } catch (e) {
//     print('Order failed: $e');
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text('Failed to place order. Try again.'),
//         backgroundColor: Colors.red,
//       ),
//     );
//   }
// }