import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/ai_chatbot_state.dart';
import '../widgets/floatingButton.dart';
import 'cart/cart.dart';
import 'chatBot.dart';
import 'listing/viewListingDetails.dart'; // Import the ViewListingDetails screen

class ViewAllScreen extends StatefulWidget {
  @override
  _ViewAllScreenState createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  String? _searchQuery = '';
  String? _selectedCategory;
  String? _selectedCondition;
  List<String> _selectedProductCategories = [];
  String? _selectedServiceCategory;
  bool _isProductCategorySelected = false;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Fetch all listings from Firestore and sort by timestamp (latest to oldest)
  Future<List<Map<String, dynamic>>> _fetchAllListings() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('listings')
        .where('listingStatus', isEqualTo: 'active')
        .orderBy('timestamp', descending: true)
        .get();

    List<Map<String, dynamic>> allListings = snapshot.docs
        .map((doc) => {
      'id': doc.id,  // Use Firestore document ID here
      ...doc.data() as Map<String, dynamic>
    })
        .toList();

    if (_searchQuery != '' && _searchQuery != null) {
      String searchQueryLower = _searchQuery!.toLowerCase();
      allListings = allListings.where((listing) {
        String name = listing['name']?.toString().toLowerCase() ?? '';
        return name.contains(searchQueryLower);
      }).toList();
    }

    if (_isProductCategorySelected && _selectedProductCategories.isNotEmpty) {
      allListings = allListings.where((listing) {
        return _selectedProductCategories.contains(listing['category']);
      }).toList();
    }

    if (!_isProductCategorySelected && _selectedServiceCategory != null) {
      allListings = allListings.where((listing) {
        return listing['category'] == _selectedServiceCategory;
      }).toList();
    }

    if (_selectedCondition != null && _isProductCategorySelected) {
      allListings = allListings.where((listing) {
        return listing['condition'] == _selectedCondition;
      }).toList();
    }

    return allListings;
  }

  Widget _buildListingCard(Map<String, dynamic> listing) {
    return GestureDetector(
      onTap: () {
        // Ensure the 'id' field is not null before navigating
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
        margin: EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            listing['image'] != null && listing['image'].isNotEmpty
                ? Image.network(
              listing['image'],
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

          // Category Filter (Product or Service)
          DropdownButton<String>(
            value: _selectedCategory,
            onChanged: (value) {
              setState(() {
                _selectedCategory = value;
                if (value == 'Product') {
                  _isProductCategorySelected = true;
                  _selectedServiceCategory = null;  // Reset service category
                  _selectedProductCategories = []; // Reset product categories
                } else if (value == 'Service') {
                  _isProductCategorySelected = false;
                  _selectedProductCategories = [];  // Reset product categories
                  _selectedServiceCategory = null;  // Reset service category
                }
              });
            },
            items: ['Product', 'Service'].map((category) {
              return DropdownMenuItem<String>(
                value: category,
                child: Text(category),
              );
            }).toList(),
            hint: Text('Select Category'),
          ),
          SizedBox(height: 20),

          // Product Filter (only if Product category is selected)
          if (_isProductCategorySelected)
            Column(
              children: [
                Text("Product Categories", style: TextStyle(fontWeight: FontWeight.bold)),
                ...['electronics', 'books', 'food and beverages', 'clothes', 'home appliances'].map((category) {
                  return CheckboxListTile(
                    title: Text(category),
                    value: _selectedProductCategories.contains(category),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedProductCategories.add(category);
                        } else {
                          _selectedProductCategories.remove(category);
                        }
                      });
                    },
                  );
                }),
                CheckboxListTile(
                  title: Text('Other'),
                  value: _selectedProductCategories.contains('other product'),
                  onChanged: (value) {
                    setState(() {
                      if (value == true) {
                        _selectedProductCategories.add('other product');
                      } else {
                        _selectedProductCategories.remove('other product');
                      }
                    });
                  },
                ),
                SizedBox(height: 10),
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
              ],
            ),
          SizedBox(height: 20),

          // Service Filter (only if Service category is selected)
          if (_selectedCategory == 'Service')
            Column(
              children: [
                Text("Service Categories", style: TextStyle(fontWeight: FontWeight.bold)),
                ...['printing', 'fetching'].map((category) {
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
                CheckboxListTile(
                  value: _selectedServiceCategory == 'other service',
                  title: Text('Other'),
                  onChanged: (value) {
                    setState(() {
                      _selectedServiceCategory = value! ? 'other service' : null;
                    });
                  },
                ),
              ],
            ),
          SizedBox(height: 20),

          // Apply Filter Button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close drawer
              setState(() {}); // Rebuild with new filters and trigger data fetch
            },
            child: Text('Apply Filter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.yellow.shade50,
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
            title: Text('Notifications', style: TextStyle(color: Colors.white)),
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
                  builder: (context) => CartScreen(userId: FirebaseAuth.instance.currentUser!.uid),
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
          padding: const EdgeInsets.all(2.0),
          child: Column(
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(
                future: _fetchAllListings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No listings available.'));
                  } else {
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 2.0,
                        mainAxisSpacing: 2.0,
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
