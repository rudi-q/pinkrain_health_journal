import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pillow/features/journal/presentation/journal.dart';
import 'package:pillow/features/pillbox/presentation/pillbox_screen.dart';

import '../../features/profile/presentation/profile.dart';
import '../../features/treatment/presentation/duration.dart';
import '../../features/treatment/presentation/new_treatment.dart';
import '../../features/treatment/presentation/schedule.dart';



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
  GoRoute(
      path: '/schedule',
      builder: (context, state) => ScheduleScreen()
  ),
  GoRoute(
    path: '/duration',
    builder: (context, state) => DurationScreen(),
  ),
];


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  routerNeglect: true,
  navigatorKey: navigatorKey,
  routes: routes,
);