import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pillow/screens/journal.dart';
import 'package:pillow/screens/pillbox.dart';

import '../../screens/new_treatment.dart';
import '../../screens/profile.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  routerNeglect: true,
  navigatorKey: navigatorKey,
  routes: routes,
);

final List<GoRoute> routes = [
  GoRoute(
      path: '/',
      builder: (context, state) => JournalScreen()/*SplashScreen()*/
  ),
  GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen()
  ),
  GoRoute(
      path: '/pillbox',
      builder: (context, state) => PillboxScreen()
  ),
  GoRoute(
      path: '/journal',
      builder: (context, state) => JournalScreen()
  ),
  GoRoute(
    path: '/new_treatment',
    builder: (context, state) => NewTreatmentScreen()
  ),
];