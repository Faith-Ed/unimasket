import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redofyp/page/serviceCheckout.dart';
import 'productCheckout.dart';

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

    // Listen for the result after navigating back
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final result = ModalRoute.of(context)?.settings.arguments;
      if (result == true) {
        // If 'true' is passed back, refresh the cart items
        _fetchCartItems();
      }
    });
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
  Future<void> _updateCartItem(Map<String, dynamic> updatedItem) async {
    try {
      // Check if the item already exists in the cart based on listingId
      QuerySnapshot existingItemSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('cartItems')
          .where('listingId', isEqualTo: updatedItem['listingId'])
          .get();

      if (existingItemSnapshot.docs.isNotEmpty) {
        // If the item exists, get the document ID
        String existingItemId = existingItemSnapshot.docs[0].id;  // Get the document ID
        // Update the quantity directly (do not use increment)
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('cartItems')
            .doc(existingItemId)
            .update({
          'quantity': updatedItem['quantity'],  // Directly set the quantity
        });
      } else {
        // If the item does not exist, add it to the cart
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('cartItems')
            .add(updatedItem);
      }

      // Refresh the cart items after adding/updating
      _fetchCartItems();
    } catch (e) {
      print("Error updating cart item: $e");
    }
  }

  // Delete selected items
  Future<void> _deleteSelectedItems() async {
    try {
      List<String> itemsToDelete = cartItems
          .where((item) => item['isSelected'] == true)
          .map((item) => item['id'] as String)
          .toList();

      for (var itemId in itemsToDelete) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('cartItems')
            .doc(itemId)
            .delete();
      }

      // Refresh the cart items after deletion
      _fetchCartItems();
    } catch (e) {
      print("Error deleting cart items: $e");
    }
  }

  // Show confirmation dialog before deleting
  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete the selected item(s)?"),
          actions: <Widget>[
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('No'),
                style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    )
                )
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteSelectedItems();  // Proceed with deleting the selected items
              },
              child: Text('Yes'),
                style: ElevatedButton.styleFrom(
                    side: BorderSide(color: Colors.lightBlue, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(5),
                    )
                )
            ),
          ],
        );
      },
    );
  }

