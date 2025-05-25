import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/chat_service.dart';
import '../../widgets/pageDesign.dart';
import '../../chat/messageDetail.dart';
import '../donno/order.dart';

class ProductCheckoutScreen extends StatefulWidget {
  final String userId;
  final List<Map<String, dynamic>> selectedItems;

  ProductCheckoutScreen({
    required this.userId,
    required this.selectedItems,
  });

  @override
  _ProductCheckoutScreenState createState() => _ProductCheckoutScreenState();
}

class _ProductCheckoutScreenState extends State<ProductCheckoutScreen> {
  int _selectedCollectionOption = 0; // 0 for Self Pick-up, 1 for Delivery
  int _selectedPaymentMethod = 0; // 0 for QR Code, 1 for Cash on Delivery
  TextEditingController _messageController = TextEditingController();
  TextEditingController _deliveryLocationController = TextEditingController();
  String? _message;
  String _errorMessage = '';
  bool _isDeliveryLocationValid = true;

  List<Map<String, dynamic>> cartItems = [];

  final ChatService _chatService = ChatService();

  // Fetch cart items after placing the order
  Future<void> _fetchCartItems() async {
    try {
      QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('cartItems')
          .get();

      // Add cart items to the list
      setState(() {
        cartItems = snapshot.docs.map((doc) {
          return {
            'id': doc.id,
            ...doc.data() as Map<String, dynamic>,
          };
        }).toList();
      });
    } catch (e) {
      print("Error fetching cart items: $e");
    }
  }

  // Calculate total amount for all items in the checkout
  double calculateTotal() {
    double total = 0.0;
    for (var item in widget.selectedItems) {
      total += item['price'] * item['quantity'];
    }
    return total;
  }

