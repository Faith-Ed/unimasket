import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redofyp/chat/messageDetail.dart';  // Import the message detail page

class ChatSellerButton extends StatelessWidget {
  final String listingId; // The listing ID passed to fetch the creatorId

  const ChatSellerButton({Key? key, required this.listingId}) : super(key: key);

  // Generate chatId by sorting user IDs and joining with underscore
  String _generateChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  // Fetch the creatorId from Firestore using the listingId
  Future<Map<String, String?>> _getConversationDetails() async {
    try {
      DocumentSnapshot listingDoc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(listingId)
          .get();

      if (listingDoc.exists) {
        String creatorId = listingDoc['userId']; // seller's userId
        String currentUserId = FirebaseAuth.instance.currentUser!.uid;

        // Generate conversationId with underscore separator
        final String conversationId = _generateChatId(currentUserId, creatorId);

        // You can prefill messageContent or leave empty
        return {
          'conversationId': conversationId,
          'senderId': currentUserId,
          'receiverId': creatorId,
          'messageContent': 'Hello Seller!',
        };
      } else {
        print("Listing document does not exist for listingId: $listingId");
        return {};
      }
    } catch (e) {
      print("Error fetching conversation details for listingId $listingId: $e");
      return {};
    }
  }

  // Navigate to message details page with parameters
  Future<void> _chatWithSeller(BuildContext context) async {
    final conversationDetails = await _getConversationDetails();

    if (conversationDetails.isNotEmpty &&
        conversationDetails.values.every((element) => element != null)) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MessageDetailsPage(
            conversationId: conversationDetails['conversationId']!,
            senderId: conversationDetails['senderId']!,
            receiverId: conversationDetails['receiverId']!,
            messageContent: conversationDetails['messageContent']!,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch seller information.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () => _chatWithSeller(context),
      icon: const Icon(Icons.chat, color: Colors.white),
      label: const Text(
        'Chat with Seller',
        style: TextStyle(color: Colors.white),
      ),
      style: ButtonStyle(
        backgroundColor: MaterialStateProperty.all(Colors.black),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        ),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}