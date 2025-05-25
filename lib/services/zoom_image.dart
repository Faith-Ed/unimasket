import 'package:flutter/material.dart';

class ZoomImageScreen extends StatelessWidget {
  final String imageUrl;

  const ZoomImageScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Image Preview'),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
          maxScale: 5.0,
          minScale: 1.0,
        ),
      ),
    );
  }
}
