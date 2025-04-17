import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'order.dart';  // Import OrderScreen

class PendingOrderScreen extends StatefulWidget {
  final String userId;

  const PendingOrderScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<PendingOrderScreen> createState() => _PendingOrderScreenState();
}

class _PendingOrderScreenState extends State<PendingOrderScreen> with SingleTickerProviderStateMixin {
  late Future<QuerySnapshot> _ordersFuture;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this); // 3 tabs for Pending, Accepted, and Completed
    _getOrders('Pending for Approval'); // Default fetch for Pending orders
  }

  void _getOrders(String status) {
    setState(() {
      _ordersFuture = FirebaseFirestore.instance
          .collection('orders')
          .where('userId', isEqualTo: widget.userId)
          .where('status', isEqualTo: status) // Fetch based on selected status
          .get();
    });
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Orders"),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            // Change the query based on tab selection
            if (index == 0) {
              _getOrders('Pending for Approval');
            } else if (index == 1) {
              _getOrders('Accepted');
            } else if (index == 2) {
              _getOrders('Completed');
            }
          },
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Accepted"),
            Tab(text: "Completed"),
          ],
        ),
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: _ordersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No orders found."));
          }

          final orders = snapshot.data!.docs;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: orders.map((orderDoc) {
                final orderData = orderDoc.data() as Map<String, dynamic>;
                final orderId = orderDoc.id;

                // Fetch products (array) and services (single object) separately
                final List products = List.from(orderData['products'] ?? []);
                final dynamic service = orderData['services'] ?? null;
                final totalAmount = orderData['totalAmount'] ?? 0.0;

                // Group the products by itemName and sum their quantities and prices
                var groupedProducts = <String, Map<String, dynamic>>{};
                for (var product in products) {
                  final productName = product['itemName'] ?? 'Unknown';
                  if (groupedProducts.containsKey(productName)) {
                    // If the product already exists, update quantity and price
                    groupedProducts[productName]!['quantity'] += product['orderQuantity'];
                    groupedProducts[productName]!['totalPrice'] += product['itemPrice'] * product['orderQuantity'];
                  } else {
                    // If the product doesn't exist, add it to the map
                    groupedProducts[productName] = {
                      'itemImage': product['itemImage'],
                      'itemName': product['itemName'],
                      'orderQuantity': product['orderQuantity'],
                      'itemPrice': product['itemPrice'],
                      'totalPrice': product['itemPrice'] * product['orderQuantity'],
                    };
                  }
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Display Product Details for grouped products
                      ...groupedProducts.values.map((product) {
                        return Row(
                          children: [
                            // Product Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                product['itemImage'] ?? 'https://via.placeholder.com/150',
                                height: 70,
                                width: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Product details (name, quantity, price)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['itemName'] ?? 'No Name',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text("Quantity: ${product['orderQuantity']}"),
                                  Text("Price: RM ${product['itemPrice']}"),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),

                      // Display Service Details if there is a service
                      if (service != null)
                        Row(
                          children: [
                            // Service Image
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
                            // Service details (name, serviceTime)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    service['serviceName'] ?? 'No Name',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Text("Service Time: ${service['serviceTime']}"),
                                ],
                              ),
                            ),
                          ],
                        ),

                      // View More Button with down arrow, centered
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            // Navigate to OrderScreen when "View More" is clicked
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OrderScreen(orderId: orderId),  // Pass the orderId to OrderScreen
                              ),
                            );
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
                            'Total ${groupedProducts.length + (service != null ? 1 : 0)} items',
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