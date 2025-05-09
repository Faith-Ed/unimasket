import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

// A reusable function to create a customized AppBar
PreferredSizeWidget customAppBar(String title) {
  return PreferredSize(
    preferredSize: Size.fromHeight(80), // Set the height of the AppBar
    child: ClipRRect(
      borderRadius: BorderRadius.only(
        bottomLeft: Radius.circular(10), // Set left bottom corner radius
        bottomRight: Radius.circular(10), // Set right bottom corner radius
      ),
      child: AppBar(
        toolbarHeight: 80, // Toolbar height
        backgroundColor: CupertinoColors.systemYellow, // AppBar background color
        title: Text(title, style: TextStyle(color: Colors.white)),
      ),
    ),
  );
}
