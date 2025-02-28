import 'package:flutter_test/flutter_test.dart';
import 'package:pillow/core/util/helpers.dart';
import 'package:pillow/features/journal/data/journal_log.dart';

void main(){
  group('Journal Log Tests', (){
  late JournalLog journalLog;
  late DateTime date;
  late List<IntakeLog> logs;
  late IntakeLog firstLog;

  setUp(() {
    journalLog = JournalLog();
    date = DateTime.now();

    logs = journalLog.getMedicationsForTheDay(date);
    firstLog = logs[0];
  });

  test('Check Log Length', (){
    expect(logs.length, greaterThan(0));
  });

  test('Check Log Details', (){
    print(logs[0].treatment.medicine.name);
    print(logs[0].isTaken);
    firstLog.isTaken = true;
    print(journalLog.getMedicationsForTheDay(date)[0].isTaken);
  });


});
}