import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'order.dart';

class ServiceCheckoutScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> selectedItems;

  ServiceCheckoutScreen({
    required this.userId,
    required this.selectedItems,
  });

  @override
  _ServiceCheckoutScreenState createState() => _ServiceCheckoutScreenState();
}

class _ServiceCheckoutScreenState extends State<ServiceCheckoutScreen> {
  TextEditingController _messageController = TextEditingController();
  TextEditingController _locationController = TextEditingController();
  TextEditingController _destinationController = TextEditingController();
  TextEditingController _additionalInfoController = TextEditingController();

  String _message = '';

  Future<void> _saveServiceOrder() async {
    final firestore = FirebaseFirestore.instance;

    try {
      // Fetch the selected item
      var item = widget.selectedItems[0];
      final String listingId = item['listingId'];
      final String cartId = item['cartId'] ?? '';

      // Ensure cartId is valid
      if (cartId.isEmpty) {
        print('Cart ID is missing or invalid. Order cannot be placed.');
        return; // Optionally return or show a warning message
      }

      // Fetch the original listing data for additional details
      DocumentSnapshot listingSnapshot =
      await firestore.collection('listings').doc(listingId).get();

      String creatorId = listingSnapshot.get('userId');
      String description = listingSnapshot.get('description');
      String listingType = listingSnapshot.get('listingType');

      if (!listingSnapshot.exists) return;

      final listingData = listingSnapshot.data() as Map<String, dynamic>;

      // Convert price and totalPrice to double if they are strings
      double price = double.tryParse(item['price'].toString()) ?? 0.0;
      double totalPrice = double.tryParse(item['totalPrice'].toString()) ?? 0.0;


      // Create a new order document with service as a map
      DocumentReference orderRef = await firestore.collection('orders').add({
        'userId': widget.userId,
        'creatorId': creatorId,  // Store the creatorId from the listing
        'listingId': listingId,
        'listingType': listingType,
        'status': 'Pending for Approval',
        'orderTime': FieldValue.serverTimestamp(),
        'message': _message,
        'services': { // Store service details as a map
          'cartId': cartId,
          'serviceImage': item['image'],
          'serviceName': item['name'],
          'serviceDescription': description,
          'serviceTime': item['serviceTime'] ?? '',
          'serviceLocation': _locationController.text.trim(),
          'serviceDestination': _destinationController.text.trim(),
          'additionalNotes': _additionalInfoController.text.trim(),
          'price': price,
        },
        'totalPrice': totalPrice,
      });

      // Remove the items from the cartItems subcollection
      for (var item in widget.selectedItems) {
        await firestore.collection('users')
            .doc(widget.userId) // The user ID
            .collection('cartItems') // The cartItems subcollection
            .doc(cartId) // The unique cart item ID
            .delete();
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Service order placed successfully!')),
      );

      Navigator.pop(context, true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderScreen(orderId: orderRef.id),
        ),
      );
    } catch (e) {
      print('Order failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place service order. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Service Checkout'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.selectedItems.isNotEmpty) ...[
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.selectedItems.map((item) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['image'] ?? 'https://via.placeholder.com/150',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'No Name',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'Service Time: ${item['serviceTime']}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    // === Container for Message for Seller and Booking Details ===
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(top: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(5),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Message for Seller ListTile
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('Message for Seller', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(
                              _message.isEmpty ? 'Please leave a message' : _message,
                              style: TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                            trailing: Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[700]),
                            onTap: () {
                              // Show dialog to input message for seller
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    title: Text('Message for Seller'),
                                    content: TextField(
                                      controller: _messageController,
                                      decoration: InputDecoration(hintText: 'Write your message here'),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text('Cancel'),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            _message = _messageController.text;
                                          });
                                          Navigator.pop(context);
                                        },
                                        child: Text('Submit'),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                          Divider(thickness: 1, color: Colors.grey.shade300),  // Thin separator line

                          // === Booking Details (Text fields) ===
                          SizedBox(height: 10),
                          Text(
                            'Booking Details',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          _buildTextField(
                            controller: _locationController,
                            label: 'Location (e.g., pickup or meeting point)',
                            hint: 'Enter your current location or address',
                          ),
                          _buildTextField(
                            controller: _destinationController,
                            label: 'Destination (if applicable)',
                            hint: 'Enter destination (optional)',
                          ),
                          _buildTextField(
                            controller: _additionalInfoController,
                            label: 'Additional Notes',
                            hint: 'Mention any special requirements or info',
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.blueGrey[100],
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end, // Right aligned
            children: [
              ElevatedButton(
                onPressed: () {
                  _saveServiceOrder();
                },
                child: Text('Book Service'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5),
            borderSide: BorderSide(
            color: Colors.grey[100]!, // Slightly darker color when focused
            width: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}
