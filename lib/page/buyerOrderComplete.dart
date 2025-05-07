import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BuyerOrderCompleteScreen extends StatefulWidget {
  final String orderId;  // Pass the order ID to this screen
  final String userId;   // Pass the user ID to this screen

  const BuyerOrderCompleteScreen({Key? key, required this.orderId, required this.userId}) : super(key: key);

  @override
  _BuyerOrderCompleteScreenState createState() => _BuyerOrderCompleteScreenState();
}

class _BuyerOrderCompleteScreenState extends State<BuyerOrderCompleteScreen> {
  late Future<DocumentSnapshot> _orderFuture;
  late Future<DocumentSnapshot> _completedTimestampFuture;
  late String _currentUserId;

  String? _orderStatus;
  Timestamp? _completedTime;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the order data from Firestore based on orderId
    _orderFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();

    // Fetch the completed timestamp from the 'completed' subcollection
    _completedTimestampFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection('completed')
        .doc(
        'completed_timestamp') // Assuming the document ID for the completed timestamp is 'completed_timestamp'
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _completedTime = data['completedTime'];
        });
      }
      return snapshot;
    });
  }

  // Method to build the order content
  Widget _buildOrderContent(Map<String, dynamic> orderData) {
    final paymentMethod = orderData['paymentMethod'];
    final collectionOption = orderData['collectionOption'];
    final List<dynamic> products = orderData['products'] ?? [];

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

  // Method to build the order status and completed time section
  Widget _buildOrderStatusAndCompletedTime() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Container(
        width: MediaQuery
            .of(context)
            .size
            .width * 0.9,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Order Status: Completed",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 10),
            Text(
              "Completed Time: ${_completedTime?.toDate().toString() ??
                  'No Completed Time'}",
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Complete'),
      ),
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

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildOrderContent(orderData),
                  const SizedBox(height: 3),
                  _buildOrderIdAndTime(orderData),
                  const SizedBox(height: 20),

                  // Display the completed time and order status
                  _buildOrderStatusAndCompletedTime(),

                  // Add Contact Seller button at the bottom
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Implement the logic for contacting the seller
                      // For example, navigate to the chat screen or show a dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Contacting seller...')),
                      );
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: const Text("Contact Seller"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black87, // Set background color
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius
                            .zero, // Square (no rounded corners)
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
