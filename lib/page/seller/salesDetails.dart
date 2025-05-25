import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redofyp/page/seller/sellerAccept.dart';
import 'package:redofyp/page/seller/sellerComplete.dart';
import 'package:redofyp/page/seller/sellerDecline.dart';
import 'package:redofyp/page/seller/toApprove.dart';  // Import the DeclineOrderScreen

class SalesDetailsScreen extends StatefulWidget {
  const SalesDetailsScreen({Key? key}) : super(key: key);

  @override
  _SalesDetailsScreenState createState() => _SalesDetailsScreenState();
}

class _SalesDetailsScreenState extends State<SalesDetailsScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late Future<QuerySnapshot> _ordersFuture;
  List<QueryDocumentSnapshot> _sortedOrders = [];
  double totalSales = 0.0;
  int completedOrderCount = 0;

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
          .where('status', isEqualTo: status)
          .get();

      if (status == 'Completed') {
        _calculateCompletedSalesAndOrders();
      } else {
        // Reset totals when not completed tab
        totalSales = 0.0;
        completedOrderCount = 0;
      }
    });
  }

  // Method to sort orders by timestamp after fetching them
  Future<void> _sortOrdersByTimestamp(List<QueryDocumentSnapshot> orders, String status) async {
    List<QueryDocumentSnapshot> sortedOrders = [];

    for (var order in orders) {
      final orderData = order.data() as Map<String, dynamic>;

      if (orderData['status'] != null && orderData['status'].contains(status)) {
        // Get the timestamp from the corresponding subcollection
        Timestamp? timestamp;

        // Check which subcollection to use based on the status
        if (status == 'Accepted') {
          final acceptedNotesSnapshot = await FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .collection('accepted_notes')
              .doc('note') // Get the 'note' document
              .get();

          if (acceptedNotesSnapshot.exists) {
            timestamp = acceptedNotesSnapshot['timestamp'];
          }
        } else if (status == 'Declined') {
          final declineReasonSnapshot = await FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .collection('decline_reason')
              .doc('reason')
              .get();

          if (declineReasonSnapshot.exists) {
            timestamp = declineReasonSnapshot['timestamp'];
          }
        } else if (status == 'Completed') {
          final completedTimestampSnapshot = await FirebaseFirestore.instance
              .collection('orders')
              .doc(order.id)
              .collection('completed')
              .doc('completed_timestamp')
              .get();

          if (completedTimestampSnapshot.exists) {
            timestamp = completedTimestampSnapshot['completedTime'];
          }
        }

        if (timestamp != null) {
          orderData['timestamp'] = timestamp; // Add timestamp to the order data for sorting
          sortedOrders.add(order);
        }
      }
    }

    // Sort the orders by timestamp in descending order (latest first)
    sortedOrders.sort((a, b) {
      final timestampA = a['timestamp'] as Timestamp;
      final timestampB = b['timestamp'] as Timestamp;
      return timestampA.compareTo(timestampB); // Sort in descending order
    });

    // Update the orders after sorting
    setState(() {
      _sortedOrders = sortedOrders; // Store sorted orders in state
    });
  }

  Future<void> _calculateCompletedSalesAndOrders() async {
    try {
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      final completedOrdersSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: 'Completed')
          .get();

      double total = 0.0;
      int completedOrders = 0;

      for (var order in completedOrdersSnapshot.docs) {
        final orderData = order.data() as Map<String, dynamic>;
        final List<dynamic> products = orderData['products'] ?? [];
        final service = orderData['services'] ?? {}; // Service map
        final double servicePrice = (orderData['totalPrice'] ?? 0.0).toDouble();
        final String serviceCreatorId = orderData['creatorId'] ?? '';

        // Check if current user has products or services in this order
        bool hasUserProduct = products.any((product) {
          if (product is Map<String, dynamic>) {
            return product['creatorId'] == currentUserId;
          }
          return false;
        });

        // Adjusted to check the creatorId inside the service map
        bool hasUserService = serviceCreatorId == currentUserId;

        print('Service creatorId: ${service['creatorId']}');
        print('Current userId: $currentUserId');

        if (hasUserProduct || hasUserService) {
          completedOrders++; // Count this order

          // Sum product totals if the current user owns the product
          for (var product in products) {
            if (product is Map<String, dynamic> && product['creatorId'] == currentUserId) {
              final double price = (product['itemPrice'] ?? 0).toDouble();
              final int quantity = (product['orderQuantity'] ?? 0);
              total += price * quantity;
            }
          }

          // Add service price if the current user owns the service
          if (hasUserService) {
            total += servicePrice;
          }
        }
      }

      setState(() {
        totalSales = total;
        completedOrderCount = completedOrders;
      });
    } catch (e) {
      print('Error calculating completed sales and orders: $e');
    }
  }

  // Method to build content for each tab
  Widget _buildTabContent(String status, List<QueryDocumentSnapshot> orders) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the total sales and number of completed orders at the top
          if (status == 'Completed')
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  // Total Sales Container
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Sales',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'RM ${totalSales.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.yellowAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 20),
                  // No. Order Completed Container
                  Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order Completed',
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 15,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          '$completedOrderCount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: Colors.yellowAccent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final orderData = orders[index].data() as Map<String, dynamic>;
                final orderId = orders[index].id;
                final status = orderData['status'];

                // Safely handle the 'products' field, which is a List<dynamic>
                final List<dynamic> products = orderData['products'] ?? [];
                final Map service = orderData['services'] ?? {};  // Single service map
                final servicePrice = orderData['totalPrice'] ?? 0.0;
                final creatorId = orderData['creatorId'];

                // Filter the products by creatorId, ensuring each item is a Map<String, dynamic>
                final List<Map<String, dynamic>> filteredProducts = products
                    .where((item) {
                  if (item is Map<String, dynamic>) {
                    // Ensure the product has a valid creatorId and belongs to the current user
                    return item['creatorId'] == FirebaseAuth.instance.currentUser!.uid;
                  }
                  return false;  // Skip invalid items that are not maps
                })
                    .map((item) => item as Map<String, dynamic>)  // Explicitly cast each item to Map<String, dynamic>
                    .toList();

                // Calculate total amount and total items for products
                int totalItems = 0; // To count the number of items in the order
                double totalAmount = 0.0;

