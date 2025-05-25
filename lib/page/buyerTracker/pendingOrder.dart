import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:redofyp/page/buyerTracker/pending_view_more.dart';
import 'buyerOrderAccepted.dart';
import 'buyerOrderComplete.dart';
import 'buyerOrderDeclined.dart';
import '../donno/order.dart';  // Import OrderScreen

class PendingOrderScreen extends StatefulWidget {
  final String userId;

  const PendingOrderScreen({Key? key, required this.userId, required orderId}) : super(key: key);

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
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    setState(() {
      _ordersFuture = FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: status)  // Filter by the selected status (e.g., Pending for Approval)
          .where('userId', isEqualTo: currentUserId)  // Fetch only the current user's orders
          .get(); // Directly assign the result of the Firestore query
    });

    print("Fetching orders for userId: $currentUserId");
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
          .where('status', isEqualTo: 'Completed')
          .where('userId', isEqualTo: currentUserId)
          .get();

      double totalSpentAmount = 0.0;
      int completedOrders = 0;

      for (var order in completedOrdersSnapshot.docs) {
        final orderData = order.data() as Map<String, dynamic>;

        // Sum products total
        final List<dynamic> products = orderData['products'] ?? [];
        for (var product in products) {
          if (product is Map<String, dynamic>) {
            // No need to check creatorId here, since order is by current user
            final double price = product['itemPrice'] ?? 0.0;
            final int quantity = product['orderQuantity'] ?? 0;
            totalSpentAmount += price * quantity;
          }
        }

        // Add service totalPrice from order document root (if exists)
        final double serviceTotalPrice = (orderData['totalPrice'] ?? 0).toDouble();
        totalSpentAmount += serviceTotalPrice;

        completedOrders += 1;
      }

      setState(() {
        totalSpent = totalSpentAmount;
        completedOrderCount = completedOrders;
      });
    } catch (e) {
      print("Error calculating total spent and completed orders: $e");
    }
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
            title: Text('Orders', style: TextStyle(color: Colors.white)),
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
                    children: orders.map((orderDoc) {
                      final orderData = orderDoc.data() as Map<String, dynamic>;
                      final orderId = orderDoc.id;

                      final List products = List.from(orderData['products'] ?? []);
                      final dynamic service = orderData['services'];
                      final double totalAmount = orderData['totalPrice']?.toDouble() ?? 0.0;

                      // Group products by creatorId
                      Map<String, List<dynamic>> productsByCreator = {};
                      for (var product in products) {
                        final creatorId = product['creatorId'] ?? 'unknown';
                        if (productsByCreator.containsKey(creatorId)) {
                          productsByCreator[creatorId]!.add(product);
                        } else {
                          productsByCreator[creatorId] = [product];
                        }
                      }

                      List<Widget> productContainers = [];

                      // Build container per creator
                      productsByCreator.forEach((creatorId, productList) {
                        Map<String, Map<String, dynamic>> groupedProducts = {};
                        double totalPriceForCreator = 0.0;

                        for (var product in productList) {
                          final name = product['itemName'] ?? 'Unknown';
                          final quantity = product['orderQuantity'] ?? 0;
                          final price = product['itemPrice'] ?? 0.0;
                          final totalPrice = product['totalPrice'] ?? (price * quantity);

                          totalPriceForCreator += totalPrice;

                          if (groupedProducts.containsKey(name)) {
                            groupedProducts[name]!['orderQuantity'] += quantity;
                            groupedProducts[name]!['totalPrice'] += totalPrice;
                          } else {
                            groupedProducts[name] = {
                              'itemImage': product['itemImage'],
                              'itemName': name,
                              'orderQuantity': quantity,
                              'itemPrice': price,
                              'totalPrice': totalPrice,
                            };
                          }
                        }

                        final int totalItemsCount = groupedProducts.length;
                        final firstProduct = groupedProducts.values.first;

                        productContainers.add(
                          Container(
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
                                // Show only first product image and details
                                Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        firstProduct['itemImage'] ?? 'https://via.placeholder.com/150',
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
                                            firstProduct['itemName'] ?? 'No Name',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          Text("Quantity: ${firstProduct['orderQuantity']}"),
                                          Text("Price: RM ${firstProduct['itemPrice']}"),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Total items and price combined
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,  // Align row contents to the left
                                  children: [
                                    Text(
                                      'Total $totalItemsCount items: ',
                                      style: const TextStyle(fontWeight: FontWeight.normal),
                                    ),
                                    Text(
                                      'RM ${totalPriceForCreator.toStringAsFixed(2)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),

                                // View More button per seller container
                                Align(
                                  alignment: Alignment.center,
                                  child: TextButton(
                                    onPressed: () {
                                      final String orderStatus = orderData['status'];

                                      if (_tabController.index == 0) {
                                        // Pending tab - open PendingViewMoreScreen for this seller
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => PendingViewMoreScreen(
                                              orderId: orderId,
                                              creatorId: creatorId,  // Pass current seller creatorId
                                            ),
                                          ),
                                        );
                                      } else {
                                        // Other tabs - existing behavior
                                        if (orderStatus == 'Declined') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BuyerOrderDeclineScreen(orderId: orderId, userId: widget.userId),
                                            ),
                                          );
                                        } else if (orderStatus == 'Accepted') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BuyerOrderAcceptedScreen(orderId: orderId, userId: widget.userId),
                                            ),
                                          );
                                        } else if (orderStatus == 'Completed') {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => BuyerOrderCompleteScreen(orderId: orderId, userId: widget.userId),
                                            ),
                                          );
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => OrderScreen(orderId: orderId),
                                            ),
                                          );
                                        }
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
                              ],
                            ),
                          ),
                        );
                      });

                      // Service container if exists
                      Widget? serviceContainer;
                      if (service != null && service.isNotEmpty) {
                        final double serviceTotalPrice = totalAmount;

                        serviceContainer = Container(
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
                                        Text("Service Time: ${service['serviceTime'] ?? 'N/A'}"),
                                      ],
                                    ),
                                  ),
                                ],
                              ),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  const Text(
                                    'Total 1 item: ',
                                    style: TextStyle(fontWeight: FontWeight.normal),
                                  ),
                                  Text(
                                    'RM ${serviceTotalPrice.toStringAsFixed(2)}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),

                              Align(
                                alignment: Alignment.center,
                                child: TextButton(
                                  onPressed: () {
                                    final String orderStatus = orderData['status'];

                                    if (orderStatus == 'Declined') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BuyerOrderDeclineScreen(orderId: orderId, userId: widget.userId),
                                        ),
                                      );
                                    } else if (orderStatus == 'Accepted') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BuyerOrderAcceptedScreen(orderId: orderId, userId: widget.userId),
                                        ),
                                      );
                                    } else if (orderStatus == 'Completed') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => BuyerOrderCompleteScreen(orderId: orderId, userId: widget.userId),
                                        ),
                                      );
                                    } else {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => OrderScreen(orderId: orderId),
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
                            ],
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ...productContainers,
                          if (serviceContainer != null) serviceContainer,
                        ],
                      );
                    }).toList(),
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