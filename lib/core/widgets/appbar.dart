import 'package:flutter/material.dart';

AppBar buildAppBar(String title, {List<Widget>? actions}){
  return AppBar(
    title: Text(
      title,
      style: TextStyle(
        color: Colors.black,
        fontSize: 22,
        fontWeight: FontWeight.bold,
      ),
    ),
    backgroundColor: Colors.transparent,
    elevation: 0,
    automaticallyImplyLeading: false,
    actions: actions,
  );
}