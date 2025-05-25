import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../widgets/pageDesign.dart';

class SellerAcceptOrderScreen extends StatefulWidget {
  final String orderId;  // Pass the order ID to this screen

  const SellerAcceptOrderScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _SellerAcceptOrderScreenState createState() => _SellerAcceptOrderScreenState();
}

class _SellerAcceptOrderScreenState extends State<SellerAcceptOrderScreen> {
  late Future<DocumentSnapshot> _orderFuture;
  late Future<DocumentSnapshot> _acceptedNotesFuture;
  late String _currentUserId;

  String? _pickupLocation;
  String? _pickupTime;
  String? _deliveryTime;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the order data from Firestore based on orderId
    _orderFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();

    // Fetch the accepted_notes subcollection for the order
    _acceptedNotesFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection('accepted_notes')
        .doc('note') // Assuming the document ID for the accepted note is 'note'
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data() as Map<String, dynamic>;
        setState(() {
          _pickupLocation = data['pickupLocation'];
          _pickupTime = data['pickupTime'];
          _deliveryTime = data['deliveryTime'];
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

    double totalProductsPrice = 0.0;
    for (var item in products) {
      final quantity = item['orderQuantity'] ?? 0;
      final price = (item['itemPrice'] ?? 0.0).toDouble();
      totalProductsPrice += quantity * price;
    }

    double servicePrice = 0.0;
    if (orderData['totalPrice'] != null) {
      servicePrice = (orderData['totalPrice'] as num).toDouble();
    }

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

            // Total price
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
      appBar: customAppBar('Order Acceptance'),
      body: FutureBuilder<DocumentSnapshot>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
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

                  // Display pickup and delivery details
                  if (_pickupLocation != null || _pickupTime != null || _deliveryTime != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pickup/Delivery Details:",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            if (_pickupLocation != null)
                              Text(
                                "Pickup Location: $_pickupLocation",
                                style: TextStyle(fontSize: 14),
                              ),
                            if (_pickupTime != null)
                              Text(
                                "Pickup Time: $_pickupTime",
                                style: TextStyle(fontSize: 14),
                              ),
                            if (_deliveryTime != null)
                              Text(
                                "Delivery Time: $_deliveryTime",
                                style: TextStyle(fontSize: 14),
                              ),
                          ],
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
