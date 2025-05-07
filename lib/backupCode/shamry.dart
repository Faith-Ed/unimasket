// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:redofyp/page/sellerDecline.dart';  // Import the DeclineOrderScreen
//
// class SalesDetailsScreen extends StatefulWidget {
//   const SalesDetailsScreen({Key? key}) : super(key: key);
//
//   @override
//   _SalesDetailsScreenState createState() => _SalesDetailsScreenState();
// }
//
// class _SalesDetailsScreenState extends State<SalesDetailsScreen> with TickerProviderStateMixin {
//   late TabController _tabController;
//   late Future<QuerySnapshot> _ordersFuture;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 4, vsync: this); // 4 tabs for To Approve, Accepted, Declined, and Completed
//     _getOrders('Pending for Approval'); // Default fetch for To Approve orders
//   }
//
//   // Method to get orders based on the creatorId (current user's ID) and order status
//   void _getOrders(String status) {
//     setState(() {
//       _ordersFuture = FirebaseFirestore.instance
//           .collection('orders')
//           .where('status', isEqualTo: status)  // Filter by the selected status (e.g., Pending for Approval)
//           .get(); // Directly assign the result of the Firestore query
//     });
//   }
//
//   // Method to build content for each tab
//   Widget _buildTabContent(String status, List<QueryDocumentSnapshot> orders) {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             child: ListView.builder(
//               itemCount: orders.length,
//               itemBuilder: (context, index) {
//                 final orderData = orders[index].data() as Map<String, dynamic>;
//                 final orderId = orders[index].id;
//                 final status = orderData['status'];
//
//                 // Safely handle the 'products' field, which is a List<dynamic>
//                 final List<dynamic> products = orderData['products'] ?? [];
//                 final Map service = orderData['services'] ?? {};  // Single service map
//                 final creatorId = orderData['creatorId'];
//
//                 // Filter the products by creatorId, ensuring each item is a Map<String, dynamic>
//                 final List<Map<String, dynamic>> filteredProducts = products
//                     .where((item) {
//                   if (item is Map<String, dynamic>) {
//                     // Ensure the product has a valid creatorId and belongs to the current user
//                     return item['creatorId'] == FirebaseAuth.instance.currentUser!.uid;
//                   }
//                   return false;  // Skip invalid items that are not maps
//                 })
//                     .map((item) => item as Map<String, dynamic>)  // Explicitly cast each item to Map<String, dynamic>
//                     .toList();
//
//                 // Calculate total amount based on the price and quantity of the filtered products
//                 double totalAmount = 0.0;
//                 for (var item in filteredProducts) {
//                   totalAmount += (item['itemPrice'] ?? 0.0) * (item['orderQuantity'] ?? 0);
//                 }
//
//                 // Compare creatorId with the current user's ID for both service and product
//                 bool serviceBelongsToUser = creatorId == FirebaseAuth.instance.currentUser!.uid;
//
//                 // Skip this order if no products match and service doesn't belong to the current user
//                 if (filteredProducts.isEmpty && !serviceBelongsToUser) {
//                   return Container(); // Skip if no products or services match the current user
//                 }
//
//                 return Container(
//                   margin: const EdgeInsets.only(bottom: 16),
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: Colors.white,
//                     borderRadius: BorderRadius.circular(8),
//                     boxShadow: [
//                       BoxShadow(
//                         color: Colors.black.withOpacity(0.1),
//                         blurRadius: 6,
//                         offset: Offset(0, 2),
//                       ),
//                     ],
//                   ),
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         "Order ID: $orderId",
//                         style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                       ),
//                       const SizedBox(height: 10),
//                       Text('Status: $status'),
//                       const SizedBox(height: 10),
//                       // Display filtered products (products that belong to the current user)
//                       Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: filteredProducts.map<Widget>((item) {
//                           return Row(
//                             children: [
//                               ClipRRect(
//                                 borderRadius: BorderRadius.circular(8),
//                                 child: Image.network(
//                                   item['itemImage'] ?? 'https://via.placeholder.com/150',
//                                   height: 70,
//                                   width: 70,
//                                   fit: BoxFit.cover,
//                                 ),
//                               ),
//                               const SizedBox(width: 12),
//                               Expanded(
//                                 child: Column(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     Text(
//                                       item['itemName'] ?? 'No Name',
//                                       style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                                     ),
//                                     Text("Quantity: ${item['orderQuantity'] ?? 0}"),
//                                     Text("Price: RM ${item['itemPrice'] ?? 0.0}"),
//                                   ],
//                                 ),
//                               ),
//                             ],
//                           );
//                         }).toList(),
//                       ),
//                       const SizedBox(height: 10),
//
//                       // If there is a service and it belongs to the current user, display the service details
//                       if (creatorId == FirebaseAuth.instance.currentUser!.uid)
//                         Padding(
//                           padding: const EdgeInsets.only(top: 10),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "Service Details",
//                                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                               ),
//                               const SizedBox(height: 10),
//                               Row(
//                                 children: [
//                                   ClipRRect(
//                                     borderRadius: BorderRadius.circular(8),
//                                     child: Image.network(
//                                       service['serviceImage'] ?? 'https://via.placeholder.com/150',
//                                       height: 70,
//                                       width: 70,
//                                       fit: BoxFit.cover,
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Expanded(
//                                     child: Column(
//                                       crossAxisAlignment: CrossAxisAlignment.start,
//                                       children: [
//                                         Text(
//                                           service['serviceName'] ?? 'No Service Name',
//                                           style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
//                                         ),
//                                         Text("Service Time: ${service['serviceTime']}"),
//                                         Text("Service Location: ${service['serviceLocation']}"),
//                                         Text("Service Destination: ${service['serviceDestination']}"),
//                                         Text("Additional Notes: ${service['additionalNotes']}"),
//                                       ],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       // Display View More button with down arrow
//                       Align(
//                         alignment: Alignment.center,
//                         child: TextButton(
//                           onPressed: () {
//                             final String orderId = orders[index].id;  // Get the order ID from the orders list
//                             // Navigate to the DeclineOrderScreen with the orderId
//                             Navigator.push(
//                               context,
//                               MaterialPageRoute(
//                                 builder: (context) => DeclineOrderScreen(  // Navigate to DeclineOrderScreen
//                                   orderId: orderId,  // Pass the orderId to the screen
//                                 ),
//                               ),
//                             );
//                           },
//                           child: Row(
//                             mainAxisSize: MainAxisSize.min,
//                             children: const [
//                               Text("View More"),
//                               Icon(Icons.arrow_drop_down, size: 16),
//                             ],
//                           ),
//                         ),
//                       ),
//                       // Display total price for the order
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.end,
//                         children: [
//                           Text(
//                             'Total Amount: RM ${totalAmount.toStringAsFixed(2)}',
//                             style: const TextStyle(fontWeight: FontWeight.bold),
//                           ),
//                         ],
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Sales Details'),
//         bottom: TabBar(
//           controller: _tabController,
//           onTap: (index) {
//             // Change the query based on tab selection
//             if (index == 0) {
//               _getOrders('Pending for Approval');
//             } else if (index == 1) {
//               _getOrders('Accepted');
//             } else if (index == 2) {
//               _getOrders('Declined');
//             } else if (index == 3) {
//               _getOrders('Completed');
//             }
//           },
//           tabs: const [
//             Tab(text: 'To Approve'),
//             Tab(text: 'Accepted'),
//             Tab(text: 'Declined'),
//             Tab(text: 'Completed'),
//           ],
//         ),
//       ),
//       body: FutureBuilder<QuerySnapshot>(
//         future: _ordersFuture,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           }
//
//           if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
//             return const Center(child: Text("No orders found."));
//           }
//
//           final orders = snapshot.data!.docs;
//
//           return TabBarView(
//             controller: _tabController,
//             children: [
//               _buildTabContent('To Approve', orders),
//               _buildTabContent('Accepted', orders),
//               _buildTabContent('Declined', orders),
//               _buildTabContent('Completed', orders),
//             ],
//           );
//         },
//       ),
//     );
//   }
// }
