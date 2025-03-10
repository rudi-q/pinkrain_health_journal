import 'package:pillow/core/util/helpers.dart';

class MoodTracker{
  static List<Map<DateTime, int>> moodLog = [];

  static int getMood(DateTime date) {
    date = date.normalize();
    int mood = 0;
    for (int i = 0; i < moodLog.length; i++) {
      if (moodLog[i].containsKey(date) && moodLog[i][date]!= null) {
        mood = moodLog[i][date] ?? mood;
      }
    }
    return mood;
  }

  static void addMood(DateTime date, int mood) {
    date = date.normalize();
    final Map<DateTime, int> log = {date:mood};
    moodLog.add(log);
    'Added mood for $date with value $mood -- ${moodLog.last[date]}.'.log();
  }

  static int getMoodCountByRange(DateTime startDate, DateTime endDate, int mood) {
    int count = 0;
    for (DateTime date = startDate; date.isBefore(endDate); date = date.add(Duration(days: 1))) {
      if (getMood(date) == mood) count++;
    }
    return count;
  }

  static void populateSample(){
    if(MoodTracker.moodLog.isNotEmpty) {return;}
    MoodTracker.addMood(DateTime.now().subtract(Duration(days: 2)), 4);
    MoodTracker.addMood(DateTime.now().subtract(Duration(days: 1)), 4);
    MoodTracker.addMood(DateTime.now(), 4);
    MoodTracker.addMood(DateTime.now().add(Duration(days: 1)), 3);
    MoodTracker.addMood(DateTime.now().add(Duration(days: 2)), 5);
  }
}