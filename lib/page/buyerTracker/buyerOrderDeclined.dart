import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redofyp/widgets/pageDesign.dart';

import '../../widgets/chatSellerButton.dart';

class BuyerOrderDeclineScreen extends StatefulWidget {
  final String orderId;  // Pass the order ID to this screen
  final String userId;   // Pass the user ID to this screen

  const BuyerOrderDeclineScreen({Key? key, required this.orderId, required this.userId}) : super(key: key);

  @override
  _BuyerOrderDeclineScreenState createState() => _BuyerOrderDeclineScreenState();
}

class _BuyerOrderDeclineScreenState extends State<BuyerOrderDeclineScreen> {
  late Future<DocumentSnapshot> _orderFuture;
  late String _currentUserId;
  String? _declineMessage;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the order data from Firestore based on orderId
    _orderFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();

    // Fetch the decline message from the 'decline_reason' subcollection
    _fetchDeclineMessage();
  }

  Future<void> _fetchDeclineMessage() async {
    try {
      // Fetch the decline message from the 'decline_reason' subcollection under the order
      final declineSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .collection('decline_reason')
          .doc('reason') // Assuming the document ID for the reason is 'reason'
          .get();

      // Check if the declineSnapshot exists and contains data
      if (declineSnapshot.exists) {
        final declineData = declineSnapshot.data();

        // Check if declineData is valid and a Map<String, dynamic>
        if (declineData != null && declineData is Map<String, dynamic>) {
          setState(() {
            _declineMessage = declineData['reason'] ??
                'No decline reason provided'; // Use fallback if null
          });
        } else {
          setState(() {
            _declineMessage =
            'No decline reason available'; // Provide fallback message
          });
        }
      } else {
        setState(() {
          _declineMessage =
          'No decline reason provided'; // Provide fallback if document doesn't exist
        });
      }
    } catch (e) {
      print("Error fetching decline reason: $e");
      setState(() {
        _declineMessage =
        'Error fetching decline reason'; // Set fallback error message
      });
    }
  }

  // Method to build the order content
  Widget _buildOrderContent(Map<String, dynamic> orderData) {
    final status = orderData['status'];
    final paymentMethod = orderData['paymentMethod'];
    final collectionOption = orderData['collectionOption'];
    final List<dynamic> products = orderData['products'] ?? [];
    final Map service = orderData['services'] ?? {}; // Single service map
    final creatorId = orderData['creatorId'];

    double total = 0.0; // To calculate total order cost

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display filtered products (products that belong to the current user)
          if (products.isNotEmpty)
            Container(
              width: MediaQuery
                  .of(context)
                  .size
                  .width * 0.9,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: products.map<Widget>((item) {
                      double itemTotal = item['orderQuantity'] *
                          item['itemPrice'];
                      total += itemTotal;
                      return Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['itemImage'] ??
                                      'https://via.placeholder.com/150',
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['itemName'] ?? 'No Name',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "Quantity: ${item['orderQuantity'] ?? 0}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "Price: RM ${item['itemPrice'] ?? 0.0}",
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w400,
                                          fontSize: 14),
                                    ),
                                    SizedBox(height: 5),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                        ],
                      );
                    }).toList(),
                  ),
                  const Divider(),
                  // Order Summary: Order Total
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Collection Option: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold), // Bold label
                            ),
                            Text(
                              '$collectionOption',
                              style: TextStyle(fontWeight: FontWeight
                                  .normal), // Normal value
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Method: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold), // Bold label
                            ),
                            Text(
                              '$paymentMethod',
                              style: TextStyle(fontWeight: FontWeight
                                  .normal), // Normal value
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        const Divider(),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Total: ',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold), // Bold label
                            ),
                            Text(
                              'RM ${total.toStringAsFixed(2)}',
                              style: TextStyle(fontWeight: FontWeight.w500,
                                  fontSize: 18), // Normal value
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  )
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Order ID and Time Section (Container 2)
  Widget _buildOrderIdAndTime(Map<String, dynamic> orderData) {
    return Container(
      width: MediaQuery
          .of(context)
          .size
          .width * 0.9,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order ID:'),
              Text(widget.orderId),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Time:'),
              Text(orderData['orderTime']?.toDate().toString() ?? 'No Time'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: customAppBar('Order Declined'),
      body: FutureBuilder<DocumentSnapshot>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Order not found"));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>?;

          if (orderData == null) {
            return const Center(child: Text("Order data is unavailable"));
          }

          // Get listingId from products if available
          String? listingId;
          if (orderData['products'] != null &&
              (orderData['products'] as List).isNotEmpty) {
            listingId = orderData['products'][0]['listingId'];
          }

          // Get listingId from services (outside the map)
          String? serviceListingId = orderData['listingId'] ?? orderData?['services']?['listingId'];

          // Determine which listingId to use for chat button
          String? chatListingId = listingId ?? serviceListingId;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildOrderContent(orderData),
                  const SizedBox(height: 3),
                  _buildOrderIdAndTime(orderData),
                  const SizedBox(height: 20),

                  // Display the decline message below the order details
                  if (_declineMessage != null && _declineMessage!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 5)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Decline Reason:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _declineMessage ?? 'No decline reason provided',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 50),

                  // Contact Seller Button
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: chatListingId != null
                        ? ChatSellerButton(listingId: chatListingId)
                        : ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Listing ID not found. Cannot chat with seller.')),
                        );
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Contact Seller"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,
                        foregroundColor: Colors.white,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

