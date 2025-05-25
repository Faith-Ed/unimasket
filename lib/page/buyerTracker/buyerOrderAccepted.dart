import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redofyp/widgets/pageDesign.dart';

import '../../services/notification_service.dart';
import '../../widgets/chatSellerButton.dart';
import 'buyerOrderComplete.dart';

class BuyerOrderAcceptedScreen extends StatefulWidget {
  final String orderId;  // Pass the order ID to this screen
  final String userId;   // Pass the user ID to this screen

  const BuyerOrderAcceptedScreen({Key? key, required this.orderId, required this.userId}) : super(key: key);

  @override
  _BuyerOrderAcceptedScreenState createState() => _BuyerOrderAcceptedScreenState();
}

class _BuyerOrderAcceptedScreenState extends State<BuyerOrderAcceptedScreen> {
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

    // Calculate total for products
    double totalProductsPrice = 0.0;
    for (var item in products) {
      final quantity = item['orderQuantity'] ?? 0;
      final price = (item['itemPrice'] ?? 0.0).toDouble();
      totalProductsPrice += quantity * price;
    }

    // Service total price fetched directly
    double servicePrice = 0.0;
    if (service.isNotEmpty && service['price'] != null) {
      servicePrice = (service['price'] as num).toDouble();
    }

    // Overall order total is sum of products + service price
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
            // Products section
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
              // Collection Option and Payment Method for products only
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

            // Service section
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

  // Method to update the order status to 'Completed'
  Future<void> _updateOrderStatusToCompleted() async {
    try {
      // Show a confirmation dialog to confirm order completion
      bool? confirm = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Confirm Order Received'),
            content: Text('Have you received the order?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Yes'),
              ),
            ],
          );
        },
      );

      // If the user confirmed, update the order status to 'Completed' and save timestamp
      if (confirm == true) {
        final completedData = {
          'completedBy': _currentUserId,
          'completedTime': FieldValue.serverTimestamp(),
        };

        // Save the timestamp in the 'completed' subcollection
        await FirebaseFirestore.instance.collection('orders').doc(widget.orderId)
            .collection('completed').doc('completed_timestamp').set(completedData);

        // Get the order details and update the products to 'Completed' status
        final orderSnapshot = await FirebaseFirestore.instance.collection('orders')
            .doc(widget.orderId)
            .get();

        final orderData = orderSnapshot.data() as Map<String, dynamic>;
        final List<dynamic> products = orderData['products'] ?? [];

        // Loop through products and update the status to 'Completed' if the creatorId matches the current user
        for (var i = 0; i < products.length; i++) {
          if (products[i]['creatorId'] == _currentUserId) {
            products[i]['status'] = 'Completed';
          }
        }

        // Update the order status and the products in Firestore
        await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
          'status': 'Completed',  // Update the overall order status
          'products': products,   // Update the products array with the modified statuses
        });

        // Update the notification to reflect that the order has been completed
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('notifications')
            .where('orderId', isEqualTo: widget.orderId)
            .get()
            .then((snapshot) {
          snapshot.docs.forEach((doc) {
            doc.reference.update({
              'type': 'order_completed',
              'message': 'Your order has been completed.',
              'isSelected': false,
            });
          });
        });

        final notificationsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(_currentUserId)
            .collection('notifications')
            .where('orderId', isEqualTo: widget.orderId)
            .get();

        for (var doc in notificationsSnapshot.docs) {
          await doc.reference.update({'isSeen': false});
        }

        // Fetch the seller's ID (creatorId of the product)
        final sellerId = products.isNotEmpty ? products[0]['creatorId'] : null;

        if (sellerId != null) {
          // Send a notification to the seller indicating the order has been completed
          await NotificationService.sendNotificationToUser(
            userId: sellerId,
            orderId: widget.orderId,
            type: 'seller_order_completed',
            customMessage: 'The order has been completed. Please check.',
          );

          print("Seller ID: $sellerId");
        } else {
          print("Error: Seller ID is missing");
        }

        // Send a notification to the current user (buyer) for order completion
        await NotificationService.sendNotificationToUser(
          userId: _currentUserId,  // The current user (buyer)
          orderId: widget.orderId,
          type: 'order_completed',
          customMessage: 'You have marked the order as completed.',
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BuyerOrderCompleteScreen(
              orderId: widget.orderId,
              userId: widget.userId,
            ),
          ),
        );

        // Optionally, you can show snackbar after redirect, or remove it
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked as completed.')),
        );
      }
    } catch (e) {
      print("Error updating order status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update order status.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: customAppBar('Order Accepted'),
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
          Map<String, dynamic> service = Map<String, dynamic>.from(orderData['services'] ?? {});

          String? listingId;
          if (orderData != null && orderData['products'] != null && (orderData['products'] as List).isNotEmpty) {
            listingId = orderData['products'][0]['listingId'];
          }

          String? serviceListingId = orderData?['listingId'] as String?; // outside 'services' map

          Widget? contactSellerButton;

          if (listingId != null) {
            contactSellerButton = ChatSellerButton(listingId: listingId);
          } else if (serviceListingId != null) {
            contactSellerButton = ChatSellerButton(listingId: serviceListingId);
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

                  // Display pickup/delivery details if available
                  if (_pickupLocation != null ||
                      _pickupTime != null ||
                      _deliveryTime != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                      child: Container(
                        width: MediaQuery.of(context).size.width * 0.9,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 5)
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Pickup/Delivery Details:",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            const SizedBox(height: 10),
                            if (_pickupLocation != null)
                              Text("Pickup Location: $_pickupLocation",
                                  style: const TextStyle(fontSize: 14)),
                            if (_pickupTime != null)
                              Text("Pickup Time: $_pickupTime",
                                  style: const TextStyle(fontSize: 14)),
                            if (_deliveryTime != null)
                              Text("Delivery Time: $_deliveryTime",
                                  style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 50),

                  // Contact Seller Button
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
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _updateOrderStatusToCompleted,
              child: const Text('Order Received'),
            ),
          ],
        ),
      ),
    );
  }
}
