import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PreviewImageScreen extends StatefulWidget {
  final File imageFile;
  final String conversationId;
  final String senderId;
  final String receiverId;

  const PreviewImageScreen({
    Key? key,
    required this.imageFile,
    required this.conversationId,
    required this.senderId,
    required this.receiverId,
  }) : super(key: key);

  @override
  _PreviewImageScreenState createState() => _PreviewImageScreenState();
}

class _PreviewImageScreenState extends State<PreviewImageScreen> {
  late TextEditingController _messageController;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _messageController = TextEditingController();
  }

  // Upload image and save message
  Future<void> _uploadImageToCloudinaryAndSend() async {
    setState(() {
      _isUploading = true;
    });

    try {
      final cloudinaryUploadUrl = Uri.parse(
          'https://api.cloudinary.com/v1_1/dgou42nni/image/upload');

      final request = http.MultipartRequest('POST', cloudinaryUploadUrl)
        ..fields['upload_preset'] = 'flutter_unsigned'
        ..files.add(
            await http.MultipartFile.fromPath('file', widget.imageFile.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        final resStr = await response.stream.bytesToString();
        final resJson = json.decode(resStr);
        final downloadUrl = resJson['secure_url'];

        // Now save the image URL to Firestore and send the message
        await _sendTextMessage(imageUrl: downloadUrl);

        // Navigate back to MessageDetailsPage
        Navigator.pop(context, 'send');
      } else {
        print("Cloudinary upload failed with status: ${response.statusCode}");
        setState(() {
          _isUploading = false;
        });
      }
    } catch (e) {
      print("Image upload error: $e");
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _sendTextMessage({String? imageUrl}) async {
    if (_messageController.text.isEmpty && imageUrl == null) return;

    String senderId = widget.senderId;
    String receiverId = widget.receiverId;

    final currentTime = FieldValue.serverTimestamp();
    String conversationId1 = '${senderId}-${receiverId}'; // id1-id2
    String conversationId2 = '${receiverId}-${senderId}'; // id2-id1

    var existingConversationSnapshot = await FirebaseFirestore.instance
        .collection('messages')
        .doc(conversationId1)
        .get();

    if (!existingConversationSnapshot.exists) {
      existingConversationSnapshot = await FirebaseFirestore.instance
          .collection('messages')
          .doc(conversationId2)
          .get();
    }

    if (existingConversationSnapshot.exists) {
      String conversationId = existingConversationSnapshot.id;
      String content = _messageController.text.trim();
      String lastMessage = content.isEmpty && imageUrl != null ? '[photo]' : content;

      await FirebaseFirestore.instance.collection('messages').doc(
          conversationId).collection('chats').add({
        'senderId': senderId,
        'receiverId': receiverId,
        'content': content,
        'timestamp': currentTime,
        'isDeleted': false,
        'imageUrl': imageUrl, // Save the image URL here
      });

      await FirebaseFirestore.instance.collection('messages').doc(
          conversationId).set({
        'senderId': receiverId,
        'receiverId': senderId,
        'lastMessage': lastMessage,
        'lastUpdated': currentTime,
      }, SetOptions(merge: true));

      _messageController.clear();
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview Image'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context), // Close and return
        ),
      ),
      body: Column(
        children: [
          // Image preview with Expanded to ensure it does not overflow
          Expanded(
            child: Center(
              child: Image.file(widget.imageFile), // Preview the image
            ),
          ),

          // TextField and Send Button at the bottom
          Padding(
            padding: const EdgeInsets.all(5.0),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: "  Type a message...",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30.0),
                            borderSide: const BorderSide(color: Colors.grey),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.greenAccent, // Background color
                        shape: BoxShape.circle, // Make the container round
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white), // Icon with a white color
                        onPressed: _uploadImageToCloudinaryAndSend,
                      ),
                    )

                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
