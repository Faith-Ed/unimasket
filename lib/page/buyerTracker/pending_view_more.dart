import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../../widgets/chatSellerButton.dart';
import '../../widgets/pageDesign.dart';

class PendingViewMoreScreen extends StatefulWidget {
  final String orderId;
  final String creatorId; // The seller whose products we want to show

  const PendingViewMoreScreen({
    super.key,
    required this.orderId,
    required this.creatorId,
  });

  @override
  State<PendingViewMoreScreen> createState() => _PendingViewMoreScreenState();
}

class _PendingViewMoreScreenState extends State<PendingViewMoreScreen> {
  late Future<DocumentSnapshot> _orderFuture;

  @override
  void initState() {
    super.initState();
    _orderFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get()
        .then((snapshot) {
      if (snapshot.exists) {
        return snapshot;
      } else {
        throw Exception('Order not found');
      }
    });
  }

  String formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';
    return DateFormat('yyyy-MM-dd HH:mm').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: customAppBar('Seller Products Details'),
      body: FutureBuilder<DocumentSnapshot>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Order not found."));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          final List products = data['products'] ?? [];
          final Map<String, dynamic> services = data['services'] ?? {};

          // Filter products by creatorId (seller)
          final sellerProducts = products.where((product) {
            if (product is Map<String, dynamic>) {
              return product['creatorId'] == widget.creatorId;
            }
            return false;
          }).toList();

          final String status = data['status'] ?? 'Unknown';
          final Timestamp? orderTimestamp = data['orderTime'];
          final String orderDate = formatTimestamp(orderTimestamp);
          final String orderId = snapshot.data!.id;
          final String collectionOption = data['collectionOption'] ?? 'N/A';
          final String paymentMethod = data['paymentMethod'] ?? 'N/A';

          // Calculate total price for this seller's products only
          double totalPrice = 0.0;
          for (var product in sellerProducts) {
            totalPrice += product['totalPrice'] ?? 0.0;
          }

          // Note: Service is order-level, so do NOT add service price here
          // unless you want to show service separately

          String listingId = sellerProducts.isNotEmpty ? sellerProducts[0]['listingId'] : '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Status
                  const Text(
                    "ORDER STATUS:",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    status.toUpperCase(),
                    style: const TextStyle(color: Colors.green, fontSize: 16),
                  ),
                  const SizedBox(height: 20),

                  ...sellerProducts.map((product) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.zero,
                      ),
                      child: Row(
                        children: [
                          Image.network(
                            product['itemImage'] ?? 'https://via.placeholder.com/150',
                            height: 70,
                            width: 70,
                            fit: BoxFit.cover,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(product['itemName'] ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (product['itemDescription'] != null)
                                  Text(product['itemDescription']),
                                Text("Quantity: ${product['orderQuantity'] ?? 'N/A'}"),
                                Text("Total: RM ${product['totalPrice']?.toStringAsFixed(2) ?? '0.00'}"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),

                  const SizedBox(height: 10),
                  // Collection Option and Payment Method
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Collection Option: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        collectionOption,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Payment Method: ",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        paymentMethod,
                        style: const TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Total for this seller's products only
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Overall Total:",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        "RM ${totalPrice.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Order Info
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Order No: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextSpan(
                          text: widget.orderId,
                          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(
                          text: 'Order Date: ',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        TextSpan(
                          text: orderDate,
                          style: const TextStyle(fontWeight: FontWeight.normal, fontSize: 16),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Contact Seller Button
                  Align(
                    alignment: Alignment.bottomRight,
                    child: ChatSellerButton(listingId: listingId), // Pass listingId for chat
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
