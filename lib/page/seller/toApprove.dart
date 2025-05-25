import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/accept_button.dart';
import '../../widgets/decline_button.dart';
import '../../widgets/pageDesign.dart';

class ToApproveScreen extends StatefulWidget {
  final String orderId;  // Pass the order ID to this screen

  const ToApproveScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _ToApproveScreenState createState() => _ToApproveScreenState();
}

class _ToApproveScreenState extends State<ToApproveScreen> {
  late Future<DocumentSnapshot> _orderFuture;
  final TextEditingController _sellerNotesController = TextEditingController();
  final TextEditingController _orderTotalController = TextEditingController();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the order data from Firestore based on orderId
    _orderFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();

    // Fetch seller notes from the subcollection and update the controller
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection('user_notes')
        .doc('seller_notes')
        .get()
        .then((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _sellerNotesController.text = snapshot.data()!['note'] ?? ''; // Update the seller notes text controller
      }
    });

    // Fetch order total and update the controller
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get()
        .then((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _orderTotalController.text = snapshot.data()!['totalPrice']?.toString() ?? '0.00'; // Update the order total
      }else {
        print("Error: Order not found");
        // Handle case where order does not exist
      }
    });
  }

  // Method to build the order content
  Widget _buildOrderContent(Map<String, dynamic> orderData) {
    final status = orderData['status'];
    final paymentMethod = orderData['paymentMethod'];
    final collectionOption = orderData['collectionOption'];
    final String deliveryLocation = orderData['deliveryLocation'] ?? '';
    final List<dynamic> products = orderData['products'] ?? [];
    final Map<String, dynamic>? service = (orderData['services'] != null)
        ? Map<String, dynamic>.from(orderData['services'])
        : null;
    final creatorId = orderData['creatorId'];

    // Filter products by the current user
    final filteredProducts = products.where((item) {
      return item is Map<String, dynamic> &&
          item['creatorId'] == FirebaseAuth.instance.currentUser!.uid;
    }).toList();

    // For service, check if it belongs to current user (by comparing creatorId inside service or order level if applicable)
    bool serviceBelongsToUser = false;
    if (service != null) {
      // For example, if service has 'creatorId' or you want to check by order level creatorId
      if (service.containsKey('creatorId')) {
        serviceBelongsToUser = service['creatorId'] == _currentUserId;
      } else {
        // fallback: check order creatorId (optional)
        serviceBelongsToUser = orderData['creatorId'] == _currentUserId;
      }
    }

    double total = 0.0; // To calculate total order cost
    // Calculate total from products only, since service totalPrice is separate
    for (var item in filteredProducts) {
      total += (item['orderQuantity'] ?? 0) * (item['itemPrice'] ?? 0);
    }

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product List UI
          if (filteredProducts.isNotEmpty)
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...filteredProducts.map<Widget>((item) {
                    return Column(
                      children: [
                        Row(
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
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Quantity: ${item['orderQuantity'] ?? 0}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w400, fontSize: 14),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    "Price: RM ${item['itemPrice'] ?? 0.0}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w400, fontSize: 14),
                                  ),
                                  SizedBox(height: 5),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                      ],
                    );
                  }),
                  const Divider(),
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Collection Option: ',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text.rich(
                          TextSpan(
                            text: collectionOption == 'Delivery' && deliveryLocation.isNotEmpty
                                ? 'Delivery '
                                : collectionOption,
                            style: TextStyle(fontWeight: FontWeight.normal),
                            children: [
                              if (collectionOption == 'Delivery' && deliveryLocation.isNotEmpty)
                                TextSpan(
                                  text: '($deliveryLocation)',
                                  style: TextStyle(color: Colors.redAccent),
                                ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Method: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$paymentMethod',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  const Divider(),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Total: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'RM $total',
                        style:
                        TextStyle(fontWeight: FontWeight.w500, fontSize: 18),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                ],
              ),
            ),

          // Service Details UI (if service belongs to user)
          if (serviceBelongsToUser && service != null)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Service Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
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
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text("Service Time: ${service['serviceTime'] ?? '-'}"),
                            Text("Service Location: ${service['serviceLocation'] ?? '-'}"),
                            Text("Service Destination: ${service['serviceDestination'] ?? '-'}"),
                            Text("Additional Notes: ${service['additionalNotes'] ?? '-'}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  SizedBox(height: 5),
                  Text(
                    "Seller Notes (For your own record):",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      controller: _sellerNotesController,
                      decoration: InputDecoration(
                        hintText: "Enter seller notes here...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                            vertical: 4, horizontal: 8), // Reduced padding for smaller height
                      ),
                      maxLines: 5,
                      onChanged: (value) {
                        FirebaseFirestore.instance
                            .collection('orders')
                            .doc(widget.orderId)
                            .collection('user_notes')
                            .doc('seller_notes')
                            .set({'note': value});
                      },
                    ),
                  ),
                  SizedBox(height: 8),
                  const Divider(),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Total: ',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: 120,
                        height: 30,
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                "RM",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _orderTotalController,
                                decoration: InputDecoration(
                                  hintText: "0.00",
                                  border: OutlineInputBorder(),
                                  contentPadding:
                                  EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  double? newTotal = double.tryParse(value);
                                  if (newTotal != null) {
                                    FirebaseFirestore.instance
                                        .collection('orders')
                                        .doc(widget.orderId)
                                        .update({'totalPrice': newTotal});
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderIdAndTime(Map<String, dynamic> orderData) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
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
      appBar: customAppBar('Order Details'),
      body: FutureBuilder<DocumentSnapshot>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
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

                  // Pass orderId to AcceptButton and DeclineButton
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      AcceptButton(orderId: widget.orderId),
                      DeclineButton(orderId: widget.orderId),
                    ],
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
