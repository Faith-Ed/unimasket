import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ToApproveScreen extends StatefulWidget {
  final String userId; // Current user ID

  const ToApproveScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _ToApproveScreenState createState() => _ToApproveScreenState();
}

class _ToApproveScreenState extends State<ToApproveScreen> {
  late Future<QuerySnapshot> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _getOrders();
  }

  // Fetch orders where the creatorId is the same as the current user
  void _getOrders() {
    setState(() {
      _ordersFuture = FirebaseFirestore.instance
          .collection('orders')
          .where('creatorId', isEqualTo: widget.userId)
          .get();
    });
  }

  // Format timestamp
  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders to Approve"),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders to approve."));
          }

          final orders = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: orders.map((orderDoc) {
                final orderData = orderDoc.data() as Map<String, dynamic>;
                final orderId = orderDoc.id;
                final List items = orderData['products'] ?? [];
                final totalAmount = orderData['totalAmount'] ?? 0.0;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display either product or service details
                      ...items.map((item) {
                        if (item['listingType'] == 'product') {
                          return Row(
                            children: [
                              // Product Image
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
                              // Product details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['itemName'] ?? 'No Name',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text("Quantity: ${item['orderQuantity']}"),
                                    Text("Price: RM ${item['itemPrice']}"),
                                    Text("Collection Option: ${item['collectionOption']}"),
                                    if (item['collectionOption'] == 'Delivery')
                                      Text("Location: ${item['deliveryLocation']}"),
                                    Text("Payment Method: ${item['paymentMethod']}"),
                                  ],
                                ),
                              ),
                            ],
                          );
                        } else if (item['listingType'] == 'service') {
                          return Row(
                            children: [
                              // Service Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['serviceImage'] ?? 'https://via.placeholder.com/150',
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Service details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['serviceName'] ?? 'No Name',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    Text("Service Time: ${item['serviceTime']}"),
                                    Text("Location: ${item['serviceLocation']}"),
                                    Text("Destination: ${item['serviceDestination']}"),
                                    Text("Additional Notes: ${item['additionalNotes']}"),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }
                        return Container(); // If it's neither, just return an empty container
                      }).toList(),

                      // View More Button with down arrow, centered
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            // Navigate to OrderScreen when "View More" is clicked
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Text("View More"),
                              Icon(Icons.arrow_drop_down, size: 16),
                            ],
                          ),
                        ),
                      ),

                      // Display total items and total price for the order
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Label for total number of items (unbold)
                          Text(
                            'Total ${items.length} items',
                            style: const TextStyle(fontWeight: FontWeight.normal),
                          ),
                          const SizedBox(width: 10),
                          // Price in bold
                          Text(
                            'RM ${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}
