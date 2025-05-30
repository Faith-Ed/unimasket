import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../chat/messageDetail.dart';

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
    _tabController = TabController(length: 2, vsync: this);
    _fetchCreatorDetails();
    _fetchListings();
  }

  Future<void> _fetchCreatorDetails() async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.creatorId)
          .get();

      if (userDoc.exists) {
        var userData = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _creatorName = userData['fullname'] ?? 'No Name';
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

  Future<void> _fetchListings() async {
    try {
      QuerySnapshot listingsSnapshot = await FirebaseFirestore.instance
          .collection('listings')
          .where('userId', isEqualTo: widget.creatorId)
          .get();

      List<QueryDocumentSnapshot> products = [];
      List<QueryDocumentSnapshot> services = [];

      for (var doc in listingsSnapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['listingType'] == 'product') {
          products.add(doc);
        } else if (data['listingType'] == 'service') {
          services.add(doc);
        }
      }

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
    return ids.join('_');  // Use underscore for consistency
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: AppBar(
        backgroundColor: CupertinoColors.systemYellow,
        automaticallyImplyLeading: true,
      ),
      body: Column(
        children: [
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
                Spacer(),
                ElevatedButton.icon(
                  onPressed: () async {
                    final currentUserId = FirebaseAuth.instance.currentUser!.uid;
                    final receiverId = widget.creatorId;
                    final conversationId = _createConversationId(currentUserId, receiverId);
                    final chatDocRef = FirebaseFirestore.instance.collection('messages').doc(conversationId);
                    final chatDoc = await chatDocRef.get();

                    if (!chatDoc.exists) {
                      await chatDocRef.set({
                        'participants': [currentUserId, receiverId],
                        'lastMessage': '',
                        'lastUpdated': FieldValue.serverTimestamp(),
                      });
                    }

                    String messageContent = "Hi, I'd like to chat with you about your listing.";

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MessageDetailsPage(
                          conversationId: conversationId,
                          senderId: currentUserId,
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
                    backgroundColor: Colors.blue.shade200,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    padding: EdgeInsets.symmetric(horizontal: 14.0),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            thickness: 1.0,
            color: Colors.grey[300],
            indent: 1.0,
            endIndent: 1.0,
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: 'Products'),
              Tab(text: 'Services'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildListingContainer(_productListings),
                _buildListingContainer(_serviceListings),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListingContainer(List<QueryDocumentSnapshot> listings) {
    if (listings.isEmpty) {
      return Center(child: Text('No listings available.'));
    }
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8.0,
        mainAxisSpacing: 8.0,
        childAspectRatio: 0.75,
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
                Image.network(imageUrl, height: 120, fit: BoxFit.cover),
                SizedBox(height: 8),
                Text(
                  name ?? 'Unnamed Listing',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  '\RM $price',
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
