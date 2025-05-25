import 'package:flutter/material.dart';
import 'package:redofyp/chat/messaging.dart';
import 'package:redofyp/backupCode/shamry.dart';
import '../page/main/home.dart';
import '../page/main/me_menu.dart';
import '../page/notification/notification.dart'; // Your Home screen import


class BottomNavigationBarWidget extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int unreadCount;  // Add this new parameter

  BottomNavigationBarWidget({
    required this.currentIndex,
    required this.onTap,
    this.unreadCount = 0,  // Default to 0 if not provided
  });

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
          icon: Stack(
            children: [
              Icon(Icons.chat),
              if (unreadCount > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
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
