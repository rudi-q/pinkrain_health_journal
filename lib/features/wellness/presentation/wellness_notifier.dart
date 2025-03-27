import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillow/core/util/helpers.dart';


class WellnessScreenNotifier extends StateNotifier<DateTime> {
  WellnessScreenNotifier() : super(DateTime.now());

  String checkInMessage (String selectedDateOption){
    final checkInMessage = 'How have you been feeling '
        '${
        (state.isToday() && selectedDateOption == 'day')
        ? 'today'
        : selectedDateOption == 'day'
        ? 'on this day'
        : 'this $selectedDateOption'}';
    return checkInMessage;
  }

  void setDate(DateTime newDate) {
    if (newDate.normalize() != state) {
      state = newDate.normalize();
    }
  }

}

final wellnessScreenProvider = StateNotifierProvider<WellnessScreenNotifier, DateTime>((ref) => WellnessScreenNotifier());