import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/treatment.dart';

class TreatmentManager {
  List<Treatment> _treatments = [];

  List<Treatment> get treatments => _treatments;

  Future<void> loadTreatments() async {
    final prefs = await SharedPreferences.getInstance();
    final String? treatmentsJson = prefs.getString('treatments');
    if (treatmentsJson != null) {
      final List<dynamic> decodedList = json.decode(treatmentsJson);
      _treatments = decodedList.map((item) => Treatment.fromJson(item)).toList();
    }
  }

  Future<void> saveTreatments() async {
    final prefs = await SharedPreferences.getInstance();
    final String encodedList = json.encode(_treatments.map((t) => t.toJson()).toList());
    await prefs.setString('treatments', encodedList);
  }

  Future<void> addTreatment(Treatment treatment) async {
    _treatments.add(treatment);
    await saveTreatments();
  }
}