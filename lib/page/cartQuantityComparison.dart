import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> addToCart({
  required String userId,
  required String listingId,
  required Map<String, dynamic> listingData,
  required int quantity,
  required String serviceTime,
  required BuildContext context,
}) async {
  try {
    // Create a cart item object
    Map<String, dynamic> cartItem = {
      'name': listingData['name'],
      'price': listingData['price'],
      'quantity': quantity,
      'image': listingData['image'],
      'listingType': listingData['listingType'],
      'status': 'In Stock', // You can set this based on your product
      'isSelected': false, // Initialize isSelected as false
      'listingId': listingId, // Include the listingId to track the item
      'serviceTime': serviceTime, // For services, store the time
    };

    // Check if the item already exists in the user's cart subcollection
    FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('cartItems')
        .where('listingId', isEqualTo: listingId)
        .get()
        .then((querySnapshot) async {
      if (querySnapshot.docs.isEmpty) {
        // If the item does not exist, add it to the cart
        await FirebaseFirestore.instance.collection('users').doc(userId).collection('cartItems').add(cartItem);
      } else {
        // If the item exists, we need to compare the quantity
        var cartItemDoc = querySnapshot.docs.first;
        int cartQuantity = cartItemDoc['quantity'];

        // Fetch available stock from the listing collection
        DocumentSnapshot listingSnapshot = await FirebaseFirestore.instance.collection('listings').doc(listingId).get();
        int availableQuantity = int.tryParse(listingSnapshot['quantity'].toString()) ?? 0;

        if (cartQuantity + quantity > availableQuantity) {
          // If the total quantity exceeds available stock, show an error message
          _showErrorMessage("Cannot add more items to the cart. Stock is limited.", context);
        } else {
          // If stock is available, update the quantity
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .collection('cartItems')
              .doc(cartItemDoc.id)
              .update({
            'quantity': FieldValue.increment(quantity),
          });
        }
      }
    }).catchError((e) {
      print("Error checking item in cart: $e");
    });
  } catch (e) {
    print("Error adding item to cart: $e");
  }
}

void _showErrorMessage(String message, BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("OK"),
          ),
        ],
      );
    },
  );
}
