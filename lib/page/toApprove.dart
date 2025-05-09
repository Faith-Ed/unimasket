import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:redofyp/page/time_picker_helper.dart';

class ToApproveScreen extends StatefulWidget {
  final String orderId;  // Pass the order ID to this screen

  const ToApproveScreen({Key? key, required this.orderId}) : super(key: key);

  @override
  _ToApproveScreenState createState() => _ToApproveScreenState();
}

class _ToApproveScreenState extends State<ToApproveScreen> {
  late Future<DocumentSnapshot> _orderFuture;
  final TextEditingController _sellerNotesController = TextEditingController();
  final TextEditingController _orderTotalController = TextEditingController();
  final TextEditingController _declineReasonController = TextEditingController();
  final TextEditingController _pickupLocationController = TextEditingController();
  final TextEditingController _deliveryTimeController = TextEditingController();
  late String _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;

    // Fetch the order data from Firestore based on orderId
    _orderFuture = FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get();

    // Fetch seller notes from the subcollection and update the controller
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .collection('user_notes')
        .doc('seller_notes')
        .get()
        .then((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _sellerNotesController.text = snapshot.data()!['note'] ?? ''; // Update the seller notes text controller
      }
    });

    // Fetch order total and update the controller
    FirebaseFirestore.instance
        .collection('orders')
        .doc(widget.orderId)
        .get()
        .then((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        _orderTotalController.text = snapshot.data()!['totalPrice']?.toString() ?? '0.00'; // Update the order total
      }
    });
  }

// Method to handle accepting the order
  Future<void> _acceptOrder(Map<String, dynamic> orderData) async {
    print("Collection Option: ${orderData['collectionOption']}");
    // Fetch the collection option and show the respective dialog box
    if (orderData['collectionOption'] == 'Self Pick-up') {
      _showPickupDialog(orderData['paymentMethod']);
    } else if (orderData['collectionOption'] == 'Delivery') {
      _showDeliveryDialog(orderData['paymentMethod']);
    }
  }

