import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redofyp/page/home.dart';
import 'package:redofyp/page/time_picker_helper.dart';
import 'cart.dart';

class ViewListingDetailsScreen extends StatefulWidget {
  final String listingId; // Listing ID passed to the screen
  ViewListingDetailsScreen({required this.listingId});

  @override
  _ViewListingDetailsScreenState createState() => _ViewListingDetailsScreenState();
}

class _ViewListingDetailsScreenState extends State<ViewListingDetailsScreen> {
  late Map<String, dynamic> _listingData = {};
  late Map<String, dynamic> _creatorData = {};
  late String _listingCreatorId;
  late String _category;
  late List<dynamic> _similarListings = [];
  String? _creatorProfileImageUrl;
  int _quantity = 1;
  TextEditingController _serviceTimeController = TextEditingController();
  bool _isDescriptionExpanded = false;
  bool _isBottomSheetOpen = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getListingDetails();
  }

  @override
  void dispose() {
    // Safely close the bottom sheet and clean up the controller
    if (_isBottomSheetOpen) {
      Navigator.pop(context);  // Close bottom sheet if open
    }
    super.dispose();
  }

  Future<void> _getListingDetails() async {
    try {
      // Get the listing details from Firestore
      DocumentSnapshot listingSnapshot = await FirebaseFirestore.instance.collection('listings').doc(widget.listingId).get();
      if (!listingSnapshot.exists) {
        print("Listing not found");
        return;
      }
      _listingData = listingSnapshot.data() as Map<String, dynamic>;

      // Retrieve the userId (creator) from the listing data
      _listingCreatorId = _listingData['userId'];

      // Fetch the creator's profile image
      await _fetchCreatorProfileImage(_listingCreatorId);

      // Get the listing creator's data using userId
      DocumentSnapshot creatorSnapshot = await FirebaseFirestore.instance.collection('users').doc(_listingCreatorId).get();
      if (creatorSnapshot.exists) {
        _creatorData = creatorSnapshot.data() as Map<String, dynamic>;
        print("Creator data fetched: $_creatorData");
      } else {
        print("No creator data found");
        return;
      }

      // Get similar listings from the same category
      _category = _listingData['category'];
      QuerySnapshot similarListingsSnapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where('category', isEqualTo: _category)
          .get();

      // Filter out the current listing by document ID (using doc.id)
      _similarListings = similarListingsSnapshot.docs
          .where((doc) => doc.id != widget.listingId)  // Exclude the current listing by document ID
          .map((doc) => {
        'id': doc.id,  // Add the doc ID here to make sure it's available
        ...doc.data() as Map<String, dynamic>,  // Add the document data
      })
          .toList();

      setState(() {});
    } catch (e) {
      print("Error fetching listing details: $e");
    }
  }

  // Fetch the creator's profile image from the subcollection `photo_profile`
  Future<void> _fetchCreatorProfileImage(String creatorId) async {
    try {
      final photoDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(creatorId)
          .collection('photo_profile')
          .doc('profile')
          .get();

      if (photoDoc.exists) {
        setState(() {
          _creatorProfileImageUrl = photoDoc['url'];  // Assign the image URL
          print("Creator profile image fetched: $_creatorProfileImageUrl");
        });
      } else {
        print("No profile image found for creator");
      }
    } catch (e) {
      print("Error fetching creator's profile image: $e");
    }
  }
  // Function to show error pop-up
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Open the bottom sheet for adding to cart
  void _openBottomSheet() {
    bool isProduct = _listingData['listingType'] == 'product';
    int availableQuantity = int.tryParse(_listingData['quantity'].toString()) ?? 0; // Convert to int
    _quantity = 1;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        _isBottomSheetOpen = true;
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              padding: EdgeInsets.all(16.0),
              height: 400,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product or service image
                  Image.network(
                    _listingData['image'] ?? 'default_image_url',
                    height: 120,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  SizedBox(height: 16),

                  // Product or service name and price
                  Text(
                    _listingData['name'] ?? 'No Name',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '\$${_listingData['price']}',
                    style: TextStyle(fontSize: 28, color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),

                  // Check if it's a product or a service and show the appropriate bottom sheet content
                  if (isProduct) ...[
                    // Show available quantity for products
                    Text(
                      'Available Stocks: $availableQuantity',
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 16),

                    // Quantity control (minus, number, plus) for products
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Quantity label
                        Text(
                          'Quantity',
                          style: TextStyle(fontSize: 16),
                        ),
                        // Quantity control (minus, number, plus)
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_quantity > 1) {
                                    _quantity--;
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(Icons.remove, size: 20, color: Colors.black),
                              ),
                            ),
                            SizedBox(width: 8),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                '$_quantity', // Display the current quantity
                                style: TextStyle(fontSize: 20),
                              ),
                            ),
                            SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (_quantity < availableQuantity) {
                                    _quantity++;
                                  }
                                });
                              },
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(8.0),
                                ),
                                child: Icon(Icons.add, size: 20, color: Colors.black),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ] else ...[
                    // For service: show a time input field
                    Text(
                      'Enter the date and time for the service:',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    GestureDetector(
                      onTap: () async {
                        print("Text field tapped!");
                        String? selectedTime = await TimePickerHelper.pickServiceTime(context);
                        if (selectedTime != null) {
                          setState(() {
                            _serviceTimeController.text = selectedTime;
                          });
                        }
                      },
                      child: AbsorbPointer (
                        child: TextFormField(
                          controller: _serviceTimeController,
                          decoration: InputDecoration(
                            labelText: 'Service Time',
                            hintText: 'Select time for service',
                            border: OutlineInputBorder(),
                            suffixIcon: Icon(Icons.access_time),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 16),
                  // Spacer to push the button to the bottom
                  Spacer(),

                  // Add to Cart Button (centered)
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        User? user = FirebaseAuth.instance.currentUser;

                        if (user != null) {
                          String userId = user.uid;

                          Map<String, dynamic> cartItem = {
                            'name': _listingData['name'],
                            'price': _listingData['price'],
                            'quantity': _quantity,
                            'image': _listingData['image'],
                            'listingType': _listingData['listingType'],
                            'status': 'In Stock',
                            'isSelected': false,
                            'listingId': widget.listingId,
                            'serviceTime': _serviceTimeController.text,
                          };

                          // Check for quantity comparison
                          DocumentSnapshot listingSnapshot = await FirebaseFirestore.instance
                              .collection('listings')
                              .doc(widget.listingId)
                              .get();
                          int availableQuantity = int.tryParse(listingSnapshot['quantity'].toString()) ?? 0;

                          FirebaseFirestore.instance
                              .collection('users')
                              .doc(userId)
                              .collection('cartItems')
                              .where('listingId', isEqualTo: widget.listingId)
                              .get()
                              .then((querySnapshot) async {
                            if (querySnapshot.docs.isEmpty) {
                              // If the item does not exist, check quantity
                              if (_quantity > availableQuantity) {
                                setState(() {
                                  _errorMessage;
                                });
                                _showErrorDialog(_errorMessage); // Show error dialog
                                return;
                              }
                              await FirebaseFirestore.instance.collection('users').doc(userId).collection('cartItems').add(cartItem);
                            } else {
                              String docId = querySnapshot.docs.first.id;
                              var cartItemData = querySnapshot.docs.first.data();
                              int cartItemQuantity = cartItemData['quantity'];

                              if (cartItemQuantity + _quantity > availableQuantity) {
                                setState(() {
                                  _errorMessage = "Exceed available stock. Please check your cart";
                                });
                                _showErrorDialog(_errorMessage); // Show error dialog
                                return;
                              }

                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(userId)
                                  .collection('cartItems')
                                  .doc(docId)
                                  .update({
                                'quantity': FieldValue.increment(_quantity),
                              });
                            }

                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => CartScreen(userId: userId),
                              ),
                            );
                          }).catchError((e) {
                            print("Error checking item in cart: $e");
                          });
                        } else {
                          print("User is not logged in");
                        }
                      },
                      child: Text('Add to Cart'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.green,
                        textStyle: TextStyle(fontSize: 18),
                        minimumSize: Size(double.infinity, 50),
                      ),
                    ),
                  ),
                  if (_errorMessage.isNotEmpty) ...[
                    Text(
                      _errorMessage,
                      style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                    ),
                  ]
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to the cart screen
            },
          ),
          PopupMenuButton<String>(

            onSelected: (value) {
              // Navigate to home page
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (context) => HomeScreen()),
                    (Route<dynamic> route) => false,
              );
            },
            itemBuilder: (BuildContext context) {
              return ['Home'].map((String choice) {
                return PopupMenuItem<String>(value: choice, child: Text(choice));
              }).toList();
            },
          ),
        ],
      ),
      body: _listingData.isEmpty
          ? Center(child: CircularProgressIndicator()) // Show loading indicator
          : ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Image.network(_listingData['image']),
          SizedBox(height: 16),
          Text(
            '\$${_listingData['price']}',
            style: TextStyle(fontSize: 28, color: Colors.red, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            _listingData['name'] ?? '',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Divider(
            color: Colors.grey[300],
            thickness: 1,
          ),
          SizedBox(height: 5),
          // Description: Display description with truncation if needed
          Text(
            "Description",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          _isDescriptionExpanded
              ? Text(
            _listingData['description'] ?? '',
            style: TextStyle(fontSize: 16),
          )
              : Text(
            (_listingData['description'] ?? '').length > 100
                ? (_listingData['description'] as String).substring(0, 100) + "..."
                : _listingData['description'] ?? '',
            style: TextStyle(fontSize: 16),
          ),
          _listingData['description'] != null && (_listingData['description'] as String).length > 100
              ? GestureDetector(
            onTap: () {
              setState(() {
                _isDescriptionExpanded = !_isDescriptionExpanded;
              });
            },
            child: Row(
              children: [
                Text(
                  _isDescriptionExpanded ? 'See less' : 'See more',
                  style: TextStyle(color: Colors.blue),
                ),
                Icon(
                  _isDescriptionExpanded ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: Colors.blue,
                ),
              ],
            ),
          )
              : SizedBox.shrink(),
          SizedBox(height: 16),
          Divider(
            color: Colors.grey[300],  // Line color
            thickness: 1,  // Thickness of the divider
          ),
          SizedBox(height: 5),
          // Creator's profile in a container (with profile image and see profile link)
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blueGrey[50], // Background color
              borderRadius: BorderRadius.circular(10), // Rounded corners
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, // To space out the text and "See Profile" link
              children: [
                Row(
                  children: [
                    _creatorProfileImageUrl != null
                        ? CircleAvatar(
                      radius: 20,
                      backgroundImage: NetworkImage(_creatorProfileImageUrl!),
                    )
                        : CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.grey,
                      child: Icon(Icons.person, size: 50, color: Colors.white),
                    ),
                    SizedBox(width: 10),
                    Text(
                      _creatorData['fullname'] ?? 'No Name',
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    // Navigate to the creator's profile page (replace with actual navigation)
                    print('Navigate to creator profile');
                  },
                  child: Row(
                    children: [
                      Text(
                        'See Profile',
                        style: TextStyle(fontSize: 16, color: Colors.blue[600], fontWeight: FontWeight.w300),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: Colors.blue[600],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),
          // Similar Listings Title (Centered)
          Center(
            child: Text(
              '--- Similar Listings ---',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(height: 8),
          // Check if there are similar listings
          _similarListings.isEmpty
              ? Center( // Centering the "No similar listings" message
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                'No similar listings available.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ),
          )
              : GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,  // Two columns
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 8.0,
              childAspectRatio: 0.75, // Adjust the aspect ratio of the cards
            ),
            itemCount: _similarListings.length,
            itemBuilder: (context, index) {
              var listing = _similarListings[index];
              return Card(
                margin: EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    // Ensure the 'id' field is not null before navigating
                    String listingId = listing['id'] ?? 'default_id';  // Use the correct field for the ID
                    print('Listing ID: $listingId');  // Log the listingId

                    // Navigate to ViewListingDetails screen when a card is tapped
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ViewListingDetailsScreen(listingId: listingId),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.network(
                        listing['image'] ?? 'default_image_url',
                        height: 120,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          listing['name'] ?? 'No Name',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '\$${listing['price']}',
                          style: TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Chat with seller button
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.all(10),
                ),
                onPressed: () {
                  // Start a chat with the seller
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(sellerId: _listingCreatorId),
                    ),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.chat, size: 20, color: Colors.red), // Icon for chat with seller
                    SizedBox(height: 4), // Small space between icon and label
                    Text('Chat with Seller', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            SizedBox(width: 10),
            // Add to cart button
            Expanded(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.all(10),
                ),
                onPressed: () {
                  // Open slide up panel for quantity adjustment
                  _openBottomSheet();
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shopping_cart, size: 20, color: Colors.red), // Icon for add to cart
                    SizedBox(height: 4), // Small space between icon and label
                    Text('Add to Cart', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Open AI chatbot
        },
        child: Icon(Icons.android),
        tooltip: 'AI Chatbot',
      ),
    );
  }
}

class ChatScreen extends StatelessWidget {
  final String sellerId;

  ChatScreen({required this.sellerId});

  @override
  Widget build(BuildContext context) {
    // Replace with a real chat interface
    return Scaffold(
      appBar: AppBar(
        title: Text('Chat with Seller'),
      ),
      body: Center(
        child: Text('Chat with seller $sellerId'),
      ),
    );
  }
}
