import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> deleteMessage(BuildContext context, String conversationId, String messageId) async {
  // Show confirmation dialog before deletion
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Delete Message'),
      content: Text('Are you sure you want to delete this message?'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(); // Close dialog if cancelled
          },
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () async {
            try {
              // Delete the message document from the 'messages' subcollection inside the conversation doc
              await FirebaseFirestore.instance
                  .collection('messages')
                  .doc(conversationId)
                  .collection('messages')
                  .doc(messageId)
                  .delete();

              // Optionally, update the parent conversation doc's lastMessage and lastUpdated fields here if needed

              // Close the dialog after deletion
              Navigator.of(context).pop();
            } catch (e) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to delete message: $e')),
              );
            }
          },
          child: Text('Delete'),
        ),
      ],
    ),
  );
}
