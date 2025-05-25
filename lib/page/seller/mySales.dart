import 'package:flutter/material.dart';
import '../../widgets/pageDesign.dart';
import 'listing.dart';
import 'salesDetails.dart'; // Import SalesDetailsScreen

class MySalesScreen extends StatelessWidget {
  const MySalesScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: customAppBar('My Sales'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Sales Container - Entire container clickable
            GestureDetector(
              onTap: () {
                // Navigate to SalesDetailsScreen when container is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SalesDetailsScreen(), // Navigate to SalesDetailsScreen
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Sales',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ), // Icon is still there, but no longer clickable
                  ],
                ),
              ),
            ),

            // Listings Container - Entire container clickable
            GestureDetector(
              onTap: () {
                // Navigate to SalesDetailsScreen when container is clicked
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListingScreen(), // Navigate to SalesDetailsScreen
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Listings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey,
                    ), // Icon is still there, but no longer clickable
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
