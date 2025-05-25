import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/pageDesign.dart';

class DeclineOrderScreen extends StatefulWidget {
  final String orderId;  // Pass the order ID to this screen

  const DeclineOrderScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _DeclineOrderScreenState createState() => _DeclineOrderScreenState();
}

class _DeclineOrderScreenState extends State<DeclineOrderScreen> {
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

    // Fetch the decline message from the decline_reason subcollection
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

      if (declineSnapshot.exists) {
        final declineData = declineSnapshot.data() as Map<String, dynamic>;
        setState(() {
          _declineMessage = declineData['reason']; // Set the decline reason
        });
      } else {
        setState(() {
          _declineMessage = 'No decline reason provided'; // Fallback message
        });
      }
    } catch (e) {
      print("Error fetching decline reason: $e");
    }
  }

  // Method to build the order content
  Widget _buildOrderContent(Map<String, dynamic> orderData) {
    final paymentMethod = orderData['paymentMethod'] ?? 'N/A';
    final collectionOption = orderData['collectionOption'] ?? 'N/A';
    final List<dynamic> products = orderData['products'] ?? [];
    final Map<String, dynamic> service = Map<String, dynamic>.from(orderData['services'] ?? {});

    double totalProductsPrice = 0.0;
    for (var item in products) {
      final quantity = item['orderQuantity'] ?? 0;
      final price = (item['itemPrice'] ?? 0.0).toDouble();
      totalProductsPrice += quantity * price;
    }

    double servicePrice = 0.0;
    if (orderData['totalPrice'] != null) {
      servicePrice = (orderData['totalPrice'] as num).toDouble();
    }

    double overallTotal = totalProductsPrice + servicePrice;

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 5)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Products section
            if (products.isNotEmpty) ...[
              Column(
                children: products.map<Widget>((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 15),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            item['itemImage'] ?? 'https://via.placeholder.com/150',
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Quantity: ${item['orderQuantity'] ?? 0}",
                                style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "Price: RM ${item['itemPrice']?.toStringAsFixed(2) ?? '0.00'}",
                                style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Collection Option: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(collectionOption, style: const TextStyle(fontWeight: FontWeight.normal)),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Method: ', style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(paymentMethod, style: const TextStyle(fontWeight: FontWeight.normal)),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(),
              const SizedBox(height: 8),
            ],

            // Service section
            if (service.isNotEmpty) ...[
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      service['serviceImage'] ?? 'https://via.placeholder.com/150',
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
                          service['serviceName'] ?? 'No Name',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          "Service Time: ${service['serviceTime'] ?? 'N/A'}",
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Service Destination:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(service['serviceDestination'] ?? 'N/A', textAlign: TextAlign.right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Service Location:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(service['serviceLocation'] ?? 'N/A', textAlign: TextAlign.right),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Additional Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                  Expanded(
                    child: Text(service['additionalNotes'] ?? 'N/A', textAlign: TextAlign.right),
                  ),
                ],
              ),
              const Divider(height: 30),
            ],

            // Overall order total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Order Total: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Text('RM ${overallTotal.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 5),
          ],
        ),
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

          if (!snapshot.hasData) {
            return const Center(child: Text("Order not found"));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;

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
                  if (_declineMessage != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Container(
                        width: MediaQuery
                            .of(context)
                            .size
                            .width * 0.9, // Set width to 90% of screen width
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(
                              color: Colors.black12, blurRadius: 5)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Decline Reason:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _declineMessage!,
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
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
