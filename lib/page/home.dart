import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:redofyp/page/messaging.dart';
import 'package:redofyp/page/viewAll.dart';
import 'package:redofyp/page/viewListingDetails.dart';
import 'package:redofyp/page/viewProduct.dart';
import 'package:redofyp/page/viewService.dart';
import '../auth/login_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/floatingButton.dart';
import 'bottomNavigationBar.dart';
import 'cart.dart';
import 'chatBot.dart';
import 'create_listing.dart'; // Import CreateListingScreen

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;

  int _currentIndex = 0; // Keep track of the selected tab

  // Fetch listings based on category
  Future<List<Map<String, dynamic>>> _fetchListings(String category, {bool isNew = false}) async {
    Query query;

    if (isNew) {
      // Fetch the top 3 recent listings (both product and service)
      query = FirebaseFirestore.instance
          .collection('listings')
          .where('listingStatus', isEqualTo: 'active')
          .orderBy('timestamp', descending: true)
          .limit(2);
    } else if (category == 'product') {
      // Fetch the latest 3 products
      query = FirebaseFirestore.instance
          .collection('listings')
          .where('listingStatus', isEqualTo: 'active')
          .where('listingType', isEqualTo: 'product')
          .orderBy('timestamp', descending: true)
          .limit(2);
    } else {
      // Fetch the latest 3 services
      query = FirebaseFirestore.instance
          .collection('listings')
          .where('listingStatus', isEqualTo: 'active')
          .where('listingType', isEqualTo: 'service')
          .orderBy('timestamp', descending: true)
          .limit(2);
    }

    var snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,  // Correctly getting the Firestore document ID
        ...doc.data() as Map<String, dynamic>
      };
    }).toList();
  }

  // Format product price to RM with 2 decimal places
  String formatPrice(double price) {
    final formatter = NumberFormat('#,##0.00', 'en_US');  // Format with 2 decimal places
    return 'RM ${formatter.format(price)}';  // Prefix with RM and return formatted value
  }

  // Build the listing card widget and navigate to the ViewListingDetailsScreen
  Widget _buildListingCard(Map<String, dynamic> listing) {
    return GestureDetector(
      onTap: () {
        // Get the listingId (document ID of the listing)
        String listingId = listing['id'] ?? 'default_id';  // Fallback value if 'id' is null
        print('Listing ID: $listingId');  // Log the listingId

        // Navigate to ViewListingDetails screen when a card is tapped
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewListingDetailsScreen(listingId: listingId),
          ),
        );
      },
      child: Card(
        margin: EdgeInsets.all(5.0),
        child: Column(
          children: [
            // Use Image.network for displaying images from a URL
            listing['image'] != null && listing['image'].isNotEmpty
                ? Image.network(
              listing['image'], // Use the image URL here
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
            )
                : Container(
              height: 150,
              color: Colors.grey[200],
              child: Center(child: Text('No Image')),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                listing['name'] ?? 'No Name',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            Text(
              '\RM ${listing['price'] ?? 'No Price'}',
              style: TextStyle(color: Colors.green),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // Set the height of the AppBar
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),  // Set left bottom corner radius
            bottomRight: Radius.circular(10),  // Set right bottom corner radius
          ),
          child: AppBar(
            toolbarHeight: 80, // Toolbar height remains as per your request
            title: Text('UniMASKET', style: TextStyle(color: Colors.white)),
            backgroundColor: CupertinoColors.systemYellow,  // AppBar background color
            actions: [
              IconButton(
                icon: Icon(Icons.search, color: Colors.black),
                onPressed: () {},
              ),
              IconButton(
                icon: Icon(Icons.shopping_cart, color: Colors.black),
                onPressed: () {
                  // Navigate to the CartScreen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => CartScreen(userId: FirebaseAuth.instance.currentUser!.uid),
                    ),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 15),
                child: Tooltip(
                  message: 'Sell',  // The label to show when user taps/hover
                  child: IconButton(
                    icon: Icon(
                      Icons.sell, // Use sell icon for the button
                      size: 22,
                      color: Colors.black,  // Icon color
                    ),
                    onPressed: () {
                      // Navigate to CreateListingScreen
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => CreateListingScreen()),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // Image preview section
              Container(
                width: double.infinity,
                height: 200, // Set a fixed height for the image container
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/ecommerce.png'), // Image asset for preview
                    fit: BoxFit.cover,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              SizedBox(height: 10),
              // New Listings Section
              ColoredBox(
                color: Colors.pink.shade400,  // Set background color to black
                child: Padding(
                  padding: const EdgeInsets.all(1.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('   New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ViewAllScreen()),
                          );
                        },
                        child: Text('See All', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),

              // GridView for displaying new listings in 2-column grid
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchListings('new', isNew: true),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No new listings available.'));
                  } else {
                    return GridView.builder(
                      shrinkWrap: true,  // Limit the size of the GridView
                      physics: NeverScrollableScrollPhysics(),  // Disable scrolling for GridView inside SingleChildScrollView
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, // 2 cards per row
                        crossAxisSpacing: 8.0, // Spacing between cards
                        mainAxisSpacing: 8.0, // Spacing between rows
                        childAspectRatio: 0.75, // Adjust height/width ratio to avoid overflow
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return _buildListingCard(snapshot.data![index]);
                      },
                    );
                  }
                },
              ),

              // Products Section
              ColoredBox(
                color: Colors.pink.shade400,   // Set background color to black
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('   Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ViewProductScreen()),
                          );
                        },
                        child: Text('See All', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchListings('product'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No products available.'));
                  } else {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),  // Disable scrolling for GridView inside SingleChildScrollView
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return _buildListingCard(snapshot.data![index]);
                      },
                    );
                  }
                },
              ),

              // Services Section
              // Services Section with black background and white text
              ColoredBox(
                color: Colors.pink.shade400, // Set background color to black
                child: Padding(
                  padding: const EdgeInsets.all(3.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('   Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.white)),
                      TextButton(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ViewServiceScreen()),
                          );
                        },
                        child: Text('See All', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchListings('service'),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No services available.'));
                  } else {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),  // Disable scrolling for GridView inside SingleChildScrollView
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8.0,
                        mainAxisSpacing: 8.0,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: snapshot.data!.length,
                      itemBuilder: (context, index) {
                        return _buildListingCard(snapshot.data![index]);
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBarWidget(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
      floatingActionButton: CustomFloatingActionButton(), // Call the custom floating action button here
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
