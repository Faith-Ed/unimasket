import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'order.dart';

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

  List<Map<String, dynamic>> cartItems = [];

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

      // Create the order with products as an array
      DocumentReference orderRef = await _firestore.collection('orders').add({
        'userId': widget.userId,
        'status': 'Pending for Approval',
        'orderTime': FieldValue.serverTimestamp(),
        'message': _message,
        'collectionOption': _selectedCollectionOption == 0 ? 'Self Pick-up' : 'Delivery',
        'deliveryLocation':
        _selectedCollectionOption == 1 ? _deliveryLocationController.text : null,
        'paymentMethod': _selectedPaymentMethod == 0 ? 'QR Code' : 'Cash on Delivery',
        'totalAmount': calculateTotal(),
        'products': orderItems, // Store products in an array
        'cartId': cartId,
      });

      // Remove the items from the cartItems subcollection
      for (var item in widget.selectedItems) {
        await _firestore.collection('users')
            .doc(widget.userId) // The user ID
            .collection('cartItems') // The cartItems subcollection
            .doc(item['cartId']) // The unique cart item ID
            .delete();
      }

      // Refresh the cart items after deletion
      _fetchCartItems();  // Fetch the updated cart

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Product order placed successfully!')),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Product Checkout'),
      ),
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
                              Text('Self Pick-up (Location)'),
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
                          decoration: InputDecoration(hintText: 'Please determine your delivery place'),
                        ),
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
        color: Colors.blueGrey[100],
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
                  backgroundColor: Colors.green,  // Set background color
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
