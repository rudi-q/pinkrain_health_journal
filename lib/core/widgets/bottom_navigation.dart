import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/icons.dart';
import '../../../core/theme/tokens.dart';



Widget buildBottomNavigationBar({required BuildContext context, required String currentRoute}) {
  return BottomAppBar(
    color: Colors.transparent,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildNavItem(context, 'Journal', 'journal', currentRoute == 'journal'),
        buildNavItem(context, 'Pillbox', 'pillbox', currentRoute == 'pillbox'),
        buildNavItem(context, 'Mindfulness', 'mindfulness',
            currentRoute == 'mindfulness' || currentRoute == 'breath' || currentRoute == 'meditation'),
        buildNavItem(context, 'Wellness', 'wellness', currentRoute == 'wellness'),
      ],
    ),
  );
}

GestureDetector buildNavItem(BuildContext context, String label, String route, bool isSelected) {
  return GestureDetector(
    onTap: () {
      if (!isSelected) {
        context.go('/$route');
      }
    },
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
        decoration: BoxDecoration(
          shape: BoxShape.rectangle,
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppTokens.bgCard : Colors.transparent,
        ),
        padding: EdgeInsets.all(8),
        child: appVectorImage(fileName: route)
        ),

        Text(label),
      ],
    ),
  );
}
