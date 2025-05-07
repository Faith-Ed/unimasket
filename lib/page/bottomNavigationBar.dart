import 'package:flutter/material.dart';
import 'package:redofyp/page/messaging.dart';
import 'package:redofyp/backupCode/shamry.dart';
import 'home.dart';
import 'me_menu.dart';
import 'notification.dart'; // Your Home screen import


class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  BottomNavigationBarWidget({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (index) {
        switch (index) {
          case 0: // Home
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomeScreen()),
                  (Route<dynamic> route) => false,
            );
            break;
          case 1: // Chats
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MessagingScreen()), // Replace with your actual Chats screen
                  (Route<dynamic> route) => false,
            );
            break;
          case 2: // Notifications
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => NotificationScreen()), // Replace with your actual Notifications screen
                  (Route<dynamic> route) => false,
            );
            break;
          case 3: // Me
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => MeMenuScreen()), // Replace with your actual Me screen
                  (Route<dynamic> route) => false,
            );
            break;
          default:
            break;
        }
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
          backgroundColor: Colors.blue,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.chat),
          label: 'Chats',
          backgroundColor: Colors.blue,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.notifications),
          label: 'Notifications',
          backgroundColor: Colors.blue,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Me',
          backgroundColor: Colors.blue,
        ),
      ],
      selectedItemColor: Colors.yellow,
      unselectedItemColor: Colors.white,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      iconSize: 30.0,
      backgroundColor: Colors.blue,
    );
  }
}
