import 'dart:convert';

import 'package:dialog_flowtter/dialog_flowtter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:googleapis_auth/auth_io.dart';
import 'package:googleapis_auth/googleapis_auth.dart';

import '../widgets/pageDesign.dart';


class ChatBot extends StatefulWidget {
  const ChatBot({Key? key}) : super(key: key);

  @override
  _ChatBotState createState() => _ChatBotState();
}

class _ChatBotState extends State<ChatBot> {
  late DialogFlowtter dialogFlowtter;
  final TextEditingController _controller = TextEditingController();
  List<Map<String, dynamic>> messages = [];
  List<String> faqTopics = ["What is UniMASket?", "UniMASket Features", "UniMASket Services"];
  bool isFAQVisible = true;

  @override
  void initState() {
    super.initState();
    _initializeDialogFlowtter();
  }

  // Initialize DialogFlowtter using the JSON credentials file from assets
  _initializeDialogFlowtter() async {
    try {
      // Load the credentials manually from the assets folder
      final credentials = await _loadCredentials();
      final authClient = await _getAuthClient(credentials);
      dialogFlowtter = DialogFlowtter();
    } catch (error) {
      print('Error initializing DialogFlowtter: $error');
    }
  }

  // Load the credentials JSON file from the assets folder
  Future<Map<String, dynamic>> _loadCredentials() async {
    String jsonString = await rootBundle.loadString('assets/dialog_flow_auth.json');
    return Map<String, dynamic>.from(json.decode(jsonString));
  }

  // Authenticate and return an authenticated client
  Future<AuthClient> _getAuthClient(Map<String, dynamic> credentials) async {
    final credentialsJson = jsonEncode(credentials);  // Ensure it's a JSON string
    final authClient = await clientViaServiceAccount(
        ServiceAccountCredentials.fromJson(credentialsJson),
        ['https://www.googleapis.com/auth/dialogflow']  // Required scope for Dialogflow
    );

    return authClient;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.yellow.shade50,
      appBar: customAppBar('Chatbot'),
      body: Column(
        children: [
          // If FAQ is visible, show the prompt and FAQ topics
          if (isFAQVisible)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'What can I help you?',
                    style: TextStyle(fontSize: 24, color: Colors.black),
                  ),
                  SizedBox(height: 20),
                  // FAQ Topic buttons inside a Wrap widget to avoid overflow
                  Wrap(
                    spacing: 10,  // Horizontal spacing between buttons
                    runSpacing: 10,  // Vertical spacing between buttons
                    alignment: WrapAlignment.center,
                    children: faqTopics.map((topic) {
                      return ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                        onPressed: () {
                          // Hide FAQ and prompt, and send the selected topic to chatbot
                          setState(() {
                            isFAQVisible = false;  // Hide FAQ topics and prompt
                          });
                          sendMessage(topic);  // Send the FAQ topic as a message to Dialogflow
                        },
                        child: Text(topic),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

          // Display the list of messages (user and bot)
          Expanded(
            child: MessagesScreen(messages: messages),
          ),

          // Input field for typing messages, always visible
          Container(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            color: Colors.deepPurple,
            child: Row(
              children: [
                Expanded(
                    child: TextField(
                      controller: _controller,
                      style: TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(color: Colors.white60),
                      ),
                    )),
                IconButton(
                    onPressed: () {
                      // Hide the FAQ section once user clicks send or types a message
                      if (isFAQVisible) {
                        setState(() {
                          isFAQVisible = false;  // Hide FAQ section if it's still visible
                        });
                      }
                      sendMessage(_controller.text);  // Send the message typed by the user
                      _controller.clear();  // Clear the text field after sending the message
                    },
                    icon: Icon(Icons.send, color: Colors.white))
              ],
            ),
          )
        ],
      ),
    );
  }

  // Function to send the message to DialogFlow and get a response
  sendMessage(String text) async {
    if (text.isEmpty) {
      print('Message is empty');
    } else {
      setState(() {
        addMessage(Message(text: DialogText(text: [text])), true);
      });

      DetectIntentResponse response = await dialogFlowtter.detectIntent(
          queryInput: QueryInput(text: TextInput(text: text)));
      if (response.message == null) return;
      setState(() {
        addMessage(response.message!);
      });
    }
  }

  addMessage(Message message, [bool isUserMessage = false]) {
    messages.add({'message': message, 'isUserMessage': isUserMessage});
  }
}

// Widget to display the chat messages (user and bot)
class MessagesScreen extends StatefulWidget {
  final List messages;
  const MessagesScreen({Key? key, required this.messages}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  @override
  Widget build(BuildContext context) {
    var w = MediaQuery.of(context).size.width;
    return ListView.separated(
      itemBuilder: (context, index) {
        return Container(
          margin: EdgeInsets.all(10),
          child: Row(
            mainAxisAlignment: widget.messages[index]['isUserMessage']
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            children: [
              if (!widget.messages[index]['isUserMessage'])
                Icon(
                  Icons.flutter_dash_sharp, // Icon to represent the chatbot
                  color: Colors.lightGreenAccent,
                  size: 30,
                ),
              SizedBox(width: 10),  // Space between icon and text
              Container(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomRight: Radius.circular(
                        widget.messages[index]['isUserMessage'] ? 0 : 20),
                    topLeft: Radius.circular(
                        widget.messages[index]['isUserMessage'] ? 20 : 0),
                  ),
                  color: widget.messages[index]['isUserMessage']
                      ? Colors.blue
                      : Colors.grey.shade200,
                ),
                constraints: BoxConstraints(maxWidth: w * 2 / 3),
                child: Text(
                  widget.messages[index]['message'].text.text[0],
                  style: TextStyle(color: widget.messages[index]['isUserMessage']
                      ? Colors.white
                      : Colors.black),  // White for user, black for chatbot response
                ),
              ),
            ],
          ),
        );
      },
      separatorBuilder: (_, i) => Padding(padding: EdgeInsets.only(top: 10)),
      itemCount: widget.messages.length,
    );
  }
}