// Iterate through the filtered products
                for (var item in filteredProducts) {
                  totalAmount += (item['itemPrice'] ?? 0.0) * (item['orderQuantity'] ?? 0);
                  totalItems++;  // Increment for each product in the filtered products list
                }

// Set totalItems to 1 if there's a service
                if (creatorId == FirebaseAuth.instance.currentUser!.uid && service.isNotEmpty) {
                  totalItems += 1;  // Add 1 item for the service
                }

                // Compare creatorId with the current user's ID for both service and product
                bool serviceBelongsToUser = creatorId == FirebaseAuth.instance.currentUser!.uid;

                // Skip this order if no products match and service doesn't belong to the current user
                if (filteredProducts.isEmpty && !serviceBelongsToUser) {
                  return Container(); // Skip if no products or services match the current user
                }

                // Display the service totalPrice if the service belongs to the user
                if (creatorId == FirebaseAuth.instance.currentUser!.uid) {
                  totalAmount += servicePrice;
                }

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
                      Text(
                        "Order ID: $orderId",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      Text('Status: $status'),
                      const SizedBox(height: 10),
                      // Display the first filtered product (if any)
                      if (filteredProducts.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    filteredProducts[0]['itemImage'] ?? 'https://via.placeholder.com/150',
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
                                        filteredProducts[0]['itemName'] ?? 'No Name',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                      ),
                                      Text("Quantity: ${filteredProducts[0]['orderQuantity'] ?? 0}"),
                                      Text("Price: RM ${filteredProducts[0]['itemPrice'] ?? 0.0}"),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      // If there is a service and it belongs to the current user, display the service details
                      if (creatorId == FirebaseAuth.instance.currentUser!.uid)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
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
                                          service['serviceName'] ?? 'No Service Name',
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
                          ),
                        ),
                      // Display View More button with down arrow
                      Align(
                        alignment: Alignment.center,
                        child: TextButton(
                          onPressed: () {
                            final String orderId = orders[index].id;  // Get the order ID from the orders list
                            final String orderStatus = orderData['status']; // Get the order status

                            // Navigate based on order status
                            if (orderStatus == 'Declined') {
                              // If the status is Declined, navigate to the DeclineOrderScreen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => DeclineOrderScreen(  // Navigate to DeclineOrderScreen
                                    orderId: orderId,  // Pass the orderId to the screen
                                  ),
                                ),
                              );
                            } else if (orderStatus == 'Accepted') {
                              // If the status is Accepted, navigate to the SellerAcceptOrderScreen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SellerAcceptOrderScreen(  // Navigate to SellerAcceptOrderScreen
                                    orderId: orderId,  // Pass the orderId to the screen
                                  ),
                                ),
                              );
                            } else if (orderStatus == 'Completed') {
                              // If the status is Completed, navigate to the SellerCompleteScreen
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SellerCompleteScreen(  // Navigate to SellerOrderCompleteScreen
                                    orderId: orderId, userId: '',  // Pass the orderId to the screen
                                  ),
                                ),
                              );
                            } else {
                              // Otherwise, navigate to the order details screen (for example, ToApproveScreen)
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ToApproveScreen(  // You can create a general order details screen here
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
                      // Display total price for the order
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'Total $totalItems items: RM ${totalAmount.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
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
      backgroundColor: Colors.yellow.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(120), // Set the height of the AppBar
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),  // Set left bottom corner radius
            bottomRight: Radius.circular(10),  // Set right bottom corner radius
          ),
          child: AppBar(
            toolbarHeight: 80, // Toolbar height remains as per your request
            title: Text('Sales Details', style: TextStyle(color: Colors.white)),
            backgroundColor: CupertinoColors.systemYellow,  // AppBar background color
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
      ),),),
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

          // Sort orders by timestamp for each status (Accept, Decline, Completed)
          if (_tabController.index == 1) {
            // For Accepted orders
            _sortOrdersByTimestamp(orders, 'Accepted');
          } else if (_tabController.index == 2) {
            // For Declined orders
            _sortOrdersByTimestamp(orders, 'Declined');
          } else if (_tabController.index == 3) {
            // For Completed orders
            _sortOrdersByTimestamp(orders, 'Completed');
          }

          return Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent('To Approve', orders),
                    _buildTabContent('Accepted', orders),
                    _buildTabContent('Declined', orders),
                    _buildTabContent('Completed', orders),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
