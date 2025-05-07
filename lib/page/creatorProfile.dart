import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'messageDetail.dart';

class CreatorProfileScreen extends StatefulWidget {
  final String creatorId;  // Pass the creator's userId

  CreatorProfileScreen({required this.creatorId});

  @override
  _CreatorProfileScreenState createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> with SingleTickerProviderStateMixin {
  String? _creatorName;
  String? _profileImageUrl;
  late TabController _tabController;

  List<QueryDocumentSnapshot> _productListings = [];
  List<QueryDocumentSnapshot> _serviceListings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);  // Provide 'vsync'
    _fetchCreatorDetails();
    _fetchListings();
  }

  // Fetch creator details (profile image and name)
  Future<void> _fetchCreatorDetails() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.creatorId)  // Use the passed creatorId
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _creatorName = userData['fullname'] ?? 'No Name'; // Assign default value if null
        });
      }
    } catch (e) {
      print("Error fetching creator details: $e");
    }

    final photoDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.creatorId)
        .collection('photo_profile')
        .doc('profile')
        .get();

    if (photoDoc.exists) {
      setState(() {
        _profileImageUrl = photoDoc['url'];
      });
    }
  }

  // Fetch all listings created by the user (based on creatorId)
  Future<void> _fetchListings() async {
    try {
      QuerySnapshot listingsSnapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where('userId', isEqualTo: widget.creatorId)  // Filter listings by creatorId
          .get();

      List<QueryDocumentSnapshot> products = [];
      List<QueryDocumentSnapshot> services = [];

      listingsSnapshot.docs.forEach((doc) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['listingType'] == 'product') {
          products.add(doc);
        } else if (data['listingType'] == 'service') {
          services.add(doc);
        }
      });

      setState(() {
        _productListings = products;
        _serviceListings = services;
      });
    } catch (e) {
      print("Error fetching listings: $e");
    }
  }

  String _createConversationId(String senderId, String receiverId) {
    List<String> ids = [senderId, receiverId];
    ids.sort();
    return ids.join('-');
  }

  // Build the UI for the creator profile
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black26,
        automaticallyImplyLeading: true,  // Ensure the back button is displayed
      ),
      body: Column(
        children: [
          // Creator's profile image and name below the back arrow
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundImage: _profileImageUrl != null
                      ? NetworkImage(_profileImageUrl!)
                      : null,
                  radius: 25,
                ),
                SizedBox(width: 8),
                Text(
                  _creatorName ?? 'No Name',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Spacer(),  // Pushes the chat button to the far right
                ElevatedButton.icon(
                  onPressed: () {
                    String senderId = FirebaseAuth.instance.currentUser!.uid;
                    String receiverId = widget.creatorId;
                    String conversationId = _createConversationId(senderId, receiverId);
                    String messageContent = "Hi, I'd like to chat with you about your listing.";

                    // Debugging prints
                    print("Sender ID: $senderId");
                    print("Receiver ID: $receiverId");
                    print("Conversation ID: $conversationId");

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageDetailsPage(
                          conversationId: conversationId,
                          senderId: senderId,
                          receiverId: receiverId,
                          messageContent: messageContent,
                        ),
                      ),
                    );
                  },
                  icon: Icon(Icons.chat),
                  label: Text('Chat'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.blue.shade200,  // Set the text color
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: EdgeInsets.symmetric(horizontal: 14.0),
                  ),
                ),
              ],
            ),
          ),
          // Divider to visually separate the profile from the tab bar
          Divider(
            thickness: 1.0,
            color: Colors.grey[300],
            indent: 1.0,
            endIndent: 1.0,
          ),
          // TabBar below the profile and chat button
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Products'),
              Tab(text: 'Services'),
            ],
          ),
          // Display listings based on the selected tab
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Product listings
                _buildListingContainer(_productListings),
                // Service listings
                _buildListingContainer(_serviceListings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the container that holds the listing items (both products and services)
  Widget _buildListingContainer(List<QueryDocumentSnapshot> listings) {
    if (listings.isEmpty) {
      return Center(child: Text('No listings available.'));
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,  // Two cards in each row
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.75, // Adjust the aspect ratio of the cards
      ),
      itemCount: listings.length,
      itemBuilder: (context, index) {
        var listingData = listings[index].data() as Map<String, dynamic>;
        var name = listingData['name'];
        var price = listingData['price'].toString();
        var imageUrl = listingData['image'] ?? '';

        return Card(
          margin: EdgeInsets.all(8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              children: [
                // Listing image
                Image.network(imageUrl, height: 120, fit: BoxFit.cover),
                SizedBox(height: 8),
                // Listing name and price
                Text(
                  name ?? 'Unnamed Listing',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\RM $price', // Assuming the price is stored as a number
                  style: TextStyle(fontSize: 14, color: Colors.green),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
