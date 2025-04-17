import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CartScreen extends StatefulWidget {
  final String userId;

  CartScreen({required this.userId});

  @override
  _CartScreenState createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List<Map<String, dynamic>> cartItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCartItems();
  }

  // Fetch cart items from Firestore
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

  // Calculate total for selected items
  double getTotal() {
    double total = 0.0;
    for (var item in cartItems) {
      if (item['isSelected'] == true) {
        double price = double.tryParse(item['price'].toString()) ?? 0.0;
        int quantity = int.tryParse(item['quantity'].toString()) ?? 0;
        total += price * quantity;
      }
    }
    return total;
  }

  // Handle all checkbox selection
  void selectAll(bool? value) {
    setState(() {
      for (var item in cartItems) {
        item['isSelected'] = value ?? false;
      }
    });
  }

  // Check for existing cart item and update quantity if it exists
  Future<void> _updateCartItem(Map<String, dynamic> newItem) async {
    try {
      // Check if the item already exists in the cart based on listingId
      QuerySnapshot existingItemSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('cartItems')
          .where('listingId', isEqualTo: newItem['listingId'])
          .get();

      if (existingItemSnapshot.docs.isNotEmpty) {
        // If the item exists, get the document ID
        String existingItemId = existingItemSnapshot.docs[0].id;  // Get the document ID
        // Update the quantity of the existing item in the cart
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('cartItems')
            .doc(existingItemId)
            .update({
          'quantity': FieldValue.increment(newItem['quantity']),  // Increment the quantity
        });
      } else {
        // If the item does not exist, add it to the cart
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('cartItems')
            .add(newItem);
      }

      // Refresh the cart items after adding/updating
      _fetchCartItems();
    } catch (e) {
      print("Error updating cart item: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Separate products and services based on the 'listingType'
    List<Map<String, dynamic>> products = cartItems.where((item) => item['listingType'] == 'product').toList();
    List<Map<String, dynamic>> services = cartItems.where((item) => item['listingType'] == 'service').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Shopping Cart'),
      ),
      body: SingleChildScrollView(  // Make the body scrollable to avoid overflow
        child: Column(
          children: [
            // Product Section
            if (products.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('--- Products ---', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ListView.builder(
              shrinkWrap: true,  // Make the ListView take only as much space as it needs
              physics: NeverScrollableScrollPhysics(),  // Disable scrolling for ListView since SingleChildScrollView will handle it
              itemCount: products.length,
              itemBuilder: (context, index) {
                var item = products[index];
                return Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Checkbox
                      Checkbox(
                        value: item['isSelected'] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            item['isSelected'] = value ?? false;
                          });
                        },
                      ),
                      // Item Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['image'] ?? 'default_image_url',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 10),
                      // Item Name and Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'No Name',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              item['status'] ?? 'No Status',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      // Item Price and Quantity
                      Column(
                        children: [
                          Text('RM${double.tryParse(item['price'].toString())?.toStringAsFixed(2) ?? '0.00'}'),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (item['quantity'] > 1) {
                                      item['quantity']--;
                                      _updateCartItem(item); // Update the item in Firestore
                                    }
                                  });
                                },
                              ),
                              Text('${item['quantity']}'),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    item['quantity']++;
                                    _updateCartItem(item); // Update the item in Firestore
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),

            // Service Section
            if (services.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('--- Services ---', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: services.length,
              itemBuilder: (context, index) {
                var item = services[index];
                return Container(
                  margin: EdgeInsets.all(10),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Checkbox
                      Checkbox(
                        value: item['isSelected'] ?? false,
                        onChanged: (bool? value) {
                          setState(() {
                            item['isSelected'] = value ?? false;
                          });
                        },
                      ),
                      // Item Image
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item['image'] ?? 'default_image_url',
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 10),
                      // Item Name and Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['name'] ?? 'No Name',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              item['status'] ?? 'No Status',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      // Item Price and Quantity
                      Column(
                        children: [
                          Text('RM${double.tryParse(item['price'].toString())?.toStringAsFixed(2) ?? '0.00'}'),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.remove),
                                onPressed: () {
                                  setState(() {
                                    if (item['quantity'] > 1) {
                                      item['quantity']--;
                                      _updateCartItem(item); // Update the item in Firestore
                                    }
                                  });
                                },
                              ),
                              Text('${item['quantity']}'),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () {
                                  setState(() {
                                    item['quantity']++;
                                    _updateCartItem(item); // Update the item in Firestore
                                  });
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // "All" Checkbox
              Row(
                children: [
                  Checkbox(
                    value: cartItems.every((item) => item['isSelected'] == true),
                    onChanged: (bool? value) {
                      selectAll(value);
                    },
                  ),
                  Text('All'),
                ],
              ),
              // Total Price
              Text('Total: RM${getTotal().toStringAsFixed(2)}'),
              // Checkout Button
              ElevatedButton(
                onPressed: () {
                  // Implement Checkout logic
                  print('Proceed to checkout');
                },
                child: Text('Checkout (${cartItems.where((item) => item['isSelected'] == true).length})'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
