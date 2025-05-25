import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redofyp/page/listing/viewListingDetails.dart';

import '../../widgets/pageDesign.dart';

class ListingScreen extends StatefulWidget {
  @override
  _ListingScreenState createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late FirebaseAuth _auth;
  late String userId;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _tabController = TabController(length: 2, vsync: this);
    _getUserId();
  }

  // Get the current logged-in user's ID
  void _getUserId() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    }
  }

  // Fetch listings from Firestore
  Future<QuerySnapshot> _fetchListings(String listingType) async {
    print("Fetching listings for user ID: $userId");
    try {
      var snapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where('userId', isEqualTo: userId) // Get listings for current user
          .where('listingType', isEqualTo: listingType)
          .get();

      print("Number of listings fetched: ${snapshot.docs.length}");
      return snapshot;
    } catch (e) {
      print("Error fetching listings: $e");
      rethrow;
    }
  }

  // Function to update listing status on Firestore
  Future<void> _updateListingStatus(String listingId, bool value) async {
    try {
      String newStatus = value ? 'active' : 'inactive';
      await FirebaseFirestore.instance.collection('listings').doc(listingId).update({
        'listingStatus': newStatus,
      });
      print('Listing status updated to: $newStatus');
    } catch (e) {
      print("Error updating listing status: $e");
    }
  }

  Widget _buildItemContainer(DocumentSnapshot itemData) {
    // Initial status from Firestore document
    String status = itemData['listingStatus'] ?? 'active';
    ValueNotifier<bool> isActive = ValueNotifier(status == 'active');  // Initialize the switch value based on the status

    // Get values for category, name, quantity, and image
    String category = itemData['category'] ?? 'No category';
    String name = itemData['name'] ?? 'No name';
    int quantity = itemData['quantity'] ?? 0;  // Default to 0 if no quantity is found
    String imageUrl = itemData['image'] ?? '';  // Get the image URL

    return Container(
      margin: EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Left: Image
          imageUrl.isNotEmpty
              ? Image.network(imageUrl, height: 60, width: 60, fit: BoxFit.cover)
              : Image.asset('assets/placeholder_image.png', height: 60, width: 60),
          SizedBox(width: 12),

          // Right: Description, Category, Name, Quantity, Status, Active/Inactive label, and View More
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category, Name, and Quantity in one container, placed next to the image
                Container(
                  margin: EdgeInsets.only(bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category
                      Text(
                        category,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      SizedBox(height: 4),

                      // Product Name
                      Text(
                        name,
                        style: TextStyle(fontSize: 14),
                      ),

                      // Quantity if greater than 0
                      if (quantity > 0)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            "Quantity: $quantity",
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                    ],
                  ),
                ),

                // View More Button
                Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    onTap: () {
                      String listingId = itemData.id;  // Use the document ID directly
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewListingDetailsScreen(listingId: listingId),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("View more", style: TextStyle(color: Colors.blue, fontSize: 12)),
                        Icon(Icons.arrow_drop_down, color: Colors.blue, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Active/Inactive Label and Toggle Switch at the top right of the container
          Positioned(
            right: 12,
            top: 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Row for "Status" and Active/Inactive side by side
                Row(
                  children: [
                    // "Status: " label (always black)
                    Text(
                      'Status: ',
                      style: TextStyle(
                        color: Colors.black, // "Status" label color is always black
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    // Active/Inactive text (changes color based on the status)
                    ValueListenableBuilder<bool>(
                      valueListenable: isActive,
                      builder: (context, isActiveValue, child) {
                        return Text(
                          isActiveValue ? 'Active' : 'Inactive',
                          style: TextStyle(
                            color: isActiveValue ? Colors.green : Colors.red, // Change color dynamically
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ],
                ),

                // Status Toggle Switch below the label
                Transform.scale(
                  scale: 0.6, // Adjust the scale to make the switch smaller
                  child: ValueListenableBuilder<bool>(
                    valueListenable: isActive,
                    builder: (context, isActiveValue, child) {
                      return Switch(
                        value: isActiveValue,
                        activeColor: Colors.green,
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey[300],
                        onChanged: (value) {
                          // Update the status without rebuilding the widget
                          _updateListingStatus(itemData.id, value);
                          // Update the local value in the notifier
                          isActive.value = value;
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget build(BuildContext context) {
    return Scaffold(
      // Use the customAppBar function here
      backgroundColor: Colors.yellow.shade50,
      appBar: customAppBar('Listings'), // Title 'Listings' for the AppBar
      body: DefaultTabController(
        length: 2, // Number of tabs (Service and Product)
        child: Column(
          children: [
            // TabBar at the top
            TabBar(
              controller: _tabController,
              tabs: [
                Tab(text: 'Service'),
                Tab(text: 'Product'),
              ],
            ),
            // TabBarView for showing content for each tab
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  FutureBuilder<QuerySnapshot>(
                    future: _fetchListings('service'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No services available.'));
                      }
                      var serviceData = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: serviceData.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot item = serviceData[index];
                          return _buildItemContainer(item);
                        },
                      );
                    },
                  ),
                  FutureBuilder<QuerySnapshot>(
                    future: _fetchListings('product'),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(child: Text('No products available.'));
                      }
                      var productData = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: productData.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot item = productData[index];
                          return _buildItemContainer(item);
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}