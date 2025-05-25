import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redofyp/widgets/pageDesign.dart';

import '../../widgets/chatSellerButton.dart';

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
    final paymentMethod = orderData['paymentMethod'] ?? 'N/A';
    final collectionOption = orderData['collectionOption'] ?? 'N/A';
    final List<dynamic> products = orderData['products'] ?? [];
    final Map<String, dynamic> service = Map<String, dynamic>.from(orderData['services'] ?? {});

    // Calculate total product price
    double totalProductsPrice = 0.0;
    for (var item in products) {
      final quantity = item['orderQuantity'] ?? 0;
      final price = (item['itemPrice'] ?? 0.0).toDouble();
      totalProductsPrice += quantity * price;
    }

    // Service price from service map
    double servicePrice = 0.0;
    if (service.isNotEmpty && service['price'] != null) {
      servicePrice = (service['price'] as num).toDouble();
    }

    // Overall total
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
            // Products Section
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

            // Service Section
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
      backgroundColor: Colors.yellow.shade50,
      appBar: customAppBar('Order Complete'),
      body: FutureBuilder<DocumentSnapshot>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Order not found"));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>? ?? {};

          // Get product listingId if available
          String? listingId;
          if (orderData['products'] != null &&
              (orderData['products'] as List).isNotEmpty) {
            listingId = orderData['products'][0]['listingId'];
          }

          // Get service listingId (assumed outside 'services' map)
          String? serviceListingId = orderData['listingId'] ?? orderData?['services']?['listingId'];

          // Decide which listingId to use for chat button
          String? chatListingId = listingId ?? serviceListingId;

          Widget? contactSellerButton;
          if (chatListingId != null) {
            contactSellerButton = ChatSellerButton(listingId: chatListingId);
          } else {
            contactSellerButton = null;
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

                  _buildOrderStatusAndCompletedTime(),

                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: contactSellerButton,
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
