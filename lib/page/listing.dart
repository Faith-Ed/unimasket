import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'listingDetails.dart'; // Import listingDetails.dart to use it

class ListingScreen extends StatefulWidget {
  @override
  _ListingScreenState createState() => _ListingScreenState();
}

class _ListingScreenState extends State<ListingScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  late FirebaseAuth _auth;
  late String userId;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(vsync: this, duration: Duration(seconds: 1));
    _getUserId();
  }

  void _getUserId() {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        userId = user.uid;
      });
    }
  }

  Future<QuerySnapshot> _fetchListings(String listingType) {
    return FirebaseFirestore.instance
        .collection('listings')
        .where('userId', isEqualTo: userId)
        .where('listingType', isEqualTo: listingType)
        .get();
  }

  // Show modal bottom sheet for selecting status
  void _showStatusOptions(String listingId, String currentStatus) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text('Active'),
                onTap: () {
                  _updateListingStatus(listingId, 'active');
                  Navigator.pop(context);
                },
              ),
              ListTile(
                title: Text('Inactive'),
                onTap: () {
                  _updateListingStatus(listingId, 'inactive');
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Update the listing status in Firestore
  Future<void> _updateListingStatus(String listingId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('listings').doc(listingId).update({
        'listingStatus': newStatus,
      });
      setState(() {}); // Trigger a UI update
    } catch (e) {
      print("Error updating listing status: $e");
    }
  }

  Widget _buildItemContainer(Map<String, dynamic> itemData) {
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
          itemData['image'] != null
              ? Image.network(itemData['image'], height: 60, width: 60, fit: BoxFit.cover)
              : Image.asset('assets/placeholder_image.png', height: 60, width: 60),
          SizedBox(width: 12),
          // Right: Description & View More
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Category (left) + Status (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      itemData['category'] ?? 'No category',  // Provide a fallback in case category is null
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    InkWell(
                      onTap: () {
                        // Show the bottom sheet when the status is tapped
                        _showStatusOptions(itemData['id'], itemData['listingStatus'] ?? 'inactive');
                      },
                      child: Text(
                        // If listingStatus is null, use 'No status'
                        itemData['listingStatus'] ?? 'No status',
                        style: TextStyle(
                          color: (itemData['listingStatus'] ?? '') == 'active' ? Colors.green : Colors.red,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4),
                Text(
                  itemData['name'] ?? 'No name',  // Provide a fallback in case name is null
                  style: TextStyle(fontSize: 14),
                ),
                if (itemData['listingType'] == 'product' && itemData['quantity'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Quantity: ${itemData['quantity']}",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                SizedBox(height: 8),
                // Spacer pushes View more to the bottom
                Align(
                  alignment: Alignment.bottomCenter,
                  child: InkWell(
                    onTap: () {
                      // Navigate to ListingDetailsScreen when "View more" is clicked
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ListingDetailsScreen(listingId: itemData['id']), // Pass the listingId
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Listings'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Service'),
            Tab(text: 'Product'),
          ],
        ),
      ),
      body: TabBarView(
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
                  var item = serviceData[index].data() as Map<String, dynamic>;
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
                  var item = productData[index].data() as Map<String, dynamic>;
                  return _buildItemContainer(item);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
