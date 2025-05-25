// chat_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String messageText,
    String? imageUrl,
    String? orderId,
    String? qrCodeImageUrl,
    Map<String, dynamic>? productDetails,  // For product image, name etc.
    Map<String, dynamic>? serviceDetails,  // For service image, name etc.
  }) async {
    if (senderId == receiverId) return; // Prevent sending message to self

    final chatId = _generateChatId(senderId, receiverId);
    final chatDocRef = _firestore.collection('messages').doc(chatId);
    final messagesCollection = chatDocRef.collection('messages');
    final timestamp = FieldValue.serverTimestamp();

    // Compose imageUrl and name from product or service details if provided
    String? imgUrl = imageUrl;
    String? itemName;

    if (productDetails != null) {
      imgUrl = productDetails['itemImage'] ?? imgUrl;
      itemName = productDetails['itemName'];
    } else if (serviceDetails != null) {
      imgUrl = serviceDetails['serviceImage'] ?? imgUrl;
      itemName = serviceDetails['serviceName'];
    }

    // Include itemName in the message if available
    final fullMessage = itemName != null ? '$itemName\n$messageText' : messageText;

    await messagesCollection.add({
      'senderId': senderId,
      'message': fullMessage,
      'timestamp': timestamp,
      'imageUrl': imgUrl ?? '',
      'orderId': orderId,
      'qrCodeImageUrl': qrCodeImageUrl ?? '',
      'isDeleted': false,
      'seenBy': [senderId],  // Initialize seenBy with sender only
    });

    await chatDocRef.set({
      'participants': [senderId, receiverId],
      'lastMessage': fullMessage.isNotEmpty ? fullMessage : '[photo]',
      'lastUpdated': timestamp,
    }, SetOptions(merge: true));
  }

  String _generateChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
