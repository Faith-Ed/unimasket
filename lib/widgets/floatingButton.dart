import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../page/chatBot.dart';

class CustomFloatingActionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Chat with Bot',
      child: FloatingActionButton(
        onPressed: () {
          // Open Chatbot
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ChatBot()), // Navigate to ChatBot screen
          );
        },
        child: Icon(Icons.flutter_dash, color: Colors.black),
        backgroundColor: CupertinoColors.systemYellow,
      ),
    );
  }
}
