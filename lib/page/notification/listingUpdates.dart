import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:redofyp/widgets/pageDesign.dart';
import 'package:redofyp/page/listing/viewListingDetails.dart';

class ListingUpdatesScreen extends StatefulWidget {
  @override
  _ListingUpdatesScreenState createState() => _ListingUpdatesScreenState();
}

class _ListingUpdatesScreenState extends State<ListingUpdatesScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late User _user;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
  }

  Future<void> _saveTileSelectionState(String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('notifications')
          .doc(notificationId)
          .update({'isSelected': true});
    } catch (e) {
      print('Error saving tile selection state: $e');
    }
  }

  Widget _buildNotificationList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(_user.uid)
          .collection('notifications')
          .where('type', isEqualTo: 'new_listing')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error loading notifications'));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No new notifications'));
        }

        final notifications = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            var notificationDoc = notifications[index];
            var notification = notificationDoc.data() as Map<String, dynamic>;
            var notificationId = notificationDoc.id;
            var message = notification['message'] ?? 'No message';
            var listingId = notification['listingId'] ?? '';
            var timestamp = notification['timestamp'];
            String formattedTime = timestamp != null
                ? DateFormat('dd/MM/yyyy HH:mm').format(timestamp.toDate())
                : '';
            bool isSelected = notification['isSelected'] ?? false;

            // Skip notifications without a valid listingId
            if (listingId == null || (listingId is String && listingId.trim().isEmpty)) {
              return SizedBox.shrink(); // don't render this notification at all
            }

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('listings')
                  .doc(listingId)
                  .get(),
              builder: (context, listingSnapshot) {
                if (listingSnapshot.connectionState == ConnectionState.waiting) {
                  return Card(
                    child: ListTile(
                      title: Text('Loading listing info...'),
                    ),
                  );
                }
                if (!listingSnapshot.hasData || !listingSnapshot.data!.exists) {
                  return Card(
                    child: ListTile(
                      title: Text('Listing not found'),
                    ),
                  );
                }

                var listingData = listingSnapshot.data!.data() as Map<String, dynamic>;
                String imageUrl = listingData['image'] ?? '';
                String listingName = listingData['name'] ?? 'Unnamed Listing';
                String listingType = listingData['listingType'] ?? 'product'; // fallback to product
                String typeLabel = listingType.toLowerCase() == 'service' ? 'New Service' : 'New Product';
                String sellerUserId = listingData['userId'] ?? '';

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(sellerUserId)
                      .get(),
                  builder: (context, userSnapshot) {
                    String sellerName = 'Unknown Seller';

                    if (userSnapshot.connectionState == ConnectionState.waiting) {
                      return Card(
                        color: isSelected ? Colors.white : Colors.yellow.shade100,
                        margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 12),
                          leading: imageUrl.isNotEmpty
                              ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 70,
                              height: 70,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Icon(Icons.broken_image, size: 70),
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: progress.expectedTotalBytes != null
                                          ? progress.cumulativeBytesLoaded /
                                          progress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          )
                              : Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: Colors.grey.shade300,
                            ),
                            child: Icon(Icons.image, size: 40, color: Colors.grey),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                typeLabel,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              IconButton(
                                icon: Icon(Icons.arrow_forward_ios),
                                onPressed: () {
                                  _saveTileSelectionState(notificationId);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          ViewListingDetailsScreen(listingId: listingId),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 4),
                              Text('Loading seller info...'),
                              SizedBox(height: 6),
                              Text(
                                formattedTime,
                                style: TextStyle(color: Colors.grey[600], fontSize: 12),
                              ),
                            ],
                          ),
                          onTap: () {
                            _saveTileSelectionState(notificationId);
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ViewListingDetailsScreen(listingId: listingId),
                              ),
                            );
                          },
                        ),
                      );
                    }
                    if (userSnapshot.hasError || !userSnapshot.hasData || !userSnapshot.data!.exists) {
                      sellerName = 'Unknown Seller';
                    } else {
                      final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                      sellerName = userData['fullname'] ?? 'Unknown Seller';
                    }

                    // Determine text for listing type
                    String listingTypeText = listingType.toLowerCase() == 'service'
                        ? 'A new service is created by '
                        : 'A new product is created by ';

                    return Card(
                      color: isSelected ? Colors.grey[200] : Colors.yellow.shade100,
                      margin: EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(10),
                        onTap: () {
                          _saveTileSelectionState(notificationId);
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViewListingDetailsScreen(listingId: listingId),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12), // reduced vertical padding
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Image
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  imageUrl.isNotEmpty ? imageUrl : 'https://via.placeholder.com/60',
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Icon(Icons.broken_image, size: 60),
                                ),
                              ),
                              SizedBox(width: 12),

                              // Text info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min, // shrink to fit content height
                                  children: [
                                    Text(
                                      listingName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2), // smaller spacing
                                    Text(
                                      listingTypeText + sellerName + '.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    SizedBox(height: 2), // smaller spacing
                                    Text(
                                      formattedTime,
                                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),

                              // Arrow icon button
                              IconButton(
                                icon: Icon(Icons.arrow_forward_ios, size: 18),
                                padding: EdgeInsets.zero, // remove extra padding for smaller icon button
                                constraints: BoxConstraints(), // remove minimum size constraints
                                onPressed: () {
                                  _saveTileSelectionState(notificationId);
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViewListingDetailsScreen(listingId: listingId),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: customAppBar('Listing Updates'),
      body: _buildNotificationList(),
    );
  }
}