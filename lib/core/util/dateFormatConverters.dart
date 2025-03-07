
String getWeekdayAbbreviation(int weekday) {
  switch (weekday) {
    case DateTime.monday: return 'M';
    case DateTime.tuesday: return 'Tu';
    case DateTime.wednesday: return 'W';
    case DateTime.thursday: return 'Th';
    case DateTime.friday: return 'F';
    case DateTime.saturday: return 'Sa';
    case DateTime.sunday: return 'Su';
    default: return '';
  }
}
String getWeekdayName(int weekday) {
  switch (weekday) {
    case DateTime.monday: return 'Monday';
    case DateTime.tuesday: return 'Tuesday';
    case DateTime.wednesday: return 'Wednesday';
    case DateTime.thursday: return 'Thursday';
    case DateTime.friday: return 'Friday';
    case DateTime.saturday: return 'Saturday';
    case DateTime.sunday: return 'Sunday';
    default: return '';
  }
}
String getMonthName(int month) {
  switch (month) {
    case 1: return 'January';
    case 2: return 'February';
    case 3: return 'March';
    case 4: return 'April';
    case 5: return 'May';
    case 6: return 'June';
    case 7: return 'July';
    case 8: return 'August';
    case 9: return 'September';
    case 10: return 'October';
    case 11: return 'November';
    case 12: return 'December';
    default: return '';
  }
}