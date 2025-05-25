
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppButtons {

  /// This is for small buttons for quick actions
  static CupertinoButton secondary({
    /// Pass over the function that needs to be executed when pressed on
    required Function() onPressed,
    /// Pass over the text you would like for the button to paint
    required String text,
    /// Optionally, pass over the size, it defaults to 16
    double size = 16
  }) {
    return CupertinoButton(
        padding: EdgeInsets.zero,
        child: Text(
          text,
          style: TextStyle(
            color: Colors.pink[100],
            fontSize: size,
          ),
        ),
        onPressed: () => onPressed
    );
  }
  
}
