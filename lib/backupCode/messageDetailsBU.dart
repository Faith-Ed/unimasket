// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';
//
// class MessageDetailsPage extends StatefulWidget {
//   final String conversationId;
//   final String senderId;
//   final String receiverId;
//   final String messageContent;
//
//   const MessageDetailsPage({
//     Key? key,
//     required this.conversationId,
//     required this.senderId,
//     required this.receiverId,
//     required this.messageContent,
//   }) : super(key: key);
//
//   @override
//   _MessageDetailsPageState createState() => _MessageDetailsPageState();
// }
//
// class _MessageDetailsPageState extends State<MessageDetailsPage> {
//   late String _userId;
//   final TextEditingController _messageController = TextEditingController();
//
//   @override
//   void initState() {
//     super.initState();
//     _userId = FirebaseAuth.instance.currentUser!
//         .uid; // Get the current logged-in user ID
//   }
//
// // Send a text message
//   Future<void> _sendTextMessage() async {
//     if (_messageController.text.isEmpty) return;
//
//     String senderId = widget.senderId;
//     String receiverId = widget.receiverId;
//
//     // If the current user is replying, switch the senderId and receiverId
//     if (senderId == _userId) {
//       senderId = widget.receiverId;
//       receiverId = widget.senderId;
//     }
//
//     final currentTime = FieldValue.serverTimestamp();
//     String conversationId1 = '${senderId}-${receiverId}'; // id1-id2
//     String conversationId2 = '${receiverId}-${senderId}'; // id2-id1
//
//     // Check if the conversation already exists by checking both id1-id2 and id2-id1
//     var existingConversationSnapshot = await FirebaseFirestore.instance
//         .collection('messages')
//         .doc(conversationId1)
//         .get();
//
//     // If the conversation doesn't exist under id1-id2, check under id2-id1
//     if (!existingConversationSnapshot.exists) {
//       existingConversationSnapshot = await FirebaseFirestore.instance
//           .collection('messages')
//           .doc(conversationId2)
//           .get();
//     }
//
//     // If the conversation exists, add the message to the existing conversation's 'chats' subcollection
//     if (existingConversationSnapshot.exists) {
//       String conversationId = existingConversationSnapshot.id;
//
//       String qrCodeUrl = '';
//
//       // Save the message to the 'chats' subcollection
//       await FirebaseFirestore.instance.collection('messages').doc(
//           widget.conversationId).collection('chats').add({
//         'senderId': receiverId,
//         'receiverId': senderId,
//         'content': _messageController.text.trim(),
//         'timestamp': currentTime,
//         'isDeleted': false,
//         'orderId': null, // Add orderId only in the first message
//         'qrCodeImageUrl': qrCodeUrl,
//       });
//
//       // Update the last message in the parent 'messages' collection
//       await FirebaseFirestore.instance.collection('messages').doc(
//           widget.conversationId).set({
//         'senderId': receiverId, // Update senderId
//         'receiverId': senderId, // Update receiverId
//         'lastMessage': _messageController.text.trim(),
//         'lastUpdated': currentTime,
//       }, SetOptions(merge: true));
//
//       _messageController.clear();
//     }
//   }
//
// // Fetch the other user's profile photo from the conversation
//   Future<String> _getOtherUserProfilePhoto(String conversationId) async {
//     try {
//       // Split the conversationId to get both user IDs (id1-id2)
//       List<String> userIds = conversationId.split('-');
//
//       // Get the other user's ID (the one that is not the current user)
//       String otherUserId = (userIds[0] == _userId) ? userIds[1] : userIds[0];
//
//       // Fetch the other user's profile photo
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(otherUserId) // Fetch the profile of the other user
//           .collection('photo_profile')
//           .doc('profile')
//           .get();
//
//       if (userDoc.exists) {
//         Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
//         return data['url'] ??
//             'https://via.placeholder.com/150'; // Fallback image if no URL is found
//       } else {
//         return 'https://via.placeholder.com/150'; // Default fallback image if user data doesn't exist
//       }
//     } catch (e) {
//       return 'https://via.placeholder.com/150'; // Default fallback image on error
//     }
//   }
//
// // Fetch the other user's full name from the conversation
//   Future<String> _getOtherUserFullName(String conversationId) async {
//     try {
//       // Split the conversationId to get both user IDs (id1-id2)
//       List<String> userIds = conversationId.split('-');
//
//       // Get the other user's ID (the one that is not the current user)
//       String otherUserId = (userIds[0] == _userId) ? userIds[1] : userIds[0];
//
//       // Fetch the other user's full name
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(otherUserId) // Fetch the full name of the other user
//           .get();
//
//       if (userDoc.exists) {
//         Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
//         return data['fullname'] ?? 'No name'; // Default if no full name exists
//       } else {
//         return 'No name'; // Default name if user data doesn't exist
//       }
//     } catch (e) {
//       return 'No name'; // Default name on error
//     }
//   }
//
//   Future<List<DocumentSnapshot>> _fetchMessages() async {
//     // Define both possible conversation IDs
//     String conversationId1 = '${widget.senderId}-${widget.receiverId}'; // id1-id2
//     String conversationId2 = '${widget.receiverId}-${widget.senderId}'; // id2-id1
//
//     // Fetch messages from both collections
//     var chatSnapshot1 = await FirebaseFirestore.instance
//         .collection('messages')
//         .doc(conversationId1)
//         .collection('chats')
//         .orderBy('timestamp', descending: false)
//         .get();
//
//     var chatSnapshot2 = await FirebaseFirestore.instance
//         .collection('messages')
//         .doc(conversationId2)
//         .collection('chats')
//         .orderBy('timestamp', descending: false)
//         .get();
//
//     // Combine the results from both collections
//     List<DocumentSnapshot> allDocs = [
//       ...chatSnapshot1.docs,
//       ...chatSnapshot2.docs,
//     ];
//
//     // Sort the documents by timestamp in ascending order
//     allDocs.sort((a, b) {
//       var timestampA = a['timestamp'].toDate();
//       var timestampB = b['timestamp'].toDate();
//       return timestampA.compareTo(timestampB);
//     });
//
//     return allDocs;
//   }
//
//   Widget _buildMessageList(List<DocumentSnapshot> docs) {
//     return ListView.builder(
//       itemCount: docs.length,
//       itemBuilder: (context, index) {
//         final messageData = docs[index].data() as Map<String, dynamic>;
//         final message = messageData['content'] ?? '';
//         final timestamp = messageData['timestamp'].toDate();
//         final isSentByCurrentUser = messageData['senderId'] == _userId;
//         final orderId = messageData['orderId'];  // Fetch the orderId from the chat message
//         final qrCodeImageUrl = messageData['qrCodeImageUrl'] ?? ''; // Get the QR code image URL from the message data
//
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 6),
//           child: Align(
//             alignment: isSentByCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
//             child: Container(
//               padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
//               decoration: BoxDecoration(
//                 color: isSentByCurrentUser ? Colors.greenAccent[100] : Colors.blue[100], // Sent: green, Received: blue
//                 borderRadius: BorderRadius.only(
//                   topLeft: Radius.circular(20),
//                   topRight: Radius.circular(20),
//                   bottomLeft: isSentByCurrentUser ? Radius.circular(20) : Radius.zero,
//                   bottomRight: isSentByCurrentUser ? Radius.zero : Radius.circular(20),
//                 ), // Rounded corners with different bottom for sender and receiver
//               ),
//               // Add margin for sent and received messages
//               margin: isSentByCurrentUser
//                   ? const EdgeInsets.only(left: 40.0, right: 8.0)  // Sent messages with margin from left
//                   : const EdgeInsets.only(left: 8.0, right: 40.0), // Received messages with margin from right
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     isSentByCurrentUser ? 'You' : widget.senderId,
//                     style: const TextStyle(fontWeight: FontWeight.bold),
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     message,
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                   const SizedBox(height: 5),
//                   if (qrCodeImageUrl.isNotEmpty)  // If QR Code image URL exists, show it
//                     Column(
//                       children: [
//                         Image.network(qrCodeImageUrl, width: 150, height: 150),  // Show QR code image
//                         Text("Proceed with payment and send the receipt once you have made the payment.")
//                       ],
//                     ),
//                   const SizedBox(height: 5),
//                   if (orderId != null)  // Display orderId if it exists
//                     Text(
//                       'Order ID: $orderId',
//                       style: const TextStyle(fontSize: 12, color: Colors.grey),
//                     ),
//                   Text(
//                     DateFormat('HH:mm').format(timestamp),
//                     style: const TextStyle(fontSize: 12, color: Colors.grey),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: FutureBuilder<String>(
//           future: _getOtherUserFullName(widget.conversationId),
//           builder: (context, snapshot) {
//             if (snapshot.connectionState == ConnectionState.waiting) {
//               return const Text('Loading...');
//             }
//
//             String senderName = snapshot.data ?? 'Unknown Sender';
//
//             return Row(
//               children: [
//                 FutureBuilder<String>(
//                   future: _getOtherUserProfilePhoto(widget.conversationId),
//                   builder: (context, profileSnapshot) {
//                     if (profileSnapshot.connectionState == ConnectionState.waiting) {
//                       return const CircleAvatar(radius: 20);
//                     }
//
//                     String senderProfileImage = profileSnapshot.data ?? 'https://via.placeholder.com/150';
//
//                     return CircleAvatar(
//                       radius: 20,
//                       backgroundImage: NetworkImage(senderProfileImage),
//                     );
//                   },
//                 ),
//                 const SizedBox(width: 12),
//                 Text(senderName),
//               ],
//             );
//           },
//         ),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Display chat messages
//             Expanded(
//               child: FutureBuilder<List<DocumentSnapshot>>(
//                 future: _fetchMessages(),
//                 builder: (context, snapshot) {
//                   if (snapshot.connectionState == ConnectionState.waiting) {
//                     return const Center(child: CircularProgressIndicator());
//                   }
//                   if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                     return const Center(child: Text('No messages yet'));
//                   }
//                   return _buildMessageList(snapshot.data!);
//                 },
//               ),
//             ),
//
//             // Message input area
//             const SizedBox(height: 16),
//             Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _messageController,
//                     decoration: InputDecoration(
//                       hintText: "  Type a message...",
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30.0), // Makes the corners more rounded
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30.0), // Keep rounded corners when focused
//                         borderSide: BorderSide(color: Colors.blue),
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(30.0), // Keep rounded corners when not focused
//                         borderSide: BorderSide(color: Colors.grey),
//                       ),
//                       // Add the pin icon as a prefix
//                       suffixIcon: IconButton(
//                         icon: Icon(Icons.attach_file),
//                         onPressed: () {
//                           // Handle the pin icon click
//                           print("Pin icon clicked!");
//                           // Add your custom action here, like opening a new screen or showing a dialog
//                         },
//                       ),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendTextMessage,
//                 ),
//               ],
//             )
//           ],
//         ),
//       ),
//     );
//   }
// }
//
