import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// A simplified version of WellnessTrackerScreen for testing
class TestWellnessScreen extends StatefulWidget {
  final DateTime initialDate;
  
  const TestWellnessScreen({
    Key? key,
    required this.initialDate,
  }) : super(key: key);
  
  @override
  State<TestWellnessScreen> createState() => _TestWellnessScreenState();
}

class _TestWellnessScreenState extends State<TestWellnessScreen> {
  late DateTime selectedDate;
  String selectedDateOption = 'day';
  
  @override
  void initState() {
    super.initState();
    selectedDate = widget.initialDate;
  }
  
  void _navigateToPrevious() {
    setState(() {
      switch (selectedDateOption) {
        case 'day':
          selectedDate = selectedDate.subtract(const Duration(days: 1));
          break;
        case 'month':
          selectedDate = DateTime(
            selectedDate.year,
            selectedDate.month - 1,
            selectedDate.day,
          );
          break;
        case 'year':
          selectedDate = DateTime(
            selectedDate.year - 1,
            selectedDate.month,
            selectedDate.day,
          );
          break;
      }
    });
  }
  
  void _navigateToNext() {
    final now = DateTime.now();
    final nextDate = switch (selectedDateOption) {
      'day' => selectedDate.add(const Duration(days: 1)),
      'month' => DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          selectedDate.day,
        ),
      'year' => DateTime(
          selectedDate.year + 1,
          selectedDate.month,
          selectedDate.day,
        ),
      _ => selectedDate,
    };
    
    // Only allow navigation up to the current date
    if (!nextDate.isAfter(now)) {
      setState(() {
        selectedDate = nextDate;
      });
    }
  }
  
  void _navigateToToday() {
    setState(() {
      selectedDate = DateTime.now();
    });
  }
  
  bool _canNavigateNext() {
    final now = DateTime.now();
    final nextDate = switch (selectedDateOption) {
      'day' => selectedDate.add(const Duration(days: 1)),
      'month' => DateTime(
          selectedDate.year,
          selectedDate.month + 1,
          selectedDate.day,
        ),
      'year' => DateTime(
          selectedDate.year + 1,
          selectedDate.month,
          selectedDate.day,
        ),
      _ => selectedDate,
    };
    
    return !nextDate.isAfter(now);
  }
  
  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('MMMM yyyy').format(selectedDate);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Wellness Tracker'),
      ),
      body: Column(
        children: [
          // Date navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _navigateToPrevious,
              ),
              TextButton(
                onPressed: _navigateToToday,
                child: const Text('Today'),
              ),
              Text(
                formattedDate,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _canNavigateNext() ? _navigateToNext : null,
                key: const Key('nextButton'),
              ),
            ],
          ),
          // Display current date
          Text('Selected date: ${DateFormat('dd/MM/yyyy').format(selectedDate)}'),
          // Display whether navigation is possible
          Text('Can navigate next: ${_canNavigateNext()}'),
        ],
      ),
    );
  }
}
