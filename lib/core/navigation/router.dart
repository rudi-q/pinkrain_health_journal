import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pillow/features/journal/presentation/journal_screen_wrapper.dart';

import '../../features/breathing/presentation/breathing_screen.dart';
import '../../features/guided-meditation/guided_audio.dart';
import '../../features/pillbox/presentation/medicine_detail_screen.dart';
import '../../features/pillbox/presentation/pillbox_screen.dart';
import '../../features/profile/presentation/profile.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/treatment/domain/treatment_manager.dart';
import '../../features/treatment/presentation/duration.dart';
import '../../features/treatment/presentation/edit_treatment.dart';
import '../../features/treatment/presentation/new_treatment.dart';
import '../../features/treatment/presentation/schedule.dart';
import '../../features/wellness/presentation/wellness_screen.dart';
import '../models/medicine_model.dart';

final List<GoRoute> routes = [
  GoRoute(path: '/', builder: (context, state) => SplashScreen()),
  GoRoute(path: '/journal', builder: (context, state) => JournalScreenWrapper()),
  GoRoute(path: '/pillbox', builder: (context, state) => PillboxScreen()),
  GoRoute(path: '/breath', builder: (context, state) => BreathBreakScreen()),
  GoRoute(path: '/meditation', builder: (context, state) => GuidedMeditationScreen()),
  GoRoute(
      path: '/wellness', builder: (context, state) => WellnessTrackerScreen()),
  GoRoute(path: '/profile', builder: (context, state) => ProfileScreen()),
  GoRoute(
      path: '/new_treatment',
      builder: (context, state) => NewTreatmentScreen()),
  GoRoute(
      path: '/schedule',
      builder: (context, state) {
        final treatment = state.extra as Treatment;
        return ScheduleScreen(treatment: treatment);
      }),
  GoRoute(
    path: '/duration',
    builder: (context, state) {
      final treatment = state.extra as Treatment;
      return DurationScreen(treatment: treatment);
    },
  ),
  GoRoute(
    path: '/medicine_detail/:id',
    builder: (context, state) => MedicineDetailScreen(
      inventory: state.extra as MedicineInventory,
    ),
  ),
  GoRoute(
      path: '/edit_treatment',
      builder: (context, state) {
        final treatment = state.extra as Treatment;
        return EditTreatmentScreen(treatment: treatment);
      }),
];

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter router = GoRouter(
  routerNeglect: true,
  navigatorKey: navigatorKey,
  routes: routes,
);