// Show Pickup Location Dialog
  Future<void> _showPickupDialog(String paymentMethod) async {
    // Show dialog
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Pickup Location and Pickup Time"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pickup Location Section
              TextField(
                controller: _pickupLocationController,
                decoration: InputDecoration(hintText: "Enter pickup location here..."),
                maxLines: 2,
              ),
              SizedBox(height: 10), // Space between the sections

              // Date/Time Section
              TextField(
                controller: _deliveryTimeController,
                decoration: InputDecoration(
                  hintText: "Click to select pickup time...",
                ),
                readOnly: true, // Make it read-only, user taps to select the time
                onTap: () async {
                  // Trigger the date and time picker
                  String? selectedTime = await TimePickerHelper.pickServiceTime(context);

                  // If the user selects a time, update the controller
                  if (selectedTime != null) {
                    print("Selected Pickup Time: $selectedTime"); // Debug print
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
              onPressed: () {
                // Validate input and update order status
                if (_pickupLocationController.text.isNotEmpty && _deliveryTimeController.text.isNotEmpty) {
                  // Call the updated function with both pickup location and delivery time
                  _sendAcceptedOrder('pickup', _pickupLocationController.text, _deliveryTimeController.text);
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

// Show Delivery Time Dialog using TimePickerHelper
  Future<void> _showDeliveryDialog(String paymentMethod) async {
    print("Showing Delivery Dialog"); // Debug print
    if (!mounted) return; // Check if the widget is still mounted

    // Show an initial dialog asking for the estimated delivery time
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Enter Estimated Delivery Time"),
          content: TextField(
            controller: _deliveryTimeController,
            decoration: InputDecoration(hintText: "Click to select delivery time..."),
            readOnly: true,  // Make the field read-only, user should click it to pick time
            onTap: () async {
              // When user taps the text field, invoke the time picker
              String? selectedTime = await TimePickerHelper.pickServiceTime(context);

              // If the user selected a time, update the text field with the selected time
              if (selectedTime != null) {
                print("Selected Delivery Time: $selectedTime"); // Debug print
                _deliveryTimeController.text = selectedTime;
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Please select a delivery time.')),
                );
              }
            },
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Validate and send accepted order if delivery time is selected
                if (_deliveryTimeController.text.isNotEmpty) {
                  _sendAcceptedOrder('delivery', '', _deliveryTimeController.text);
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

  String _getConversationId(String senderId, String receiverId) {
    return senderId.hashCode <= receiverId.hashCode
        ? '$senderId-$receiverId' // Format as id1-id2
        : '$receiverId-$senderId'; // Format as id2-id1
  }

// Send Accepted Order and Save the Information in Subcollection
  Future<void> _sendAcceptedOrder(String collectionOptionType, String pickupLocation, String deliveryTime) async {
    try {
      final orderSnapshot = await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).get();
      final receiverId = orderSnapshot.data()!['userId'];  // Get the buyer's userId
      final paymentMethod = orderSnapshot.data()!['paymentMethod'];  // Fetch the payment method

      // Generate the messageId
      String conversationId = _getConversationId(_currentUserId, receiverId);

      // Get products array from the order
      final List<dynamic> products = orderSnapshot.data()?['products'] ?? [];

      // Update product status to 'Declined'
      for (var i = 0; i < products.length; i++) {
        if (products[i]['creatorId'] == _currentUserId) {
          // Update the product's status if the product's creatorId matches the current user's id
          products[i]['status'] = 'Accepted';

          // Get the listingId and quantity from the product
          String listingId = products[i]['listingId'];
          int orderQuantity = products[i]['orderQuantity'];

          // Update the stock quantity in the listings collection
          await FirebaseFirestore.instance.collection('listings')
              .doc(listingId) // Get the document of the listing by listingId
              .update({
            'quantity': FieldValue.increment(-orderQuantity), // Reduce the stock by order quantity
          });

          // Check if the quantity is 0 and update listingStatus to 'inactive' if so
          final listingSnapshot = await FirebaseFirestore.instance.collection('listings')
              .doc(listingId).get();

          int updatedQuantity = listingSnapshot.data()?['quantity'] ?? 0;
          if (updatedQuantity == 0) {
            await FirebaseFirestore.instance.collection('listings')
                .doc(listingId)
                .update({
              'listingStatus': 'inactive', // Set listingStatus to 'inactive' when quantity is 0
            });
          }
        }
      }

      // Update the products array in the Firestore order document
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'status': 'Accepted',  // Set the overall order status to Declined
        'products': products,  // Update the products array with the modified product statuses
      });

      // Prepare the data for accepted_notes subcollection
      Map<String, dynamic> acceptedData = {
        'acceptedBy': _currentUserId,
        'status': 'Accepted',
        'timestamp': FieldValue.serverTimestamp(),
      };

      // Add either pickup location or delivery time to the accepted data
      if (collectionOptionType == 'pickup') {
        acceptedData['pickupLocation'] = pickupLocation;
        acceptedData['pickupTime'] = deliveryTime;  // Add the delivery time if it's pickup
      } else if (collectionOptionType == 'delivery') {
        acceptedData['deliveryTime'] = deliveryTime;
      }

      // Save accepted notes to subcollection
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId)
          .collection('accepted_notes').doc('note').set(acceptedData);

      String qrCodeUrl = '';  // Initialize an empty string for QR Code URL

      // If the payment method is QR code, fetch the QR code image URL from the Firestore user's subcollection
      if (paymentMethod == 'QR Code') {
        qrCodeUrl = await _fetchQRCodeUrl();  // Fetch QR code URL directly
      }

      // Prepare the message content with Pickup Location and Pickup Time (or Delivery Time)
      String messageContent = "";
      if (collectionOptionType == 'pickup') {
        if (pickupLocation.isNotEmpty) {
          messageContent += 'Pickup Location: $pickupLocation\n'; // Add Pickup Location
        }
        if (deliveryTime.isNotEmpty) {
          messageContent += 'Pickup Time: $deliveryTime'; // Add Pickup Time for pickup
        }
      } else if (collectionOptionType == 'delivery') {
        if (deliveryTime.isNotEmpty) {
          messageContent += 'Delivery Time: $deliveryTime'; // Add Delivery Time for delivery
        }
      }

      // If QR code URL is available, add it to the message content
      if (qrCodeUrl.isNotEmpty) {
        messageContent += '\nQR Code for Payment: \n';
      }

      String messageId = _getConversationId(_currentUserId, receiverId);

      // Create or update a message in the 'messages' collection for this order
      final currentTime = FieldValue.serverTimestamp();
      final messageRef = FirebaseFirestore.instance.collection('messages').doc(messageId);

      // Set or update the last message in the 'messages' collection
      await messageRef.set({
        'senderId': _currentUserId,
        'receiverId': receiverId,
        'lastMessage': messageContent,
        'lastUpdated': currentTime,
      }, SetOptions(merge: true));

      // Add the message to the 'chats' subcollection (this will contain the QR code as well)
      await messageRef.collection('chats').add({
        'senderId': _currentUserId,
        'receiverId': receiverId,
        'content': messageContent,
        'timestamp': currentTime,
        'isDeleted': false,
        'orderId': widget.orderId,
        'qrCodeImageUrl': qrCodeUrl,  // Add QR code image URL to chat message
      });

      // Close the dialog after the message is saved
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Order accepted and information sent.')));
    } catch (e) {
      print("Error sending accepted order: $e");
    }
  }

// Fetch QR code URL directly from Firestore
  Future<String> _fetchQRCodeUrl() async {
    try {
      final qrCodeDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUserId)  // Use current user's UID
          .collection('qr_codes')
          .doc('profile')
          .get();

      if (qrCodeDoc.exists) {
        return qrCodeDoc['url'] ?? '';  // Return the QR code URL from Firestore
      } else {
        print("QR code not found for the user.");
        return '';  // If QR code doesn't exist, return an empty string
      }
    } catch (e) {
      print("Error fetching QR code URL: $e");
      return '';  // Return an empty string in case of an error
    }
  }

  // Method to handle declining the order
  void _showDeclineDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Provide Reason for Decline"),
          content: TextField(
            controller: _declineReasonController,
            decoration: InputDecoration(hintText: "Enter reason here..."),
            maxLines: 4,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                // Validate decline reason
                if (_declineReasonController.text.isNotEmpty) {
                  // Get receiverId from order data
                  _declineOrder();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Please provide a reason for declining.')),
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

  Future<void> _declineOrder() async {
    try {
      // Get receiverId from order data
      final orderSnapshot = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();
      final receiverId = orderSnapshot.data()!['userId'];

      // Get the current user's ID
      final currentUserId = FirebaseAuth.instance.currentUser!.uid;

      // Ensure that we get the same messageId regardless of the order of senderId and receiverId
      String messageId = _getMessageId(currentUserId, receiverId);

      // Get products array from the order
      final List<dynamic> products = orderSnapshot.data()?['products'] ?? [];

      // Update product status to 'Declined'
      for (var i = 0; i < products.length; i++) {
        if (products[i]['creatorId'] == currentUserId) {
          // Update the product's status if the product's creatorId matches the current user's id
          products[i]['status'] = 'Declined';
        }
      }

      // Update the products array in the Firestore order document
      await FirebaseFirestore.instance.collection('orders').doc(widget.orderId).update({
        'status': 'Declined',  // Set the overall order status to Declined
        'products': products,  // Update the products array with the modified product statuses
      });

      // Create a message in the 'messages' collection for this order
      final currentTime = FieldValue.serverTimestamp();
      final messageRef = FirebaseFirestore.instance.collection('messages').doc(messageId);

      // Set or update the last message in the 'messages' collection
      await messageRef.set({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'lastMessage': _declineReasonController.text,
        'lastUpdated': currentTime,
      }, SetOptions(merge: true));

      // Add the decline message to the 'chats' subcollection under the 'messages' collection
      await messageRef.collection('chats').add({
        'senderId': currentUserId,
        'receiverId': receiverId,
        'content': _declineReasonController.text,
        'timestamp': currentTime,
        'isDeleted': false, // mark as not deleted initially
        'orderId': widget.orderId,
      });

      // Save the decline reason in the decline_reason subcollection under orders
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .collection('decline_reason')
          .doc('reason')
          .set({
        'reason': _declineReasonController.text,
        'declinedBy': currentUserId,
        'timestamp': currentTime,
      });

      // Close the dialog after the message has been saved
      Navigator.pop(context);
    } catch (e) {
      print("Error declining order: $e");
    }
  }

  // Method to return the correct messageId based on sender and receiver
  String _getMessageId(String senderId, String receiverId) {
    // Ensure that we get the same messageId regardless of the order of senderId and receiverId
    return senderId.hashCode <= receiverId.hashCode
        ? '$senderId-$receiverId' // For senderId < receiverId
        : '$receiverId-$senderId'; // For receiverId < senderId
  }

  // Method to build the order content
  Widget _buildOrderContent(Map<String, dynamic> orderData) {
    final status = orderData['status'];
    final paymentMethod = orderData['paymentMethod'];
    final collectionOption = orderData['collectionOption'];
    final String deliveryLocation = orderData['deliveryLocation'] ?? '';
    final List<dynamic> products = orderData['products'] ?? [];
    final Map service = orderData['services'] ?? {};  // Single service map
    final creatorId = orderData['creatorId'];

    // Filter products by the current user
    final filteredProducts = products.where((item) {
      return item is Map<String, dynamic> &&
          item['creatorId'] == FirebaseAuth.instance.currentUser!.uid;
    }).toList();

    // Check if the service belongs to the current user
    bool serviceBelongsToUser = creatorId == FirebaseAuth.instance.currentUser!.uid;

    double total = 0.0; // To calculate total order cost

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display filtered products (products that belong to the current user)
          if (filteredProducts.isNotEmpty)
            Container(
              width: MediaQuery.of(context).size.width * 0.9,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: filteredProducts.map<Widget>((item) {
                      double itemTotal = item['orderQuantity'] * item['itemPrice'];
                      total += itemTotal;
                      return Column(
                        children: [
                          Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item['itemImage'] ?? 'https://via.placeholder.com/150',
                                  height: 70,
                                  width: 70,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['itemName'] ?? 'No Name',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "Quantity: ${item['orderQuantity'] ?? 0}",
                                      style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                                    ),
                                    SizedBox(height: 5),
                                    Text("Price: RM ${item['itemPrice'] ?? 0.0}",
                                      style: const TextStyle(fontWeight: FontWeight.w400, fontSize: 14),
                                    ),
                                    SizedBox(height: 5),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                        ],
                      );
                    }).toList(),
                  ),
                  const Divider(),
                  // Order Summary: Order Total
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,  // Align items to the start
                          children: [
                            Text(
                              'Collection Option: ',
                              style: TextStyle(fontWeight: FontWeight.bold), // Bold label
                            ),
                            Text.rich(
                              TextSpan(
                                text: collectionOption == 'Delivery' && deliveryLocation.isNotEmpty
                                    ? 'Delivery '  // Show 'Delivery' first
                                    : collectionOption,  // If not Delivery, just show collectionOption
                                style: TextStyle(fontWeight: FontWeight.normal),  // Normal value for 'Delivery' or other options
                                children: [
                                  if (collectionOption == 'Delivery' && deliveryLocation.isNotEmpty)
                                    TextSpan(
                                      text: '($deliveryLocation)',  // Display delivery location
                                      style: TextStyle(color: Colors.redAccent),  // Color just for delivery location
                                    ),
                                ],
                              ),
                            )
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Payment Method: ',
                              style: TextStyle(fontWeight: FontWeight.bold), // Bold label
                            ),
                            Text(
                              '$paymentMethod',
                              style: TextStyle(fontWeight: FontWeight.normal), // Normal value
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        const Divider(),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order Total: ',
                              style: TextStyle(fontWeight: FontWeight.bold), // Bold label
                            ),
                            Text(
                              'RM $total',
                              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 18), // Normal value
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                      ],
                    ),
                  )
                ],
              ),
            ),
          // Display service details if it belongs to the current user
          if (creatorId == FirebaseAuth.instance.currentUser!.uid)
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Service Details",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          service['serviceImage'] ?? 'https://via.placeholder.com/150',
                          height: 70,
                          width: 70,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              service['serviceName'] ?? 'No Service Name',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text("Service Time: ${service['serviceTime'] ?? '-'}"),
                            Text("Service Location: ${service['serviceLocation'] ?? '-'}"),
                            Text("Service Destination: ${service['serviceDestination'] ?? '-'}"),
                            Text("Additional Notes: ${service['additionalNotes'] ?? '-'}"),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(),

                  // Seller Notes Section
                  const SizedBox(height: 5),
                  Text(
                    "Seller Notes (For your own record):",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: MediaQuery.of(context).size.width * 0.8,
                    child: TextField(
                      controller: _sellerNotesController,
                      decoration: InputDecoration(
                        hintText: "Enter seller notes here...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 4, horizontal: 8),  // Reduced padding for smaller height
                      ),
                      maxLines: 5,  // Limit the number of lines to reduce height
                      onChanged: (value) {
                        // Save seller notes in the subcollection
                        FirebaseFirestore.instance
                            .collection('orders')
                            .doc(widget.orderId)
                            .collection('user_notes')
                            .doc('seller_notes')
                            .set({'note': value});
                      },
                    ),
                  ),

                  // Order Total
                  SizedBox(height: 8),
                  const Divider(),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Order Total: ',
                        style: TextStyle(fontWeight: FontWeight.bold), // Bold label
                      ),
                      SizedBox(
                        width: 120,  // Width of the TextField and label container
                        height: 30,  // Height of the TextField
                        child: Row(
                          children: [
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                "RM",
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ),
                            Expanded(
                              child: TextField(
                                controller: _orderTotalController,
                                decoration: InputDecoration(
                                  hintText: "0.00", // Placeholder for price
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 12), // Adjust the height here
                                ),
                                keyboardType: TextInputType.number, // Numeric input
                                onChanged: (value) {
                                  // Update total price when the user enters the amount
                                  double? newTotal = double.tryParse(value);
                                  if (newTotal != null) {
                                    FirebaseFirestore.instance
                                        .collection('orders')
                                        .doc(widget.orderId)
                                        .update({'totalPrice': newTotal});
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // Order ID and Time Section (Container 2)
  Widget _buildOrderIdAndTime(Map<String, dynamic> orderData) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 5)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order ID:'),
              Text(widget.orderId),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Order Time:'),
              Text(orderData['orderTime']?.toDate().toString() ?? 'No Time'),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: _orderFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: Text("Order not found"));
          }

          final orderData = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildOrderContent(orderData),
                  const SizedBox(height: 3),
                  _buildOrderIdAndTime(orderData),
                  const SizedBox(height: 20),
                  // Buttons for Accept and Decline
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          _acceptOrder(orderData);
                        },
                        child: Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),
                          ),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _showDeclineDialog();
                        },
                        child: const Text('Decline'),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5.0),  // No rounded corners for a square button
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
