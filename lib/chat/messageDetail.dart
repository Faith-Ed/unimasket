import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:redofyp/chat/previewImage.dart';
import '../page/donno/order.dart';
import '../services/zoom_image.dart';
import 'deleteMessage.dart';

class MessageDetailsPage extends StatefulWidget {
  final String conversationId; // e.g. "userA_userB"
  final String senderId;
  final String receiverId;
  final String messageContent;

  const MessageDetailsPage({
    Key? key,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
    required this.messageContent,
  }) : super(key: key);

  @override
  _MessageDetailsPageState createState() => _MessageDetailsPageState();
}

class _MessageDetailsPageState extends State<MessageDetailsPage> {
  late String _userId;
  final TextEditingController _messageController = TextEditingController();
  File? _selectedImage;
  ScrollController _scrollController = ScrollController();
  String? _selectedMessageId;

  List<String> participants = [];

  @override
  void initState() {
    super.initState();
    _userId = FirebaseAuth.instance.currentUser!.uid;
    _loadParticipants();
  }

  void _loadParticipants() async {
    final chatDoc = await FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.conversationId)
        .get();

    if (chatDoc.exists) {
      final data = chatDoc.data()!;
      final List<dynamic> p = data['participants'] ?? [];
      setState(() {
        participants = p.map((e) => e.toString()).toList();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PreviewImageScreen(
            imageFile: _selectedImage!,
            conversationId: widget.conversationId,
            senderId: widget.senderId,
            receiverId: widget.receiverId,
          ),
        ),
      );
    }
  }

  Future<void> _sendTextMessage({String? imageUrl}) async {
    final text = _messageController.text.trim();

    if (text.isEmpty && (imageUrl == null || imageUrl.isEmpty)) return;

    final currentTime = FieldValue.serverTimestamp();
    final chatDocRef = FirebaseFirestore.instance.collection('messages').doc(widget.conversationId);
    final messagesCollection = chatDocRef.collection('messages');

    final senderId = _userId;

    await messagesCollection.add({
      'senderId': senderId,
      'message': text,
      'timestamp': currentTime,
      'imageUrl': imageUrl ?? '',
      'isDeleted': false,
      'orderId': null,
      'qrCodeImageUrl': '',
      'seenBy': [senderId],
    });

    await chatDocRef.set({
      'participants': participants.isNotEmpty ? participants : [widget.senderId, widget.receiverId],
      'lastMessage': text.isNotEmpty ? text : '[photo]',
      'lastUpdated': currentTime,
    }, SetOptions(merge: true));

    _messageController.clear();

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 100,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<String> _getOtherUserProfilePhoto() async {
    try {
      String otherUserId = participants.firstWhere((id) => id != _userId);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .collection('photo_profile')
          .doc('profile')
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['url'] ?? 'https://via.placeholder.com/150';
      }
      return 'https://via.placeholder.com/150';
    } catch (e) {
      return 'https://via.placeholder.com/150';
    }
  }

  Future<String> _getOtherUserFullName() async {
    try {
      String otherUserId = participants.firstWhere((id) => id != _userId);

      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(otherUserId)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        return data['fullname'] ?? 'No name';
      }
      return 'No name';
    } catch (e) {
      return 'No name';
    }
  }

  Widget _buildMessageList(List<DocumentSnapshot> docs) {
    return ListView.builder(
      controller: _scrollController,
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final messageData = docs[index].data() as Map<String, dynamic>;
        final message = messageData['message'] ?? '';
        final timestamp = (messageData['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();
        final isSentByCurrentUser = messageData['senderId'] == _userId;
        final orderId = messageData['orderId'];
        final qrCodeImageUrl = messageData['qrCodeImageUrl'] ?? '';
        final imageUrl = messageData['imageUrl'] ?? '';
        final messageId = docs[index].id;

        return GestureDetector(
          onLongPress: () {
            setState(() {
              _selectedMessageId = messageId;
            });
            deleteMessage(context, widget.conversationId, messageId);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Align(
              alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  color: isSentByCurrentUser ? Colors.greenAccent[100] : Colors.blue[100],
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: isSentByCurrentUser ? Radius.circular(20) : Radius.zero,
                    bottomRight: isSentByCurrentUser ? Radius.zero : Radius.circular(20),
                  ),
                ),
                margin: isSentByCurrentUser
                    ? const EdgeInsets.only(left: 40.0, right: 8.0)
                    : const EdgeInsets.only(left: 8.0, right: 40.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (imageUrl.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ZoomImageScreen(imageUrl: imageUrl),
                            ),
                          );
                        },
                        child: Image.network(imageUrl, width: 150, height: 150),
                      ),
                    Text(message, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 5),
                    if (qrCodeImageUrl.isNotEmpty) ...[
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ZoomImageScreen(imageUrl: qrCodeImageUrl),
                            ),
                          );
                        },
                        child: Image.network(qrCodeImageUrl, width: 150, height: 150),
                      ),
                      Text("Proceed with payment and send the receipt once you have made the payment."),
                    ],
                    const SizedBox(height: 5),
                    if (orderId != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => OrderScreen(orderId: orderId),
                            ),
                          );
                        },
                        child: Text(
                          'Order ID: $orderId',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    Text(DateFormat('HH:mm').format(timestamp), style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: ClipRRect(
          borderRadius: BorderRadius.only(bottomLeft: Radius.circular(10), bottomRight: Radius.circular(10)),
          child: AppBar(
            toolbarHeight: 80,
            backgroundColor: CupertinoColors.systemYellow,
            title: FutureBuilder<String>(
              future: _getOtherUserFullName(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Text('Loading...');
                final senderName = snapshot.data ?? 'Unknown Sender';
                return Row(
                  children: [
                    FutureBuilder<String>(
                      future: _getOtherUserProfilePhoto(),
                      builder: (context, profileSnapshot) {
                        if (profileSnapshot.connectionState == ConnectionState.waiting) {
                          return const CircleAvatar(radius: 20);
                        }
                        final senderProfileImage = profileSnapshot.data ?? 'https://via.placeholder.com/150';
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ZoomImageScreen(imageUrl: senderProfileImage),
                              ),
                            );
                          },
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(senderProfileImage),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    Text(senderName),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('messages')
                    .doc(widget.conversationId)
                    .collection('messages')
                    .orderBy('timestamp')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting)
                    return const Center(child: CircularProgressIndicator());
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                    return const Center(child: Text('No messages yet'));

                  // Mark messages as seen whenever new data arrives
                  _markMessagesAsSeen(snapshot.data!.docs);

                  return _buildMessageList(snapshot.data!.docs);
                },
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "  Type a message...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.0)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.blue),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30.0),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      suffixIcon: IconButton(icon: Icon(Icons.attach_file), onPressed: _pickImage),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
                  child: IconButton(icon: const Icon(Icons.send), onPressed: () => _sendTextMessage()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // MARK: Mark unread messages as seen by the current user
  Future<void> _markMessagesAsSeen(List<DocumentSnapshot> messages) async {
    final batch = FirebaseFirestore.instance.batch();
    bool hasUpdates = false;

    for (var messageDoc in messages) {
      final data = messageDoc.data() as Map<String, dynamic>;
      final List<dynamic> seenBy = data['seenBy'] ?? [];
      final String senderId = data['senderId'] ?? '';

      // Only mark messages not sent by current user and not yet seen
      if (senderId != _userId && !seenBy.contains(_userId)) {
        final messageRef = messageDoc.reference;
        batch.update(messageRef, {
          'seenBy': FieldValue.arrayUnion([_userId])
        });
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      await batch.commit();
    }
  }
}
