import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:redofyp/page/viewAll.dart';
import '../auth/login_user.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_listing.dart'; // Import CreateListingScreen
import 'me_menu.dart'; // Import me_menu.dart

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _auth = FirebaseAuth.instance;

  int _currentIndex = 0; // Keep track of the selected tab

  // Logout functionality
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
    );
  }

  // Fetch listings based on category
  Future<List<Map<String, dynamic>>> _fetchListings(String category, {bool isNew = false}) async {
    Query query;

    if (isNew) {
      // Fetch the top 3 recent listings (both product and service)
      query = FirebaseFirestore.instance
          .collection('listings')
          .orderBy('timestamp', descending: true)
          .limit(2);
    } else if (category == 'product') {
      // Fetch the latest 3 products
      query = FirebaseFirestore.instance
          .collection('listings')
          .where('listingType', isEqualTo: 'product')
          .orderBy('timestamp', descending: true)
          .limit(2);
    } else {
      // Fetch the latest 3 services
      query = FirebaseFirestore.instance
          .collection('listings')
          .where('listingType', isEqualTo: 'service')
          .orderBy('timestamp', descending: true)
          .limit(2);
    }

    var snapshot = await query.get();
    return snapshot.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();
  }

  // Format product price to RM with 2 decimal places
  String formatPrice(double price) {
    final formatter = NumberFormat('#,##0.00', 'en_US');  // Format with 2 decimal places
    return 'RM ${formatter.format(price)}';  // Prefix with RM and return formatted value
  }

// Build the listing card widget
  Widget _buildListingCard(Map<String, dynamic> listing) {
    return Card(
      margin: EdgeInsets.all(8.0),
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
            '\$${listing['price'] ?? 'No Price'}',
            style: TextStyle(color: Colors.green),
          ),
        ],
      ),
    );
  }


  // Handle Tab Selection
  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 0) {
        // Navigate to HomeScreen if not already on it
        if (_currentIndex != 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => HomeScreen()),
                (Route<dynamic> route) => false, // Remove previous screens from the stack
          );
        }
      } else if (index == 1) {
        // Navigate to Chats screen
      } else if (index == 2) {
        // Navigate to Notifications screen
      } else if (index == 3) {
        // Navigate to MeMenuScreen
        if (_currentIndex != 3) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MeMenuScreen()),
                (Route<dynamic> route) => false, // Remove previous screens from the stack
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logo'),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              // Navigate to profile or login page
            },
          ),
        ],
      ),
      body: SingleChildScrollView(  // Wrap the entire body in SingleChildScrollView for vertical scrolling
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              // New Listings Section
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('New', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    TextButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context)=> ViewAllScreen()),
                        );
                      },
                      child: Text('See All'),
                    ),
                  ],
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Products', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    TextButton(
                      onPressed: () {},
                      child: Text('See All'),
                    ),
                  ],
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Services', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                    TextButton(
                      onPressed: () {},
                      child: Text('See All'),
                    ),
                  ],
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            if (index == 3) { // When the "Me" icon is tapped, navigate to MeMenuScreen
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => MeMenuScreen()),
              );
            }
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
            backgroundColor: Colors.blue, // Set background color to blue
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chats',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications),
            label: 'Notifications',
            backgroundColor: Colors.blue,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Me',
            backgroundColor: Colors.blue, // Set background color to blue
          ),
        ],
        selectedItemColor: Colors.yellow, // Set selected item text and icon color to white
        unselectedItemColor: Colors.white, // Set unselected item text and icon color to white
        showUnselectedLabels: true, // Ensure unselected labels are visible
        type: BottomNavigationBarType.fixed, // Prevent icon shifting by keeping them fixed
        backgroundColor: Colors.blue,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateListingScreen()), // Navigate to CreateListingScreen
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Sell',
      ),
    );
  }
}
