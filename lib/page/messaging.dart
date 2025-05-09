import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'bottomNavigationBar.dart';
import 'messageDetail.dart'; // Import the message detail page

class MessagingScreen extends StatefulWidget {
  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  late String _userId;
  Map<String, List<DocumentSnapshot>> _groupedMessages = {}; // Grouped messages by senderId
  int _currentIndex = 1;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _getMessages();
  }

  // Fetch latest message from each sender and group messages by senderId
  Future<void> _getMessages() async {
    try {
      // Fetch messages where either the senderId or receiverId matches the current user
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .where('senderId', isEqualTo: _userId)
          .orderBy('lastUpdated', descending: true)
          .get();

      QuerySnapshot querySnapshotReceiver = await FirebaseFirestore.instance
          .collection('messages')
          .where('receiverId', isEqualTo: _userId)
          .orderBy('lastUpdated', descending: true)
          .get();

      // Combine the two queries
      final allDocs = [...querySnapshot.docs, ...querySnapshotReceiver.docs];

      Map<String, List<DocumentSnapshot>> groupedMessages = {};

      for (var doc in allDocs) {
        final messageData = doc.data() as Map<String, dynamic>;
        final senderId = messageData['senderId'];
        final receiverId = messageData['receiverId'];

        // Create conversationId from senderId and receiverId
        String conversationId = _createConversationId(senderId, receiverId);

        // If the conversationId is not in the map, add it
        if (!groupedMessages.containsKey(conversationId)) {
          groupedMessages[conversationId] = [];
        }
        groupedMessages[conversationId]!.add(doc);  // Add the message to the group of the conversationId
      }

      setState(() {
        _groupedMessages = groupedMessages;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }

  // Create a unique conversation ID by sorting senderId and receiverId
  String _createConversationId(String senderId, String receiverId) {
    List<String> ids = [senderId, receiverId];
    ids.sort();
    return ids.join('-');
  }

  // Fetch sender's profile photo from the 'photo_profile' subcollection
  Future<String> _getSenderProfilePhoto(String senderId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('photo_profile')
          .doc('profile')
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        return data['url'] ?? 'https://via.placeholder.com/150';
      } else {
        return 'https://via.placeholder.com/150';
      }
    } catch (e) {
      return 'https://via.placeholder.com/150';
    }
  }

  // Fetch sender's full name
  Future<String> _getSenderFullName(String senderId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        return data['fullname'] ?? 'No name';
      } else {
        return 'No name';
      }
    } catch (e) {
      return 'No name';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // Set the height of the AppBar
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),  // Set left bottom corner radius
            bottomRight: Radius.circular(10),  // Set right bottom corner radius
          ),
          child: AppBar(
            toolbarHeight: 80, // Toolbar height remains as per your request
            title: Text('Chats', style: TextStyle(color: Colors.white)),
            backgroundColor: CupertinoColors.systemYellow,  // AppBar background color
        automaticallyImplyLeading: false,
      ),),),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _groupedMessages.isEmpty
            ? const Center(child: Text("No messages found"))
            : ListView.builder(
          itemCount: _groupedMessages.length,
          itemBuilder: (context, index) {
            String conversationId = _groupedMessages.keys.elementAt(index);
            List<DocumentSnapshot> messageDocs = _groupedMessages[conversationId]!;

            final messageData = messageDocs.last.data() as Map<String, dynamic>;
            final messageContent = messageData['lastMessage'] ?? 'No content';
            final timestamp = messageData['lastUpdated'].toDate();

            String senderId = messageData['senderId'];
            String receiverId = messageData['receiverId'];

            // Determine the other user in the conversation
            String otherUserId = senderId == _userId ? receiverId : senderId;

            return FutureBuilder<String>(
              future: _getSenderProfilePhoto(otherUserId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListTile(
                    title: const Text('Loading...'),
                  );
                }

                String senderProfileImage = snapshot.data ?? 'https://via.placeholder.com/150';

                return FutureBuilder<String>(
                  future: _getSenderFullName(otherUserId),
                  builder: (context, nameSnapshot) {
                    if (nameSnapshot.connectionState == ConnectionState.waiting) {
                      return ListTile(
                        title: const Text('Loading full name...'),
                      );
                    }

                    String senderFullName = nameSnapshot.data ?? 'No Name';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(senderProfileImage),
                        ),
                        title: Text(
                          senderFullName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          messageContent == "[photo]"
                              ? '[Photo]'
                              : messageContent, // Display '[Photo]' for image-only messages
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: Text(
                          DateFormat('HH:mm').format(timestamp),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        onTap: () {
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
                      ),
                    );
                  },
                );
              },
            );
          },
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
    );
  }
}
