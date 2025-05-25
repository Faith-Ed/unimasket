import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:redofyp/page/listing/viewListingDetails.dart';
import 'package:redofyp/widgets/pageDesign.dart';
import 'dart:io';
import '../main/home.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class CreateListingScreen extends StatefulWidget {
  @override
  _CreateListingScreenState createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();

  String? _listingType;
  String? _category;
  String? _condition;
  String? _serviceCategory;
  String? _productName;
  String? _serviceName;
  String? _description;
  String? _serviceDescription;
  String? _price; // Service price will be a string
  double? _productPrice; // Product price will be a double
  int? _quantity; // Quantity will be a number
  bool _isProduct = true;
  late User _user;  // User variable
  String? _listingImageUrl; // This will store the Cloudinary URL (String)
  bool _isUploadingImage = false;

  // Custom category fields
  String? _customCategory;
  String? _customServiceCategory;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;  // Initialize the user when the screen is initialized
  }

  // Upload image to Cloudinary
  Future<void> _uploadListingImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      final file = File(pickedFile.path);

      final cloudinaryUploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/dgou42nni/image/upload');

      setState(() {
        _isUploadingImage = true;
      });

      final request = http.MultipartRequest('POST', cloudinaryUploadUrl)
        ..fields['upload_preset'] = 'flutter_unsigned'
        ..fields['folder'] = 'listing_photo'  // Specify the folder for listing images
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      try {
        final response = await request.send();

        if (response.statusCode == 200) {
          final resStr = await response.stream.bytesToString();
          final resJson = json.decode(resStr);
          final downloadUrl = resJson['secure_url'];

          // Save Cloudinary image URL to Firestore
          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user.uid)
              .collection('photo_listing')
              .doc('listing')
              .set({'url': downloadUrl});

          setState(() {
            _listingImageUrl = downloadUrl; // Store the URL, not the File
          });
        } else {
          print("Cloudinary upload failed with status: ${response.statusCode}");
        }
      } catch (e) {
        print("Image upload error: $e");
      } finally {
        setState(() {
          _isUploadingImage = false;
        });
      }
    }
  }

  // Submit the listing
  Future<void> _submitListing() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        String imageUrl = _listingImageUrl ?? '';

        // Determine final category
        String? finalCategory;

        // If it's a product listing
        if (_isProduct) {
          if (_category == 'other') {
            // If category is "other" for product, store as "other product"
            finalCategory = 'other product';
          } else {
            finalCategory = _category;
          }
        }
        // If it's a service listing
        else {
          if (_serviceCategory == 'other') {
            // If category is "other" for service, store as "other service"
            finalCategory = 'other service';
          } else {
            finalCategory = _serviceCategory;
          }
        }

        final user = _auth.currentUser;
        final listingData = {
          'listingType': _listingType,
          'name': _isProduct ? _productName : _serviceName,
          'name_lowercase': (_isProduct ? _productName : _serviceName)?.toLowerCase(),  // Store lowercase version of the name
          'description': _description ?? _serviceDescription,
          'category': finalCategory,
          'customCategory': _isProduct ? _customCategory : null,
          'customServiceCategory': !_isProduct ? _customServiceCategory : null,
          'condition': _isProduct ? _condition : null,
          'price': _isProduct ? _productPrice : _price, // Save as double for product or string for service
          'quantity': _quantity, // Store as number (double or int)
          'image': imageUrl,
          'userId': user?.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'listingStatus': 'active',
        };

        // Add listing and get reference
        final listingRef = await FirebaseFirestore.instance.collection('listings').add(listingData);

        // Prepare batch for notifications
        final batch = FirebaseFirestore.instance.batch();

        // Fetch all users to notify
        final usersSnapshot = await FirebaseFirestore.instance.collection('users').get();

        for (var userDoc in usersSnapshot.docs) {
          final isCurrentUser = (userDoc.id == user?.uid);

          // Notification document reference in flat notifications collection
          final notifRef = userDoc.reference.collection('notifications').doc();

          batch.set(notifRef, {
            'category': 'listing',
            'isSeen': false,
            'isSelected': false,
            'message': isCurrentUser
                ? 'Your listing "${_isProduct ? _productName : _serviceName}" was successfully created.'
                : 'New ${_listingType ?? 'listing'} created: ${_isProduct ? _productName : _serviceName}',
            'orderId': null,                    // null because this is listing notification
            'listingId': listingRef.id,        // ID of the new listing
            'timestamp': FieldValue.serverTimestamp(),
            'type': isCurrentUser ? 'listing_creation_success' : 'new_listing',
            'userId': user?.uid,
          });
        }

        // Commit batch notifications
        await batch.commit();

        // Navigate to ViewListingDetails page with new listing ID
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => ViewListingDetailsScreen(listingId: listingRef.id)
          ),
              (route) => false,
        );
      } catch (e) {
        print("Error creating listing or notifications: $e");
        // Optionally show error message to user here
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: customAppBar('Create Listing'),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: 'Choose listing type'),
                value: _listingType,
                items: [
                  DropdownMenuItem(value: 'product', child: Text('Product')),
                  DropdownMenuItem(value: 'service', child: Text('Service')),
                ],
                onChanged: (value) {
                  setState(() {
                    _listingType = value;
                    _isProduct = value == 'product';
                    _customCategory = null;
                    _customServiceCategory = null;
                  });
                },
                validator: (value) => value == null ? 'Please select a listing type' : null,
              ),
              SizedBox(height: 16),

              if (_isProduct)
                ...[
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Product Name'),
                    onChanged: (value) => _productName = value,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter product name' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Product Description'),
                    onChanged: (value) => _description = value,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter product description' : null,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Category'),
                    value: _category,
                    items: [
                      'electronics', 'books', 'food and beverages', 'clothes', 'home appliances', 'other'
                    ].map((category) => DropdownMenuItem(value: category, child: Text(category))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _category = value;
                        if (value != 'other') _customCategory = null;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a category' : null,
                  ),
                  if (_category == 'other')
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Custom Category'),
                      onChanged: (value) => setState(() => _customCategory = value),
                      validator: (value) {
                        if (_category == 'other' && (value?.isEmpty ?? true)) {
                          return 'Please enter custom category';
                        }
                        return null;
                      },
                    ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Condition'),
                    value: _condition,
                    items: ['new', 'used'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (value) => setState(() => _condition = value),
                    validator: (value) => value == null ? 'Please select condition' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _quantity = int.tryParse(value ?? ''),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter quantity' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Price'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) => _productPrice = double.tryParse(value ?? ''),
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter price' : null,
                  ),
                ]
              else
                ...[
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Service Name'),
                    onChanged: (value) => _serviceName = value,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter service name' : null,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Service Description'),
                    onChanged: (value) => _serviceDescription = value,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter service description' : null,
                  ),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: 'Service Category'),
                    value: _serviceCategory,
                    items: ['printing', 'fetching', 'other'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (value) {
                      setState(() {
                        _serviceCategory = value;
                        if (value != 'other') _customServiceCategory = null;
                      });
                    },
                    validator: (value) => value == null ? 'Please select a service category' : null,
                  ),
                  if (_serviceCategory == 'other')
                    TextFormField(
                      decoration: InputDecoration(labelText: 'Custom Category'),
                      onChanged: (value) => setState(() => _customServiceCategory = value),
                      validator: (value) {
                        if (_serviceCategory == 'other' && (value?.isEmpty ?? true)) {
                          return 'Please enter custom category';
                        }
                        return null;
                      },
                    ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Price Description'),
                    onChanged: (value) => _price = value,
                    validator: (value) => value?.isEmpty ?? true ? 'Please enter price description' : null,
                  ),
                ],
              SizedBox(height: 16),
              GestureDetector(
                onTap: _uploadListingImage,
                child: Container(
                  height: 100,
                  color: Colors.grey[700],
                  child: Center(
                    child: _isUploadingImage
                        ? CircularProgressIndicator()
                        : (_listingImageUrl == null
                        ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.upload_file,  // Upload icon
                          color: Colors.white,  // Set icon color to white
                          size: 30,  // Set the size of the icon
                        ),
                        SizedBox(height: 8),  // Add some space between the icon and text
                        Text(
                          'Select Image',
                          style: TextStyle(color: Colors.white),  // Text color white
                        ),
                      ],
                    )
                        : Image.network(_listingImageUrl!)),
                  ),
                ),
              ),
              SizedBox(height: 40),
              ElevatedButton(
                onPressed: _submitListing,
                child: Text('Submit Listing'),
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.white,
                  backgroundColor: Colors.pink,
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
