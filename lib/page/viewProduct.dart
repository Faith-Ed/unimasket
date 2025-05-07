import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'viewListingDetails.dart'; // Import the ViewListingDetails screen
import 'cart.dart';
import 'chatBot.dart';

class ViewProductScreen extends StatefulWidget {
  @override
  _ViewProductScreenState createState() => _ViewProductScreenState();
}

class _ViewProductScreenState extends State<ViewProductScreen> {
  String? _searchQuery = '';

  // Fetch only product listings with 'listingStatus' as 'active'
  Future<List<Map<String, dynamic>>> _fetchProductListings() async {
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection('listings')
        .where('listingStatus', isEqualTo: 'active') // Only active listings
        .where('listingType', isEqualTo: 'product') // Only product listings
        .orderBy('timestamp', descending: true) // Sort by timestamp
        .get();

    return snapshot.docs.map((doc) {
      return {
        'id': doc.id,  // Firestore document ID
        ...doc.data() as Map<String, dynamic>
      };
    }).toList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Products'),
        actions: [
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
        ],
      ),
      body: SingleChildScrollView(  // Wrap the entire body in SingleChildScrollView for vertical scrolling
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              FutureBuilder<List<Map<String, dynamic>>>(  // Fetch only active product listings
                future: _fetchProductListings(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(child: Text('No products available.'));
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
            ],
          ),
        ),
      ),
      floatingActionButton: Tooltip(
        message: 'Chat with Bot',  // The tooltip message for the floating button
        child: FloatingActionButton(
          onPressed: () {
            // Open Chatbot
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ChatBot()),
            );
          },
          child: Icon(Icons.flutter_dash),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }
}
