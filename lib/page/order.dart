import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class OrderScreen extends StatefulWidget {
  final String orderId;

  const OrderScreen({super.key, required this.orderId});

  @override
  State<OrderScreen> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderScreen> {
  late Future<DocumentSnapshot> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Order Details")),
      body: FutureBuilder<DocumentSnapshot>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          // Access products and services fields separately
          final List products = data['products'] ?? [];
          final Map<String, dynamic> services = data['services'] ?? {};

          final String status = data['status'] ?? 'Unknown';
          final Timestamp? orderTimestamp = data['orderTime'];
          final String orderDate = formatTimestamp(orderTimestamp);
          final String orderId = snapshot.data!.id;

          // Calculate the total price of the order
          double totalPrice = 0.0;
          for (var product in products) {
            totalPrice += product['totalPrice'] ?? 0.0;
          }
          if (services.isNotEmpty) {
            totalPrice += services['price'] ?? 0.0;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status
                  const Text(
                    "ORDER STATUS:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  ...products.map((product) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        children: [
                          // Product Image
                          Image.network(
                            product['itemImage'],
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product['itemName'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(product['itemDescription'] ?? ''),
                                Text("Quantity: ${product['orderQuantity']}"),
                                Text("Total: RM ${product['totalPrice']}"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  // Display Service Details (if service exists)
                  if (services.isNotEmpty) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        children: [
                          // Service Image
                          if (services['serviceImage'] != null && services['serviceImage'].toString().isNotEmpty)
                            Image.network(
                              services['serviceImage'],
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
                            )
                          else
                            Container(
                              height: 70,
                              width: 70,
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          const SizedBox(width: 12),
                          // Service Details Text
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(services['serviceName'] ?? 'No Name', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(services['serviceDescription'] ?? 'No Description'),
                                Text("Service Time: ${services['serviceTime'] ?? 'N/A'}"),
                                Text("Location: ${services['serviceLocation'] ?? 'N/A'}"),
                                Text("Destination: ${services['serviceDestination'] ?? 'N/A'}"),
                                Text("Additional Notes: ${services['additionalNotes'] ?? 'N/A'}"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Total
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Overall Total:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "RM ${totalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Order Info
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Order No: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextSpan(
                          text: widget.orderId,
                          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Order Date: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextSpan(
                          text: orderDate,
                          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Contact Seller Button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // implement logic
                      },
                      icon: const Icon(Icons.chat_bubble_outline),
                      label: const Text("Contact Seller"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black87,  // Set background color
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.zero, // Square (no rounded corners)
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



