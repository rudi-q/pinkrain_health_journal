import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfService {

  /// Generate a wellness report PDF for the specified date range
  static Future<File> generateWellnessReport(
      DateTime date, String timeRange) async {
    final pdf = pw.Document();

    // Load font
    final font = await rootBundle.load("assets/fonts/Outfit-Regular.ttf");
    final ttf = pw.Font.ttf(font);

    // Prepare data
    final moodData = await _getMoodData(date, timeRange);
    final medicationData = await _getMedicationData(date, timeRange);
    final symptomData = await _getSymptomData(date, timeRange);

    // Generate PDF content
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          _buildHeader(date, timeRange, ttf),
          _buildMoodSection(moodData, ttf),
          _buildMedicationSection(medicationData, ttf),
          _buildSymptomSection(symptomData, ttf),
        ],
      ),
    );

    // Save to temporary file
    final output = await _getTemporaryFile();
    await output.writeAsBytes(await pdf.save());
    return output;
  }

  /// Build the header section of the report
  static pw.Widget _buildHeader(DateTime date, String timeRange, pw.Font ttf) {
    final title = switch (timeRange) {
      'day' => DateFormat('MMMM d, y').format(date),
      'month' => DateFormat('MMMM y').format(date),
      'year' => DateFormat('y').format(date),
      _ => DateFormat('MMMM d, y').format(date),
    };

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          '$title Wellness Report',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Text(
          'Track your journey and nurture your whole self - mind and body together.',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 12,
            color: PdfColors.grey700,
          ),
          textAlign: pw.TextAlign.center,
        ),
        pw.SizedBox(height: 20),
        pw.Divider(),
      ],
    );
  }

  /// Build the mood tracking section
  static pw.Widget _buildMoodSection(
      List<Map<String, dynamic>> moodData, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Mood Tracking',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        // TODO: Add mood visualization
        pw.Container(
          height: 200,
          child: pw.Center(
            child: pw.Text(
              'Mood trend visualization will be added here',
              style: pw.TextStyle(font: ttf, color: PdfColors.grey),
            ),
          ),
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  /// Build the medication adherence section
  static pw.Widget _buildMedicationSection(
      Map<String, dynamic> medicationData, pw.Font ttf) {
    final adherenceRate = medicationData['adherenceRate'] as double? ?? 0.0;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Medication Adherence',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        pw.Row(
          children: [
            pw.Container(
              width: 60,
              height: 60,
              child: pw.Stack(
                children: [
                  pw.Center(
                    child: pw.Text(
                      '${(adherenceRate * 100).round()}%',
                      style: pw.TextStyle(
                        font: ttf,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            pw.SizedBox(width: 20),
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Overall Adherence',
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Text(
                    _getAdherenceMessage(adherenceRate),
                    style: pw.TextStyle(
                      font: ttf,
                      fontSize: 12,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }

  /// Build the symptom tracking section
  static pw.Widget _buildSymptomSection(
      List<Map<String, dynamic>> symptomData, pw.Font ttf) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Symptom Tracking',
          style: pw.TextStyle(
            font: ttf,
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 10),
        ...symptomData.map((symptom) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 10),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Text(
                      symptom['name'] as String,
                      style: pw.TextStyle(font: ttf),
                    ),
                  ),
                  pw.Text(
                    '${((symptom['frequency'] as double) * 100).round()}%',
                    style: pw.TextStyle(
                      font: ttf,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )),
        pw.SizedBox(height: 20),
      ],
    );
  }

  /// Get mood data for the specified date range
  static Future<List<Map<String, dynamic>>> _getMoodData(
      DateTime date, String timeRange) async {
    // TODO: Implement mood data retrieval from HiveService
    return [];
  }

  /// Get medication data for the specified date range
  static Future<Map<String, dynamic>> _getMedicationData(
      DateTime date, String timeRange) async {
    // TODO: Implement medication data retrieval from HiveService
    return {'adherenceRate': 0.85};
  }

  /// Get symptom data for the specified date range
  static Future<List<Map<String, dynamic>>> _getSymptomData(
      DateTime date, String timeRange) async {
    // TODO: Implement symptom data retrieval from HiveService
    return [];
  }

  /// Get a temporary file for the PDF
  static Future<File> _getTemporaryFile() async {
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return File('${directory.path}/wellness_report_$timestamp.pdf');
  }

  /// Get an appropriate message based on adherence rate
  static String _getAdherenceMessage(double rate) {
    if (rate >= 0.9) return 'Excellent adherence! Keep up the great work!';
    if (rate >= 0.8) return 'Good adherence. Room for small improvements.';
    if (rate >= 0.6) return 'Moderate adherence. Try to be more consistent.';
    return 'Adherence needs improvement. Set reminders to help.';
  }
}
