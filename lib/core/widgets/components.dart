
import 'package:flutter/material.dart';

Padding nameField(){
  return Padding(
    padding: const EdgeInsets.fromLTRB(0, 10, 0, 30),
    child: TextField(
      decoration: InputDecoration(
        hintText: 'Anonymous',
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
      ),
    ),
  );
}