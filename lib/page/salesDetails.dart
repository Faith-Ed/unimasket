import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'toApprove.dart'; // Import the toApprove.dart page

class SalesDetailsScreen extends StatefulWidget {
  const SalesDetailsScreen({Key? key}) : super(key: key);

  @override
  _SalesDetailsScreenState createState() => _SalesDetailsScreenState();
}

class _SalesDetailsScreenState extends State<SalesDetailsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<QuerySnapshot> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // 4 tabs for To Approve, Accepted, Declined, and Completed
    _getOrders('Pending for Approval'); // Default fetch for To Approve orders
  }

  // Method to get orders based on the creatorId (current user's ID) and order status
  void _getOrders(String status) {
    setState(() {
      _ordersFuture = FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: status)  // Filter by the selected status (e.g., Pending for Approval)
          .get(); // Directly assign the result of the Firestore query
    });
  }

  // Method to build content for each tab
  Widget _buildTabContent(String status, List<QueryDocumentSnapshot> orders) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$status Sales',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          // Display orders for this status
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final orderData = orders[index].data() as Map<String, dynamic>;
                final orderId = orders[index].id;
                final List products = orderData['products'] ?? []; // List of products
                final Map service = orderData['services'] ?? {}; // Single service map
                final totalAmount = orderData['totalAmount'] ?? 0.0;
                final creatorId = orderData['creatorId'];

                // Only show orders where creatorId matches the current user's ID
                if (creatorId == FirebaseAuth.instance.currentUser!.uid) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Display Product details if available
                        if (products.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Products",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
                              // For products, display product details
                              ...products.map<Widget>((item) {
                                // print('Item: $item'); // Debug print to show the product data

                                // Ensure the product has a valid listingType and is a 'product'
                                if (item != null && item is Map && item['listingType'] == 'product') {
                                  print('Product Item: $item');
                                  return Row(
                                    children: [
                                      // Product Image
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: Image.network(
                                          item['itemImage'] ?? 'https://via.placeholder.com/150', // Default image
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
                                              item['itemName'] ?? 'No Name',
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                            ),
                                            Text("Quantity: ${item['orderQuantity'] ?? 0}"),
                                            Text("Price: RM ${item['itemPrice'] ?? 0.0}"),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                }else {
                print('Skipping non-product or invalid item: $item'); // Debugging statement
                                return Container(); // If it's not a product or listingType is wrong, return an empty container
                              }}).toList(),
                            ],
                          )
                        else
                          const Center(child: Text("No products available")), // Display this message when no products are found in the order

                        // Display Service Details if there is a service
                        if (service.isNotEmpty)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 20),
                              Text(
                                "Services",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 10),
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
                                        Text("Service Location: ${service['serviceLocation']}"),
                                        Text("Service Destination: ${service['serviceDestination']}"),
                                        Text("Additional Notes: ${service['additionalNotes']}"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          )
                        else
                          const Text("No services available"),

                        // View More Button with down arrow, centered
                        Align(
                          alignment: Alignment.center,
                          child: TextButton(
                            onPressed: () {
                              // Navigate to ToApproveScreen with current userId
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ToApproveScreen(
                                    userId: FirebaseAuth.instance.currentUser!.uid, // Pass the current userId
                                  ),
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
                            Text(
                              'Total ${products.length + (service.isNotEmpty ? 1 : 0)} items',
                              style: const TextStyle(fontWeight: FontWeight.normal),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'RM ${totalAmount.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                } else {
                  return Container(); // Return empty container if creatorId doesn't match
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Details'),
        bottom: TabBar(
          controller: _tabController,
          onTap: (index) {
            // Change the query based on tab selection
            if (index == 0) {
              _getOrders('Pending for Approval');
            } else if (index == 1) {
              _getOrders('Accepted');
            } else if (index == 2) {
              _getOrders('Declined');
            } else if (index == 3) {
              _getOrders('Completed');
            }
          },
          tabs: const [
            Tab(text: 'To Approve'),
            Tab(text: 'Accepted'),
            Tab(text: 'Declined'),
            Tab(text: 'Completed'),
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

          return TabBarView(
            controller: _tabController,
            children: [
              _buildTabContent('To Approve', orders),
              _buildTabContent('Accepted', orders),
              _buildTabContent('Declined', orders),
              _buildTabContent('Completed', orders),
            ],
          );
        },
      ),
    );
  }
}
