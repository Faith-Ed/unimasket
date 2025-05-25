import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static Future<void> sendNotificationToUser({
    required String userId,
    required String orderId,
    required String type,
    String? customMessage, // optional override
    String category = 'order',
  }) async {
    final message = customMessage ?? getMessageFromType(type);

    final notification = {
      'category': category,
      'isSeen': false,
      'isSelected': false,
      'message': message,
      'orderId': orderId,
      'timestamp': FieldValue.serverTimestamp(),
      'type': type,
      'userId': userId,
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(orderId) // Use orderId as fixed doc ID
        .set(notification, SetOptions(merge: true));

    print("📨 Notification '$type' sent to userId: $userId");
  }

  static String getMessageFromType(String type) {
    switch (type) {
      case 'order_placed':
        return 'Your order has been placed successfully.';
      case 'order_accepted':
        return 'Your order has been accepted by the seller.';
      case 'order_declined':
        return 'Your order has been declined by the seller.';
      case 'order_completed':
        return 'Your order has been marked as completed. Thank you!';
      case 'order_cancelled':
        return 'The order has been cancelled.';
      case 'seller_order_completed':
        return 'The order has been completed by the buyer. Please check and confirm.';
      default:
        return 'You have a new update on your order.';
    }
  }
}
