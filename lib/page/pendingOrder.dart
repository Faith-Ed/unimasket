import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'buyerOrderAccepted.dart';
import 'buyerOrderComplete.dart';
import 'buyerOrderDeclined.dart';
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
  double totalSpent = 0.0;
  int completedOrderCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4,
        vsync: this); // 4 tabs for Pending, Accepted, Declined, and Completed
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

  // Method to calculate the total spent and completed order count
  Future<void> _getTotalSpentAndCompletedOrderCount() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Fetch completed orders for the current user
      final completedOrdersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'Completed') // Ensure we get only completed orders
          .where('userId', isEqualTo: currentUserId)
          .get();

      double totalSpentAmount = 0.0;
      int completedOrders = 0;

      // Iterate through each completed order
      for (var order in completedOrdersSnapshot.docs) {
        final orderData = order.data() as Map<String, dynamic>;

        // Get the products array from the order data
        final List<dynamic> products = orderData['products'] ?? [];

        // Iterate through the products and calculate the totalPrice for each product
        for (var product in products) {
          if (product is Map<String, dynamic>) {
            // Ensure the product has a valid creatorId and belongs to the current user
            if (product['creatorId'] == currentUserId) {
              // Fetch the price and quantity for the product and calculate the total
              final double price = product['itemPrice'] ?? 0.0;
              final int quantity = product['orderQuantity'] ?? 0;
              totalSpentAmount +=
                  price * quantity; // Add to the total spent amount
            }
          }
        }

        // Count the completed orders
        completedOrders += 1;
      }

      // Update the state with the total spent and completed order count
      setState(() {
        totalSpent = totalSpentAmount; // Store total spent
        completedOrderCount = completedOrders; // Store completed order count
      });
    } catch (e) {
      print("Error calculating total spent and completed orders: $e");
    }
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
              _getOrders('Declined'); // Fetch declined orders when "Declined" tab is selected
            } else if (index == 3) {
              _getOrders('Completed');
              _getTotalSpentAndCompletedOrderCount(); // Get the total spent and completed order count for completed orders
            }
          },
          tabs: const [
            Tab(text: "Pending"),
            Tab(text: "Accepted"),
            Tab(text: "Declined"),
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

          return Column(
            children: [
              // Fixed Container for Total Spent and Orders Completed
              if (_tabController.index == 3) // Only display in the Completed tab
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 6.0),
                  child: Row(
                    children: [
                      // Total Spent Container
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black87,
                                blurRadius: 8,
                                offset: Offset(0, 10), // Add shadow to the bottom for elevation
                              ),
                            ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Total Spent',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                'RM ${totalSpent.toStringAsFixed(2)}',  // Display total spent
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.yellowAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 15),
                      // Orders Completed Container
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black87,
                                  blurRadius: 8,
                                  offset: Offset(0, 10), // Add shadow to the bottom for elevation
                                ),
                              ]
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                'Orders Completed',
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                  color: Colors.white,
                                ),
                              ),
                              SizedBox(height: 5),
                              Text(
                                '$completedOrderCount',  // Display the completed orders count
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Colors.yellowAccent,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  )
                ),
              // Line Divider Between Container and List
              SizedBox(height: 10), // Adding some space between the container and the line
              Container(
                height: 4, // Height of the line
                color: Colors.black12, // Light grey color for the line
              ),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Orders list
                      ...orders.map((orderDoc) {
                        final orderData = orderDoc.data() as Map<String, dynamic>;
                        final orderId = orderDoc.id;

                        // Fetch products (array) and services (single object) separately
                        final List products = List.from(orderData['products'] ?? []);
                        final dynamic service = orderData['services'] ?? null;
                        final totalAmount = orderData['totalAmount'] ?? 0.0;

                        // Group the products by creatorId
                        var groupedByCreatorId = <String, List<dynamic>>{};
                        for (var product in products) {
                          final creatorId = product['creatorId'] ?? 'Unknown';
                          if (groupedByCreatorId.containsKey(creatorId)) {
                            groupedByCreatorId[creatorId]!.add(product);
                          } else {
                            groupedByCreatorId[creatorId] = [product];
                          }
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: groupedByCreatorId.entries.map((entry) {
                            final creatorId = entry.key;
                            final productList = entry.value;

                            // Group the products for each creatorId
                            var groupedProducts = <String, Map<String, dynamic>>{};
                            for (var product in productList) {
                              final productName = product['itemName'] ?? 'Unknown';
                              if (groupedProducts.containsKey(productName)) {
                                groupedProducts[productName]!['quantity'] +=
                                product['orderQuantity'];
                                groupedProducts[productName]!['totalPrice'] +=
                                    product['itemPrice'] * product['orderQuantity'];
                              } else {
                                groupedProducts[productName] = {
                                  'itemImage': product['itemImage'],
                                  'itemName': product['itemName'],
                                  'orderQuantity': product['orderQuantity'],
                                  'itemPrice': product['itemPrice'],
                                  'totalPrice': product['itemPrice'] *
                                      product['orderQuantity'],
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
                                  BoxShadow(color: Colors.black12,
                                      blurRadius: 6,
                                      offset: Offset(0, 2)),
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
                                        final String orderId = orderDoc.id;  // Get the order ID from the orders list
                                        final String orderStatus = orderData['status']; // Get the order status

                                        // Navigate based on the order status
                                        if (orderStatus == 'Declined') {
                                          // If the status is Declined, navigate to the BuyerOrderDeclinedScreen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BuyerOrderDeclineScreen(  // Navigate to the BuyerOrderDeclinedScreen
                                                    orderId: orderId,  // Pass the orderId to the screen
                                                    userId: widget.userId,  // Pass the userId to the screen
                                                  ),
                                            ),
                                          );
                                        } else if (orderStatus == 'Accepted') {
                                          // If the status is Accepted, navigate to the BuyerOrderAcceptedScreen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BuyerOrderAcceptedScreen(  // Navigate to the BuyerOrderAcceptedScreen
                                                    orderId: orderId,  // Pass the orderId to the screen
                                                    userId: widget.userId,  // Pass the userId to the screen
                                                  ),
                                            ),
                                          );
                                        } else if (orderStatus == 'Completed') {
                                          // If the status is Completed, navigate to the BuyerOrderCompleteScreen
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  BuyerOrderCompleteScreen(  // Navigate to the BuyerOrderCompleteScreen
                                                    orderId: orderId,  // Pass the orderId to the screen
                                                    userId: widget.userId,  // Pass the userId to the screen
                                                  ),
                                            ),
                                          );
                                        } else {
                                          // Handle other statuses (optional)
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  OrderScreen(  // Default order details screen
                                                    orderId: orderId,  // Pass the orderId to the screen
                                                  ),
                                            ),
                                          );
                                        }
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
                        );
                      }).toList(),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}