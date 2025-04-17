import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home.dart';

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
  String? _price;
  double? _productPrice;
  int? _quantity;
  bool _isProduct = true;
  late User _user;
  String? _listingImageUrl;
  bool _isUploadingImage = false;

  String? _customCategory;
  String? _customServiceCategory;

  @override
  void initState() {
    super.initState();
    _user = _auth.currentUser!;
  }

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
        ..fields['folder'] = 'listing_photo'
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      try {
        final response = await request.send();
        if (response.statusCode == 200) {
          final resStr = await response.stream.bytesToString();
          final resJson = json.decode(resStr);
          final downloadUrl = resJson['secure_url'];

          await FirebaseFirestore.instance
              .collection('users')
              .doc(_user.uid)
              .collection('photo_listing')
              .doc('listing')
              .set({'url': downloadUrl});

          setState(() {
            _listingImageUrl = downloadUrl;
          });
        } else {
          print("Cloudinary upload failed: ${response.statusCode}");
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

  Future<void> _submitListing() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        final user = _auth.currentUser;
        String imageUrl = _listingImageUrl ?? '';

        String? finalCategory = _isProduct
            ? (_category == 'other' ? 'other product' : _category)
            : (_serviceCategory == 'other' ? 'other service' : _serviceCategory);

        final listingData = {
          'listingType': _listingType,
          'name': _isProduct ? _productName : _serviceName,
          'name_lowercase': (_isProduct ? _productName : _serviceName)?.toLowerCase(),
          'description': _description ?? _serviceDescription,
          'category': finalCategory,
          'customCategory': _isProduct ? _customCategory : null,
          'customServiceCategory': !_isProduct ? _customServiceCategory : null,
          'condition': _isProduct ? _condition : null,
          'price': _isProduct ? _productPrice : _price,
          'quantity': _quantity,
          'image': imageUrl,
          'userId': user?.uid,
          'timestamp': FieldValue.serverTimestamp(),
          'listingStatus': 'active',
        };

        await FirebaseFirestore.instance.collection('listings').add(listingData);

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
              (Route<dynamic> route) => false,
        );
      } catch (e) {
        print("Error creating listing: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Listing')),
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
              GestureDetector(
                onTap: _uploadListingImage,
                child: Container(
                  height: 100,
                  color: Colors.grey[200],
                  child: Center(
                    child: _isUploadingImage
                        ? CircularProgressIndicator()
                        : (_listingImageUrl == null
                        ? Text('Select Image')
                        : Image.network(_listingImageUrl!)),
                  ),
                ),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitListing,
                child: Text('Submit Listing'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}