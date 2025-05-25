import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_chatbot_state.dart';
import '../widgets/floatingButton.dart';
import 'listing/viewListingDetails.dart'; // Import the ViewListingDetails screen
import 'cart/cart.dart';
import 'chatBot.dart';

class ViewServiceScreen extends StatefulWidget {
  @override
  _ViewServiceScreenState createState() => _ViewServiceScreenState();
}

class _ViewServiceScreenState extends State<ViewServiceScreen> {
  String? _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCondition;
  String? _selectedServiceCategory;
  bool _isLoading = false;
  List<Map<String, dynamic>> _serviceListings = []; // Local data to hold the listings

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Fetch only service listings with 'listingStatus' as 'active'
  Future<void> _fetchServiceListings() async {
    setState(() {
      _isLoading = true;
    });

    // Start with the base query to fetch service listings with 'active' status
    Query query = FirebaseFirestore.instance
        .collection('listings')
        .where('listingStatus', isEqualTo: 'active') // Only active listings
        .where('listingType', isEqualTo: 'service') // Only service listings
        .orderBy('timestamp', descending: true); // Sort by timestamp

    // Apply search query filter only if there is a search query
    if (_searchQuery != '' && _searchQuery != null) {
      String searchQueryLower = _searchQuery!.toLowerCase();
      query = query
          .where('name', isGreaterThanOrEqualTo: searchQueryLower)
          .where('name', isLessThanOrEqualTo: searchQueryLower + '\uf8ff');
    }

    // Apply service category filter only if a category is selected
    if (_selectedServiceCategory != null && _selectedServiceCategory!.isNotEmpty) {
      query = query.where('category', isEqualTo: _selectedServiceCategory);
    }

    // Apply condition filter only if a condition is selected
    if (_selectedCondition != null && _selectedCondition!.isNotEmpty) {
      query = query.where('condition', isEqualTo: _selectedCondition);
    }

    try {
      QuerySnapshot snapshot = await query.get();
      List<Map<String, dynamic>> fetchedListings = snapshot.docs.map((doc) {
        return {
          'id': doc.id,  // Firestore document ID
          ...doc.data() as Map<String, dynamic>
        };
      }).toList();

      setState(() {
        _serviceListings = fetchedListings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print("Error fetching listings: $e");
    }
  }

  // Build the listing card widget
  Widget _buildListingCard(Map<String, dynamic> listing) {
    return GestureDetector(
      onTap: () {
        // Get the listingId (document ID of the listing)
        String listingId = listing['id'] ?? 'default_id';  // Ensure 'id' exists
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
        margin: EdgeInsets.all(8.0),
        child: Column(
          children: [
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
                overflow: TextOverflow.ellipsis,  // Prevent overflow of long text
                maxLines: 1,  // Ensure the text stays on one line
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                '\RM ${listing['price'] ?? 'No Price'}',
                style: TextStyle(color: Colors.green),
                overflow: TextOverflow.ellipsis,  // Prevent overflow of long text
                maxLines: 1,  // Ensure the text stays on one line
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Drawer widget for filter options
  Widget _buildFilterDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.all(16.0),
        children: [
          Text(
            'Filter Options',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),

          // Service Filter (Service category)
          Text("Service Categories", style: TextStyle(fontWeight: FontWeight.bold)),
          ...['printing', 'fetching', 'others'].map((category) {
            return CheckboxListTile(
              value: _selectedServiceCategory == category,
              title: Text(category),
              onChanged: (value) {
                setState(() {
                  _selectedServiceCategory = value! ? category : null;
                });
              },
            );
          }),
          SizedBox(height: 20),

          // Condition Filter (New or Used)
          Text("Condition", style: TextStyle(fontWeight: FontWeight.bold)),
          ...['new', 'used'].map((condition) {
            return CheckboxListTile(
              value: _selectedCondition == condition,
              title: Text(condition),
              onChanged: (value) {
                setState(() {
                  _selectedCondition = value! ? condition : null;
                });
              },
            );
          }),
          SizedBox(height: 20),

          // Apply Filter Button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close drawer
              _fetchServiceListings(); // Trigger data fetch with updated filters
            },
            child: Text('Apply Filter'),
          ),
        ],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchServiceListings(); // Fetch the listings on init
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: _buildFilterDrawer(),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // Set the height of the AppBar
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),  // Set left bottom corner radius
            bottomRight: Radius.circular(10),  // Set right bottom corner radius
          ),
          child: AppBar(
            toolbarHeight: 80, // Toolbar height remains as per your request
            title: Text('Services', style: TextStyle(color: Colors.white)),
            backgroundColor: CupertinoColors.systemYellow,  // AppBar background color
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.60,
              child: TextField(
                onChanged: (query) {
                  setState(() {
                    _searchQuery = query;
                  });
                  _fetchServiceListings(); // Re-fetch the listings on search query change
                },
                decoration: InputDecoration(
                  hintText: 'Search...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: Icon(Icons.search),
                ),
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Navigate to the CartScreen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => CartScreen(userId: 'userId'), // Replace with current user ID
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: () {
              _scaffoldKey.currentState!.openEndDrawer(); // Open filter drawer
            },
          ),
        ],
      ),),),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              _isLoading
                  ? Center(child: CircularProgressIndicator()) // Show loading if fetching
                  : _serviceListings.isEmpty
                  ? Center(child: Text('No services available.'))
                  : GridView.builder(
                shrinkWrap: true, // Limit the size of the GridView
                physics: NeverScrollableScrollPhysics(), // Disable scrolling for GridView inside SingleChildScrollView
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // 2 cards per row
                  crossAxisSpacing: 8.0, // Spacing between cards
                  mainAxisSpacing: 8.0, // Spacing between rows
                  childAspectRatio: 0.75, // Adjust height/width ratio to avoid overflow
                ),
                itemCount: _serviceListings.length,
                itemBuilder: (context, index) {
                  return _buildListingCard(_serviceListings[index]);
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: AiChatbotState().isEnabled,
        builder: (context, isEnabled, _) {
          return isEnabled ? CustomFloatingActionButton() : SizedBox.shrink();
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