  Future<void> placeOrder() async {
    if (_selectedCollectionOption == 1 && _deliveryLocationController.text.isEmpty) {
      setState(() {
        _isDeliveryLocationValid = false;
        _errorMessage = 'Please determine your delivery place'; // Error message
      });
      return;
    } else {
      setState(() {
        _isDeliveryLocationValid = true;
      });
    }

    try {
      final FirebaseFirestore _firestore = FirebaseFirestore.instance;
      final List<Map<String, dynamic>> orderItems = [];

      for (var item in widget.selectedItems) {
        final String listingId = item['listingId'];
        final String cartId = item['cartId'] ?? '';

        DocumentSnapshot listingSnapshot =
        await _firestore.collection('listings').doc(listingId).get();

        String creatorId = listingSnapshot.get('userId');
        String description = listingSnapshot.get('description');
        String listingType = listingSnapshot.get('listingType');

        orderItems.add({
          'listingId': listingId,
          'listingType': listingType,
          'creatorId': creatorId,
          'userId': widget.userId,
          'status': 'Pending for Approval',
          'itemImage': item['image'],
          'itemName': item['name'],
          'itemDescription': description,
          'orderQuantity': item['quantity'],
          'itemPrice': item['price'],
          'totalPrice': item['price'] * item['quantity'],
          'message': _message,
          'collectionOption': _selectedCollectionOption == 0 ? 'Self Pick-up' : 'Delivery',
          'deliveryLocation': _deliveryLocationController.text,
          'paymentMethod': _selectedPaymentMethod == 0 ? 'QR Code' : 'Cash on Delivery',
        });
      }

      final String cartId = widget.selectedItems[0]['cartId'] ?? '';

      DocumentReference orderRef = await _firestore.collection('orders').add({
        'userId': widget.userId,
        'status': 'Pending for Approval',
        'orderTime': FieldValue.serverTimestamp(),
        'message': _message,
        'collectionOption': _selectedCollectionOption == 0 ? 'Self Pick-up' : 'Delivery',
        'deliveryLocation': _selectedCollectionOption == 1 ? _deliveryLocationController.text : null,
        'paymentMethod': _selectedPaymentMethod == 0 ? 'QR Code' : 'Cash on Delivery',
        'totalAmount': calculateTotal(),
        'products': orderItems,
        'cartId': cartId,
      });

      for (var item in widget.selectedItems) {
        await _firestore.collection('users')
            .doc(widget.userId)
            .collection('cartItems')
            .doc(item['cartId'])
            .delete();
      }

      _fetchCartItems();

      final senderId = widget.userId;
      final sentMessages = <String>{};

      if (_message != null && _message!.trim().isNotEmpty) {
        for (var item in orderItems) {
          final receiverId = item['creatorId'];
          if (!sentMessages.contains(receiverId)) {
            await _chatService.sendMessage(
              senderId: senderId,
              receiverId: receiverId,
              messageText: _message!.trim(),
              orderId: orderRef.id,
              productDetails: {
                'listingId': item['listingId'],
                'listingType': item['listingType'],
                'itemImage': item['itemImage'],
                'itemName': item['itemName'],
                'itemDescription': item['itemDescription'],
                'orderQuantity': item['orderQuantity'],
                'itemPrice': item['itemPrice'],
                'totalPrice': item['totalPrice'],
                'collectionOption': item['collectionOption'],
                'deliveryLocation': item['deliveryLocation'],
                'paymentMethod': item['paymentMethod'],
              },
            );
            sentMessages.add(receiverId);
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product order placed successfully!')),
      );

      await _sendOrderNotification(orderRef.id, widget.userId, orderItems);

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageDetailsPage(
            conversationId: 'conversationId', // Replace with actual conversation ID if available
            senderId: widget.userId,
            receiverId: orderItems[0]['creatorId'],
            messageContent: _message ?? '',
          ),
        ),
      );

      Navigator.pop(context, true);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderScreen(orderId: orderRef.id),
        ),
      );
    } catch (e) {
      print('Order failed: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to place order. Try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

// Function to send notifications for both buyer and creator
  Future<void> _sendOrderNotification(String orderId, String buyerId, List<Map<String, dynamic>> orderItems) async {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    for (var item in orderItems) {
      String creatorId = item['creatorId'];

      // For Buyer Notification ('order_placed')
      final buyerNotifQuery = await _firestore
          .collection('users')
          .doc(buyerId)
          .collection('notifications')
          .where('orderId', isEqualTo: orderId)
          .where('type', isEqualTo: 'order_placed')
          .limit(1)
          .get();

      if (buyerNotifQuery.docs.isNotEmpty) {
        // Update existing notification
        await buyerNotifQuery.docs.first.reference.update({
          'message': 'Your order for ${item['itemName']} has been placed.',
          'timestamp': FieldValue.serverTimestamp(),
          'isSeen': false,
          'isSelected': false,
        });
      } else {
        // Create new notification
        await _firestore.collection('users').doc(buyerId).collection('notifications').add({
          'message': 'Your order for ${item['itemName']} has been placed.',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'order_placed',
          'orderId': orderId,
          'category': item['listingType'],
          'userId': buyerId,
          'isSeen': false,
          'isSelected': false,
        });
      }

      // For Creator Notification ('new_order')
      final creatorNotifQuery = await _firestore
          .collection('users')
          .doc(creatorId)
          .collection('notifications')
          .where('orderId', isEqualTo: orderId)
          .where('type', isEqualTo: 'new_order')
          .limit(1)
          .get();

      if (creatorNotifQuery.docs.isNotEmpty) {
        await creatorNotifQuery.docs.first.reference.update({
          'message': 'You have a new order for ${item['itemName']}.',
          'timestamp': FieldValue.serverTimestamp(),
          'isSeen': false,
          'isSelected': false,
        });
      } else {
        await _firestore.collection('users').doc(creatorId).collection('notifications').add({
          'message': 'You have a new order for ${item['itemName']}.',
          'timestamp': FieldValue.serverTimestamp(),
          'type': 'new_order',
          'orderId': orderId,
          'category': item['listingType'],
          'userId': creatorId,
          'isSeen': false,
          'isSelected': false,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,  // Set the background color to yellow
      appBar: customAppBar('Product Checkout'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display selected items
              if (widget.selectedItems.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...widget.selectedItems.map((item) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 10),
                        padding: EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(5),
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            // Item Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                item['image'] ?? 'https://via.placeholder.com/150',
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 10),
                            // Item Info (Name, Price)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['name'] ?? 'No Name',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    'RM${item['price'].toStringAsFixed(2)}',
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                            // Quantity
                            Text('x ${item['quantity']}'),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),

              // 🧾 Wrap all ListTiles in a white container with dividers
              Container(
                margin: EdgeInsets.only(top: 10),
                padding: EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
                  ],
                ),
                child: Column(
                  children: [
                    // Message for Seller
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Message for Seller'),
                      subtitle: Text(_message?.isEmpty ?? true ? 'Please leave a message' : _message!),
                      trailing: Icon(Icons.arrow_forward_ios),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) {
                            return AlertDialog(
                              title: Text('Message for Seller'),
                              content: TextField(
                                controller: _messageController,
                                decoration: InputDecoration(hintText: 'Write your message here'),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _message = _messageController.text;
                                    });
                                    Navigator.pop(context);
                                  },
                                  child: Text('Submit'),
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    Divider(height: 1),

                    // Item Collection Option
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Item Collection Option'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Radio(
                                value: 0,
                                groupValue: _selectedCollectionOption,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedCollectionOption = value!;
                                  });
                                },
                              ),
                              Text('Self Pick-up'),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 1,
                                groupValue: _selectedCollectionOption,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedCollectionOption = value!;
                                  });
                                },
                              ),
                              Text('Delivery'),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Divider(height: 1),

                    // Delivery Location (only show if "Delivery" is selected)
                    if (_selectedCollectionOption == 1) ...[
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text('Delivery Location'),
                        subtitle: TextField(
                          controller: _deliveryLocationController,
                          decoration: InputDecoration(hintText: 'Please determine your delivery place',
                            errorText: _isDeliveryLocationValid ? null : _errorMessage,
                          ),
                        ),
                        trailing: _isDeliveryLocationValid
                            ? null
                            : Icon(Icons.error, color: Colors.red), // Error icon if not valid
                      ),
                      Divider(height: 1),
                    ],

                    // Payment Method
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Payment Method'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Radio(
                                value: 0,
                                groupValue: _selectedPaymentMethod,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                              ),
                              Text('QR Code'),
                            ],
                          ),
                          Row(
                            children: [
                              Radio(
                                value: 1,
                                groupValue: _selectedPaymentMethod,
                                onChanged: (int? value) {
                                  setState(() {
                                    _selectedPaymentMethod = value!;
                                  });
                                },
                              ),
                              Text('Cash on Delivery'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        color: Colors.lightBlue.shade50,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total: RM${calculateTotal().toStringAsFixed(2)}',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              ElevatedButton(
                onPressed: placeOrder,
                child: Text('Place Order'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,  // Set background color
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Square (no rounded corners)
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
