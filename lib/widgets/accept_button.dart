import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../page/seller/sellerAccept.dart';
import '../services/time_picker_helper.dart';
import '../services/notification_service.dart';

class AcceptButton extends StatelessWidget {
  final String orderId;

  AcceptButton({Key? key, required this.orderId}) : super(key: key);

  final TextEditingController _pickupLocationController = TextEditingController();
  final TextEditingController _deliveryTimeController = TextEditingController();

  Future<String> _getCurrentUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      throw Exception("User not logged in");
    }
  }

  Future<void> _acceptOrder(BuildContext context, Map<String, dynamic> orderData) async {
    bool isServiceOrder = false;
    if (orderData.containsKey('services') && orderData['services'] != null) {
      isServiceOrder = true;
    }

    if (isServiceOrder) {
      String currentUserId = await _getCurrentUserId();
      await _sendAcceptedOrder(context, currentUserId, '', '', ''); // No pickup/delivery details
    } else {
      if (orderData['collectionOption'] == 'Self Pick-up') {
        _showPickupDialog(context, orderData['paymentMethod']);
      } else if (orderData['collectionOption'] == 'Delivery') {
        _showDeliveryDialog(context, orderData['paymentMethod']);
      } else {
        String currentUserId = await _getCurrentUserId();
        await _sendAcceptedOrder(context, currentUserId, '', '', '');
      }
    }
  }

  Future<void> _showPickupDialog(BuildContext context, String paymentMethod) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Pickup Location and Pickup Time"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _pickupLocationController,
                decoration: InputDecoration(hintText: "Enter pickup location here..."),
                maxLines: 2,
              ),
              SizedBox(height: 10),
              TextField(
                controller: _deliveryTimeController,
                decoration: InputDecoration(hintText: "Click to select pickup time..."),
                readOnly: true,
                onTap: () async {
                  String? selectedTime = await TimePickerHelper.pickServiceTime(context);
                  if (selectedTime != null) {
                    _deliveryTimeController.text = selectedTime;
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please select a pickup time.')),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (_pickupLocationController.text.isNotEmpty && _deliveryTimeController.text.isNotEmpty) {
                  String currentUserId = await _getCurrentUserId();
                  await _sendAcceptedOrder(
                    context,
                    currentUserId,
                    'pickup',
                    _pickupLocationController.text,
                    _deliveryTimeController.text,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide both pickup location and pickup time.')),
                  );
                }
              },
              child: Text("Send"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeliveryDialog(BuildContext context, String paymentMethod) async {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Estimated Delivery Time"),
          content: TextField(
            controller: _deliveryTimeController,
            decoration: InputDecoration(hintText: "Click to select delivery time..."),
            readOnly: true,
            onTap: () async {
              String? selectedTime = await TimePickerHelper.pickServiceTime(context);
              if (selectedTime != null) {
                _deliveryTimeController.text = selectedTime;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select a delivery time.')),
                );
              }
            },
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text("Cancel")),
            TextButton(
              onPressed: () async {
                if (_deliveryTimeController.text.isNotEmpty) {
                  String currentUserId = await _getCurrentUserId();
                  await _sendAcceptedOrder(
                    context,
                    currentUserId,
                    'delivery',
                    '',
                    _deliveryTimeController.text,
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide an estimated delivery time.')),
                  );
                }
              },
              child: Text("Send"),
            ),
          ],
        );
      },
    );
  }

  String _generateChatId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> _sendAcceptedOrder(
      BuildContext context,
      String currentUserId,
      String collectionOptionType,
      String pickupLocation,
      String deliveryTime) async {
    try {
      final orderSnapshot = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      final orderData = orderSnapshot.data()!;
      final receiverId = orderData['userId'] as String? ?? '';
      final paymentMethod = orderData['paymentMethod'] as String? ?? '';

      bool isServiceOrder = false;
      Map<String, dynamic>? services;
      String? serviceTime;
      double? totalPrice;

      if (orderData.containsKey('services') && orderData['services'] is Map) {
        services = Map<String, dynamic>.from(orderData['services']);
        isServiceOrder = true;
        serviceTime = services['serviceTime']?.toString() ?? 'Not specified';

        var price = orderData['totalPrice'];
        if (price is int) {
          totalPrice = price.toDouble();
        } else if (price is double) {
          totalPrice = price;
        }
      }

      if (!isServiceOrder) {
        final List<dynamic> products = orderData['products'] ?? [];

        for (var product in products) {
          if (product['creatorId'] == currentUserId) {
            product['status'] = 'Accepted';
            String listingId = product['listingId'];
            int orderQuantity = product['orderQuantity'];

            await FirebaseFirestore.instance
                .collection('listings')
                .doc(listingId)
                .update({'quantity': FieldValue.increment(-orderQuantity)});

            final listingSnapshot =
            await FirebaseFirestore.instance.collection('listings').doc(listingId).get();

            int updatedQuantity = listingSnapshot.data()?['quantity'] ?? 0;
            if (updatedQuantity == 0) {
              await FirebaseFirestore.instance
                  .collection('listings')
                  .doc(listingId)
                  .update({'listingStatus': 'inactive'});
            }
          }
        }

        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'status': 'Accepted',
          'products': products,
        });
      } else {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'status': 'Accepted',
        });
      }

      // Update current user's notifications isSeen to false
      final userNotifsQuery = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('notifications')
          .where('orderId', isEqualTo: orderId)
          .get();

      for (var doc in userNotifsQuery.docs) {
        await doc.reference.update({'isSeen': false});
      }

      // Update or create notification for receiver (buyer)
      if (receiverId != currentUserId) {
        await NotificationService.sendNotificationToUser(
          userId: receiverId,
          orderId: orderId,
          type: 'order_accepted',
          // You can add a custom message if needed
        );
      }

      Map<String, dynamic> acceptedData = {
        'acceptedBy': currentUserId,
        'status': 'Accepted',
        'timestamp': FieldValue.serverTimestamp(),
      };

      if (collectionOptionType == 'pickup') {
        acceptedData['pickupLocation'] = pickupLocation;
        acceptedData['pickupTime'] = deliveryTime;
      } else if (collectionOptionType == 'delivery') {
        acceptedData['deliveryTime'] = deliveryTime;
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .collection('accepted_notes')
          .doc('note')
          .set(acceptedData);

      String messageContent = "";

      if (isServiceOrder) {
        messageContent +=
        "Service Time: ${serviceTime ?? 'Not specified'}\nTotal Price: \$${totalPrice?.toStringAsFixed(2) ?? 'N/A'}\n";
      }

      if (collectionOptionType == 'pickup') {
        if (pickupLocation.isNotEmpty) messageContent += 'Pickup Location: $pickupLocation\n';
        if (deliveryTime.isNotEmpty) messageContent += 'Pickup Time: $deliveryTime\n';
      } else if (collectionOptionType == 'delivery') {
        if (deliveryTime.isNotEmpty) messageContent += 'Delivery Time: $deliveryTime\n';
      }

      String qrCodeUrl = '';
      if (paymentMethod == 'QR Code') {
        qrCodeUrl = await _fetchQRCodeUrl(currentUserId);
      }

      if (qrCodeUrl.isNotEmpty) {
        messageContent += '\nQR Code for Payment: \n';
      }

      String chatId = _generateChatId(currentUserId, receiverId);
      final currentTime = FieldValue.serverTimestamp();
      final messageRef = FirebaseFirestore.instance.collection('messages').doc(chatId);

      await messageRef.set({
        'participants': [currentUserId, receiverId],
        'lastMessage': messageContent,
        'lastUpdated': currentTime,
      }, SetOptions(merge: true));

      await messageRef.collection('messages').add({
        'senderId': currentUserId,
        'message': messageContent,
        'timestamp': currentTime,
        'isDeleted': false,
        'orderId': orderId,
        'qrCodeImageUrl': qrCodeUrl,
        'seenBy': [currentUserId],
      });

      Navigator.pop(context);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SellerAcceptOrderScreen(orderId: orderId),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order accepted and information sent.')));
    } catch (e) {
      print("Error sending accepted order: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to accept order. Please try again.')));
    }
  }

  Future<String> _fetchQRCodeUrl(String currentUserId) async {
    try {
      final qrCodeDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUserId)
          .collection('qr_codes')
          .doc('profile')
          .get();

      if (qrCodeDoc.exists) {
        return qrCodeDoc['url'] ?? '';
      } else {
        return '';
      }
    } catch (e) {
      print("Error fetching QR code URL: $e");
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () async {
        final orderSnapshot =
        await FirebaseFirestore.instance.collection('orders').doc(orderId).get();

        if (!orderSnapshot.exists) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order not found.')));
          return;
        }

        final orderData = orderSnapshot.data()!;
        await _acceptOrder(context, orderData);
      },
      child: Text('Accept'),
      style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5.0)),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }
}