// Check stock availability for each item
  Future<int> _getAvailableStock(String listingId) async {
    try {
      // Fetch the listing document from the 'listings' collection using the listingId
      DocumentSnapshot listingDoc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId) // Use the listingId from the cart item
          .get();

      // Check if the listing exists
      if (listingDoc.exists) {
        // Retrieve the available stock (quantity) from the listing
        return listingDoc['quantity'] ?? 0; // Assuming 'quantity' field is in the listing document
      } else {
        // If the listing doesn't exist, return 0
        return 0;
      }
    } catch (e) {
      print("Error fetching available stock: $e");
      return 0; // Return 0 if there's an error
    }
  }


  @override
  Widget build(BuildContext context) {
    // Separate products and services based on the 'listingType'
    List<Map<String, dynamic>> products = cartItems.where((item) => item['listingType'] == 'product').toList();
    List<Map<String, dynamic>> services = cartItems.where((item) => item['listingType'] == 'service').toList();

    // Check if any item is selected to show the delete button in the AppBar
    bool isAnyItemSelected = cartItems.any((item) => item['isSelected'] == true);

    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // Set the height of the AppBar
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),  // Set left bottom corner radius
            bottomRight: Radius.circular(10),  // Set right bottom corner radius
          ),
          child: AppBar(
            toolbarHeight: 80, // Toolbar height remains as per your request
            title: Text('Shopping Cart', style: TextStyle(color: Colors.white)),
            backgroundColor: CupertinoColors.systemYellow,
        actions: [
          // Only show the delete icon if any item is selected
          if (isAnyItemSelected)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: _showDeleteConfirmationDialog,  // Show the confirmation dialog
            ),
        ],
      ),),),
      body: SingleChildScrollView(  // Make the body scrollable to avoid overflow
        child: Column(
          children: [
            // Product Section
            if (products.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  width: double.infinity,  // Make it take up the full width of the screen
                  padding: EdgeInsets.symmetric(vertical: 10.0),  // Add vertical padding
                  color: Colors.black,  // Set background color to black
                  child: Text(
                    '--- Products ---',
                    style: TextStyle(
                      color: Colors.white,  // Set text color to white
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                            // Show error message if stock is exceeded
                            if (item['errorMessage'] != '')
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),  // Small space before error message
                                child: Text(
                                  item['errorMessage'] ?? '',
                                  style: TextStyle(color: Colors.red, fontSize: 12),
                                ),
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
                                onPressed: () async {
                                  if (item['quantity'] > 1) {
                                    setState(() {
                                      item['quantity']--;
                                    });
                                    await _updateCartItem(item); // Update the item in Firestore
                                  }
                                },
                              ),
                              Text('${item['quantity']}'),
                              IconButton(
                                icon: Icon(Icons.add),
                                onPressed: () async {
                                  int availableStock = await _getAvailableStock(item['listingId']);  // Get available stock

                                  if (item['quantity'] < availableStock) {
                                    setState(() {
                                      item['quantity']++;
                                    });
                                    await _updateCartItem(item); // Update the item in Firestore
                                  } else {
                                    setState(() {
                                      item['errorMessage'] = 'Only $availableStock item available.'; // Set error message
                                    });
                                  }
                                },
                              )
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
                child: Container(
                  width: double.infinity,  // Make it take up the full width of the screen
                  padding: EdgeInsets.symmetric(vertical: 10.0),  // Add vertical padding
                  color: Colors.black,  // Set background color to black
                  child: Text(
                    '--- Services ---',
                    style: TextStyle(
                      color: Colors.white,  // Set text color to white
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
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
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Service Time:',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 4),
                          Text(
                            item['serviceTime'] ?? 'N/A',  // Display service time from cart item
                            style: TextStyle(fontSize: 14, color: Colors.grey),
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
        color: Colors.lightBlue.shade50,
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
                  // Gather selected items for checkout
                  List<Map<String, dynamic>> selectedItems = cartItems
                      .where((item) => item['isSelected'] == true)
                      .toList();

                  // Check if selected items are available for preview
                  if (selectedItems.isEmpty) {
                    // Show a message if no items are selected
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Please select some items to checkout!'),
                    ));
                    return;
                  }

                  // Navigate to the appropriate checkout page based on the listing type
                  String listingType = selectedItems.isNotEmpty ? selectedItems[0]['listingType'] : '';

                  if (listingType == 'product') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProductCheckoutScreen(
                          userId: widget.userId,
                          selectedItems: cartItems
                              .where((item) => item['isSelected'] == true)
                              .map((item) {
                            return {
                              'cartId': item['id'],  // Pass the document ID as cartId
                              'listingId': item['listingId'],
                              'name': item['name'],
                              'price': item['price'],
                              'quantity': item['quantity'],
                              'image': item['image'],
                            };
                          }).toList(),  // Pass the selected items
                        ),
                      ),
                    );
                  } else if (listingType == 'service') {
                    // If it’s a service item, you can implement a similar navigation for ServiceCheckoutScreen
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServiceCheckoutScreen(
                          userId: widget.userId,
                          selectedItems: cartItems
                              .where((item) => item['isSelected'] == true)
                              .map((item) {
                            return {
                              'cartId': item['id'],  // Pass the document ID as cartId
                              'listingId': item['listingId'],
                              'name': item['name'],
                              'price': item['price'],
                              'quantity': item['quantity'],
                              'image': item['image'],
                              'serviceTime': item['serviceTime'],
                            };
                          }).toList(),
                        ),
                      ),
                    );
                  }
                },
                child: Text('Checkout (${cartItems.where((item) => item['isSelected'] == true).length})'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,  // Set background color
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
