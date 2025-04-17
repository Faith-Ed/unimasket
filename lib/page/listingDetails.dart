import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListingDetailsScreen extends StatelessWidget {
  final String listingId;

  ListingDetailsScreen({required this.listingId});

  // Fetch the listing details from Firestore
  Future<DocumentSnapshot> _fetchListingDetails() {
    return FirebaseFirestore.instance
        .collection('listings')
        .doc(listingId)  // Get listing based on passed listingId
        .get();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Listing Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: _fetchListingDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(child: Text('No listing found.'));
          }

          var listingData = snapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Display Image (with fallback for null)
                listingData['image'] != null
                    ? Image.network(listingData['image'], height: 200, fit: BoxFit.cover)
                    : Image.asset('assets/placeholder_image.png', height: 200, fit: BoxFit.cover),
                SizedBox(height: 16),

                // Name
                Text(
                  listingData['name'] ?? 'No name',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),

                // Category
                Text(
                  'Category: ${listingData['category'] ?? 'No category'}',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                SizedBox(height: 8),

                // Listing Status
                Text(
                  'Status: ${listingData['listingStatus'] ?? 'No status'}',
                  style: TextStyle(
                    fontSize: 16,
                    color: listingData['listingStatus'] == 'active' ? Colors.green : Colors.red,
                  ),
                ),
                SizedBox(height: 8),

                // Product or Service Details
                if (listingData['listingType'] == 'product') ...[
                  Text(
                    'Price: ${listingData['price'] ?? 'No price available'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Quantity: ${listingData['quantity'] ?? 'No quantity available'}',
                    style: TextStyle(fontSize: 16),
                  ),
                ] else ...[
                  Text(
                    'Price: ${listingData['price'] ?? 'No price available'}',
                    style: TextStyle(fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Service Description: ${listingData['serviceDescription'] ?? 'No description available'}',
                    style: TextStyle(fontSize: 16),
                  ),
                ],

                SizedBox(height: 16),

                // Description
                Text(
                  'Description: ${listingData['description'] ?? 'No description available'}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
