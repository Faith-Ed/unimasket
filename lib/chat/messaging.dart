import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../widgets/bottomNavigationBar.dart';
import 'messageDetail.dart'; // Import the message detail page

class MessagingScreen extends StatefulWidget {
  @override
  _MessagingScreenState createState() => _MessagingScreenState();
}

class _MessagingScreenState extends State<MessagingScreen> {
  late String _userId;
  int _currentIndex = 1;
  int _totalUnreadChats = 0;

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
  }

  Future<String> _getOtherUserProfilePhoto(List<dynamic> participants) async {
    try {
      String otherUserId = participants.firstWhere((id) => id != _userId);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .collection('photo_profile')
          .doc('profile')
          .get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        return data['url'] ?? 'https://via.placeholder.com/150';
      }
      return 'https://via.placeholder.com/150';
    } catch (e) {
      return 'https://via.placeholder.com/150';
    }
  }

  Future<String> _getOtherUserFullName(List<dynamic> participants) async {
    try {
      String otherUserId = participants.firstWhere((id) => id != _userId);

      DocumentSnapshot userDoc =
      await FirebaseFirestore.instance.collection('users').doc(otherUserId).get();

      if (userDoc.exists) {
        Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
        return data['fullname'] ?? 'No name';
      }
      return 'No name';
    } catch (e) {
      return 'No name';
    }
  }

  // This helper counts if a chat has unread messages for current user
  Future<bool> _chatHasUnreadMessages(String chatId) async {
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .get();

    return messagesSnapshot.docs.any((doc) {
      final messageData = doc.data() as Map<String, dynamic>;
      List<dynamic> seenBy = messageData['seenBy'] ?? [];
      String senderId = messageData['senderId'] ?? '';
      return !seenBy.contains(_userId) && senderId != _userId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(10),
            bottomRight: Radius.circular(10),
          ),
          child: AppBar(
            toolbarHeight: 80,
            title: Text('Chats', style: TextStyle(color: Colors.white)),
            backgroundColor: CupertinoColors.systemYellow,
            automaticallyImplyLeading: false,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('messages')
              .where('participants', arrayContains: _userId)
              .orderBy('lastUpdated', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting)
              return const Center(child: CircularProgressIndicator());

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
              return const Center(child: Text("No messages found"));

            List<QueryDocumentSnapshot> chatDocs = snapshot.data!.docs;

            return FutureBuilder<List<bool>>(
              future: Future.wait(chatDocs.map((chatDoc) => _chatHasUnreadMessages(chatDoc.id))),
              builder: (context, unreadChatsSnapshot) {
                if (!unreadChatsSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final unreadFlags = unreadChatsSnapshot.data!;
                final totalUnreadChats = unreadFlags.where((hasUnread) => hasUnread).length;

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: chatDocs.length,
                        itemBuilder: (context, index) {
                          var chatDoc = chatDocs[index];
                          var data = chatDoc.data() as Map<String, dynamic>;

                          List<dynamic> participants = data['participants'];
                          String chatId = chatDoc.id;
                          String lastMessage = data['lastMessage'] ?? 'No content';
                          Timestamp lastUpdatedTimestamp = data['lastUpdated'] as Timestamp;
                          DateTime lastUpdated = lastUpdatedTimestamp.toDate();

                          final unreadCountForThisChat = unreadFlags[index] ? 1 : 0;

                          return FutureBuilder<String>(
                            future: _getOtherUserProfilePhoto(participants),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return ListTile(title: const Text('Loading...'));
                              }
                              String profileImage = snapshot.data ?? 'https://via.placeholder.com/150';

                              return FutureBuilder<String>(
                                future: _getOtherUserFullName(participants),
                                builder: (context, nameSnapshot) {
                                  if (nameSnapshot.connectionState == ConnectionState.waiting) {
                                    return ListTile(title: const Text('Loading full name...'));
                                  }
                                  String fullName = nameSnapshot.data ?? 'No Name';

                                  return StreamBuilder<QuerySnapshot>(
                                    stream: FirebaseFirestore.instance
                                        .collection('messages')
                                        .doc(chatId)
                                        .collection('messages')
                                        .snapshots(),
                                    builder: (context, messagesSnapshot) {
                                      if (!messagesSnapshot.hasData) {
                                        return ListTile(title: Text(fullName));
                                      }

                                      int unreadCount = messagesSnapshot.data!.docs.where((doc) {
                                        final messageData = doc.data() as Map<String, dynamic>;
                                        List<dynamic> seenBy = messageData['seenBy'] ?? [];
                                        String senderId = messageData['senderId'] ?? '';
                                        return !seenBy.contains(_userId) && senderId != _userId;
                                      }).length;

                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 6),
                                        elevation: 2,
                                        child: ListTile(
                                          contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          leading: CircleAvatar(
                                            backgroundImage: NetworkImage(profileImage),
                                          ),
                                          title: Text(fullName, style: TextStyle(fontWeight: FontWeight.bold)),
                                          subtitle: Text(
                                            lastMessage == "[photo]" ? '[Photo]' : lastMessage,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(color: Colors.grey[700]),
                                          ),
                                          trailing: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                DateFormat('HH:mm').format(lastUpdated),
                                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                              ),
                                              SizedBox(height: 4),
                                              if (unreadCount > 0)
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: Colors.red,
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Text(
                                                    '$unreadCount',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 12,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          onTap: () {
                                            String otherUserId = participants.firstWhere((id) => id != _userId);

                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => MessageDetailsPage(
                                                  conversationId: chatId,
                                                  senderId: _userId,
                                                  receiverId: otherUserId,
                                                  messageContent: lastMessage,
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
                          );
                        },
                      ),
                    ),

                    // Bottom Navigation Bar with unread badge count
                    BottomNavigationBarWidget(
                      currentIndex: _currentIndex,
                      unreadCount: totalUnreadChats,
                      onTap: (index) {
                        setState(() {
                          _currentIndex = index;
                        });
                      },
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}