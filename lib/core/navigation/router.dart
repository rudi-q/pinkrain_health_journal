import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pillow/features/journal/presentation/journal_screen.dart';
import 'package:pillow/features/journal/presentation/journal_screen_wrapper.dart';
import 'package:pillow/features/pillbox/presentation/pillbox_screen.dart';
import 'package:pillow/features/splash/splash_screen.dart'; 
import 'package:pillow/features/wellness/presentation/wellness_screen.dart';

import '../../features/pillbox/presentation/medicine_detail_screen.dart';
import '../../features/profile/presentation/profile.dart';
import '../../features/treatment/presentation/duration.dart';
import '../../features/treatment/presentation/new_treatment.dart';
import '../../features/treatment/presentation/schedule.dart';
import '../models/medicine_model.dart';



final List<GoRoute> routes = [
  GoRoute(
      path: '/',
      builder: (context, state) => SplashScreen() 
  ),
  GoRoute(
      path: '/journal',
      builder: (context, state) => JournalScreenWrapper()
  ),
  GoRoute(
      path: '/pillbox',
      builder: (context, state) => PillboxScreen()
  ),

  GoRoute(
      path: '/wellness',
      builder: (context, state) => WellnessTrackerScreen()
  ),
  GoRoute(
      path: '/profile',
      builder: (context, state) => ProfileScreen()
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
  GoRoute(
    path: '/medicine_detail/:id',
    builder: (context, state) {/*
      final medicine = state.extra as Medicine;
      final pillsLeft = int.parse(state.pathParameters['id']!);*/
      return MedicineDetailScreen(inventory: state.extra as MedicineInventory);
    },
  ),
];


final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  routerNeglect: true,
  navigatorKey: navigatorKey,
  routes: routes,
);