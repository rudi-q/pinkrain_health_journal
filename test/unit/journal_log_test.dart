import 'package:flutter_test/flutter_test.dart';
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
    // Note: Using print is acceptable in test files for debugging purposes
    // These prints help verify the test data is correct
    print('Medicine name: ${logs[0].treatment.medicine.name}');
    print('Is taken initially: ${logs[0].isTaken}');
    firstLog.isTaken = true;
    print('Is taken after update: ${journalLog.getMedicationsForTheDay(date)[0].isTaken}');
  });


});
}