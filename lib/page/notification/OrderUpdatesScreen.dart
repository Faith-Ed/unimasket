import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:redofyp/page/buyerTracker/pendingOrder.dart';
import 'package:redofyp/page/seller/sellerAccept.dart';
import 'package:redofyp/page/seller/sellerComplete.dart';
import 'package:redofyp/page/seller/sellerDecline.dart';
import 'package:redofyp/widgets/pageDesign.dart';
import 'package:redofyp/page/seller/toApprove.dart';
import '../buyerTracker/buyerOrderAccepted.dart';
import '../buyerTracker/buyerOrderComplete.dart';
import '../buyerTracker/buyerOrderDeclined.dart';
import '../donno/order.dart';

class OrderUpdatesScreen extends StatefulWidget {
  @override
  _OrderUpdatesScreenState createState() => _OrderUpdatesScreenState();
}

class _OrderUpdatesScreenState extends State<OrderUpdatesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;

  final String cloudPlaceholderUrl =
      'https://res.cloudinary.com/demo/image/upload/dgou42nni/default-placeholder.jpg';

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
  }

  Future<void> _markNotificationSelected(String notificationId) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(_user.uid)
        .collection('notifications')
        .doc(notificationId)
        .update({'isSelected': true});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: customAppBar('Order Updates'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(_user.uid)
              .collection('notifications')
              .where('type', whereIn: [
            'order_placed',
            'new_order',
            'order_accepted',
            'order_declined',
            'order_completed',
            'seller_accepted',
            'seller_declined',
            'seller_order_completed'
          ])
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error fetching notifications'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Center(child: Text('No new notifications'));
            }

            final notifications = snapshot.data!.docs;

            return ListView.builder(
              itemCount: notifications.length,
              itemBuilder: (context, index) {
                var notificationDoc = notifications[index];
                var notification = notificationDoc.data() as Map<String, dynamic>;
                var notificationId = notificationDoc.id;
                var timestamp = notification['timestamp'];
                String formattedTime = timestamp != null
                    ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                    : '';
                var message = notification['message'] ?? 'No message available.';
                var notificationType = notification['type'] ?? '';
                var orderId = notification['orderId'] ?? '';
                bool isSelected = notification['isSelected'] ?? false;

                // Fetch order details from 'orders' collection using orderId
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('orders').doc(orderId).get(),
                  builder: (context, orderSnapshot) {
                    if (orderSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(title: Text('Loading order details...'));
                    }
                    if (orderSnapshot.hasError) {
                      return ListTile(title: Text('Error loading order details'));
                    }
                    if (!orderSnapshot.hasData || !orderSnapshot.data!.exists) {
                      return ListTile(title: Text('No data found for this order'));
                    }

                    var orderData = orderSnapshot.data!.data() as Map<String, dynamic>?;

                    if (orderData == null) {
                      return ListTile(title: Text('No order data available'));
                    }

                    String? listingImage;
                    String status = orderData['status'] ?? 'Pending';

                    // Product image fetching
                    List<dynamic>? productList = orderData['products'];
                    if (productList != null && productList.isNotEmpty) {
                      final firstProduct = productList[0];
                      if (firstProduct is Map<String, dynamic>) {
                        String? imageUrl = firstProduct['itemImage'];
                        if (imageUrl != null && imageUrl.isNotEmpty) {
                          listingImage = imageUrl;
                        }
                      }
                    } else {
                      // Service image fetching
                      Map<String, dynamic>? services = orderData['services'] != null
                          ? Map<String, dynamic>.from(orderData['services'])
                          : null;
                      if (services != null) {
                        String? serviceImage = services['serviceImage'];
                        if (serviceImage != null && serviceImage.isNotEmpty) {
                          listingImage = serviceImage;
                        }
                      }
                    }

                    return Card(
                      color: isSelected ? Colors.grey[200] : Colors.red[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () async {
                          await _markNotificationSelected(notificationId);
                          setState(() {});

                          if (orderId.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Invalid order data. Please try again.')),
                            );
                            return;
                          }

                          if (notificationType == 'order_placed') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => OrderScreen(orderId: orderId)),
                            );
                          } else if (notificationType == 'new_order') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ToApproveScreen(orderId: orderId)),
                            );
                          } else if (notificationType == 'order_accepted') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuyerOrderAcceptedScreen(
                                  orderId: orderId,
                                  userId: _user.uid,
                                ),
                              ),
                            );
                          } else if (notificationType == 'order_declined') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuyerOrderDeclineScreen(
                                  orderId: orderId,
                                  userId: _user.uid,
                                ),
                              ),
                            );
                          } else if (notificationType == 'order_completed') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BuyerOrderCompleteScreen(
                                  orderId: orderId,
                                  userId: _user.uid,
                                ),
                              ),
                            );
                          } else if (notificationType == 'seller_accepted') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellerAcceptOrderScreen(orderId: orderId),
                              ),
                            );
                          } else if (notificationType == 'seller_declined') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DeclineOrderScreen(orderId: orderId),
                              ),
                            );
                          } else if (notificationType == 'seller_order_completed') {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SellerCompleteScreen(
                                  orderId: orderId,
                                  userId: _user.uid,
                                ),
                              ),
                            );
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  listingImage?.isNotEmpty == true ? listingImage! : cloudPlaceholderUrl,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Image.network(
                                      cloudPlaceholderUrl,
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (!isSelected)
                                          Icon(Icons.circle, color: Colors.red, size: 8),
                                        if (!isSelected) const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            notificationType == 'order_accepted'
                                                ? 'Order Accepted'
                                                : notificationType == 'order_declined'
                                                ? 'Order Declined'
                                                : 'Order $status',
                                            style: TextStyle(
                                              fontWeight:
                                              isSelected ? FontWeight.normal : FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      message,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formattedTime,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
