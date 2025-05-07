// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:intl/intl.dart';
// import 'bottomNavigationBar.dart';
// import 'messageDetail.dart'; // Import the message detail page
//
// class MessagingScreen extends StatefulWidget {
//   @override
//   _MessagingScreenState createState() => _MessagingScreenState();
// }
//
// class _MessagingScreenState extends State<MessagingScreen> {
//   late String _userId;
//   Map<String, List<DocumentSnapshot>> _groupedMessages = {}; // Grouped messages by senderId
//   int _currentIndex = 1;
//
//   @override
//   void initState() {
//     super.initState();
//     _userId = FirebaseAuth.instance.currentUser!.uid;
//     _getMessages();
//   }
//
//   // Fetch latest message from each sender and group messages by senderId
//   Future<void> _getMessages() async {
//     try {
//       // Fetch messages where either the senderId or receiverId matches the current user
//       QuerySnapshot querySnapshot = await FirebaseFirestore.instance
//           .collection('messages')
//           .where('senderId', isEqualTo: _userId)
//           .orderBy('lastUpdated', descending: true)
//           .get();
//
//       QuerySnapshot querySnapshotReceiver = await FirebaseFirestore.instance
//           .collection('messages')
//           .where('receiverId', isEqualTo: _userId)
//           .orderBy('lastUpdated', descending: true)
//           .get();
//
//       // Combine the two queries
//       final allDocs = [...querySnapshot.docs, ...querySnapshotReceiver.docs];
//
//       Map<String, List<DocumentSnapshot>> groupedMessages = {};
//
//       for (var doc in allDocs) {
//         final messageData = doc.data() as Map<String, dynamic>;
//         final senderId = messageData['senderId'];
//
//         // If the senderId is not in the map, add it
//         if (!groupedMessages.containsKey(senderId)) {
//           groupedMessages[senderId] = [];
//         }
//         groupedMessages[senderId]!.add(doc);  // Add the message to the group of the senderId
//       }
//
//       // Fetch the latest message content from the chat subcollection
//       for (String senderId in groupedMessages.keys) {
//         final docs = groupedMessages[senderId]!;
//
//         for (var doc in docs) {
//           final lastMessageData = doc.data() as Map<String, dynamic>;
//
//           // Fetch the chat subcollection to get the last message
//           QuerySnapshot chatSnapshot = await FirebaseFirestore.instance
//               .collection('messages')
//               .doc(doc.id)
//               .collection('chats')
//               .orderBy('timestamp', descending: true) // Order chats by timestamp to get the last message
//               .limit(1) // Limit to just the latest message
//               .get();
//
//           if (chatSnapshot.docs.isNotEmpty) {
//             final lastMessageDoc = chatSnapshot.docs.first.data() as Map<String, dynamic>;
//
//             // Now, update the Firestore document with the latest message content
//             await FirebaseFirestore.instance.collection('messages').doc(doc.id).update({
//               'lastMessage': lastMessageDoc['content'],
//               'lastUpdated': FieldValue.serverTimestamp(), // Update the timestamp of the last message
//             });
//           }
//         }
//       }
//
//       setState(() {
//         _groupedMessages = groupedMessages;
//       });
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to load messages: $e')),
//       );
//     }
//   }
//
//   // Fetch sender's profile photo from the 'photo_profile' subcollection
//   Future<String> _getSenderProfilePhoto(String senderId) async {
//     try {
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(senderId)
//           .collection('photo_profile')
//           .doc('profile')
//           .get();
//
//       if (userDoc.exists) {
//         Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
//         return data['url'] ?? 'https://via.placeholder.com/150';
//       } else {
//         return 'https://via.placeholder.com/150';
//       }
//     } catch (e) {
//       return 'https://via.placeholder.com/150';
//     }
//   }
//
//   // Fetch sender's full name
//   Future<String> _getSenderFullName(String senderId) async {
//     try {
//       DocumentSnapshot userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(senderId)
//           .get();
//
//       if (userDoc.exists) {
//         Map<String, dynamic> data = userDoc.data() as Map<String, dynamic>;
//         return data['fullname'] ?? 'No name';
//       } else {
//         return 'No name';
//       }
//     } catch (e) {
//       return 'No name';
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Messages'),
//         automaticallyImplyLeading: false,
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: _groupedMessages.isEmpty
//             ? const Center(child: Text("No messages found"))
//             : ListView.builder(
//           itemCount: _groupedMessages.length,
//           itemBuilder: (context, index) {
//             String senderId = _groupedMessages.keys.elementAt(index);
//             List<DocumentSnapshot> messageDocs = _groupedMessages[senderId]!;
//
//             final messageData = messageDocs.first.data() as Map<String, dynamic>;
//             final messageContent = messageData['lastMessage'] ?? 'No content';
//             final timestamp = messageData['lastUpdated'].toDate();
//
//             return FutureBuilder<String>(
//               future: _getSenderProfilePhoto(senderId),
//               builder: (context, snapshot) {
//                 if (snapshot.connectionState == ConnectionState.waiting) {
//                   return ListTile(
//                     title: const Text('Loading...'),
//                   );
//                 }
//
//                 String senderProfileImage = snapshot.data ?? 'https://via.placeholder.com/150';
//
//                 return FutureBuilder<String>(
//                   future: _getSenderFullName(senderId),
//                   builder: (context, nameSnapshot) {
//                     if (nameSnapshot.connectionState == ConnectionState.waiting) {
//                       return ListTile(
//                         title: const Text('Loading full name...'),
//                       );
//                     }
//
//                     String senderFullName = nameSnapshot.data ?? 'No Name';
//
//                     return Card(
//                       margin: const EdgeInsets.symmetric(vertical: 6),
//                       elevation: 2,
//                       child: ListTile(
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//                         leading: CircleAvatar(
//                           backgroundImage: NetworkImage(senderProfileImage),
//                         ),
//                         title: Text(
//                           senderFullName,
//                           style: const TextStyle(fontWeight: FontWeight.bold),
//                         ),
//                         subtitle: Text(
//                           messageContent,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                           style: TextStyle(color: Colors.grey[700]),
//                         ),
//                         trailing: Text(
//                           DateFormat('HH:mm').format(timestamp),
//                           style: TextStyle(fontSize: 12, color: Colors.grey[600]),
//                         ),
//                         onTap: () {
//                           // Navigate to the message details page
//                           Navigator.push(
//                             context,
//                             MaterialPageRoute(
//                               builder: (context) => MessageDetailsPage(
//                                 conversationId: messageDocs.first.id,  // Use messageDoc ID as conversation ID
//                                 senderId: senderId,  // Pass senderId
//                                 receiverId: _userId,  // Current user as receiverId
//                                 messageContent: messageContent,  // Pass the message content
//                               ),
//                             ),
//                           );
//                         },
//                       ),
//                     );
//                   },
//                 );
//               },
//             );
//           },
//         ),
//       ),
//       bottomNavigationBar: BottomNavigationBarWidget(
//         currentIndex: _currentIndex,
//         onTap: (index) {
//           setState(() {
//             _currentIndex = index;
//           });
//         },
//       ),
//     );
//   }
// }
