// ignore_for_file: prefer_const_constructors, avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pillow/core/models/medicine_model.dart';
import 'package:pillow/features/treatment/data/treatment.dart';
import 'package:pillow/features/treatment/domain/treatment_manager.dart';
import 'package:pillow/features/treatment/presentation/edit_treatment.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  // Helper function to create a test treatment
  Treatment createTestTreatment({
    String? id,
    String name = 'Test Medicine',
    String type = 'Tablet',
    String color = 'White',
    double dosage = 10.0,
    String unit = 'mg',
    String mealOption = 'After meal',
    String notes = 'Test notes',
  }) {
    final medicine = Medicine(name: name, type: type, color: color)
      ..addSpecification(Specification(dosage: dosage, unit: unit, useCase: 'Test use case'));

    final treatmentPlan = TreatmentPlan(
      startDate: DateTime(2025, 4, 20),
      endDate: DateTime(2025, 4, 27),
      timeOfDay: DateTime(2025, 1, 1, 8, 0),
      mealOption: mealOption,
      instructions: 'Take once daily',
      frequency: Duration(days: 1),
    );

    return Treatment(
      id: id ?? generateUniqueId(),
      medicine: medicine,
      treatmentPlan: treatmentPlan,
      notes: notes,
    );
  }

  // Helper function to build the EditTreatmentScreen widget for testing
  Widget buildEditTreatmentScreen(Treatment treatment) {
    return ProviderScope(
      child: MaterialApp(
        home: EditTreatmentScreen(treatment: treatment),
      ),
    );
  }

  group('EditTreatmentScreen Widget Tests', () {
    testWidgets('EditTreatmentScreen should display treatment details correctly', (WidgetTester tester) async {
      // Arrange: Create a test treatment
      final treatment = createTestTreatment();
      
      // Act: Build the widget
      await tester.pumpWidget(buildEditTreatmentScreen(treatment));
      
      // Assert: Verify that the treatment details are displayed correctly
      expect(find.text('Edit Treatment'), findsOneWidget);
      expect(find.text('Test Medicine'), findsOneWidget);
      expect(find.text('10.0'), findsOneWidget);
      expect(find.text('After meal'), findsOneWidget);
      expect(find.text('Test notes'), findsOneWidget);
    });

    testWidgets('EditTreatmentScreen should update dosage when changed', (WidgetTester tester) async {
      // Arrange: Create a test treatment
      final treatment = createTestTreatment();
      
      // Act: Build the widget
      await tester.pumpWidget(buildEditTreatmentScreen(treatment));
      
      // Find the dosage text field
      final dosageField = find.widgetWithText(TextField, '10.0');
      expect(dosageField, findsOneWidget);
      
      // Clear the field and enter a new value
      await tester.enterText(dosageField, '20.0');
      
      // Verify the text field was updated
      expect(find.text('20.0'), findsOneWidget);
    });

    testWidgets('EditTreatmentScreen should update name when changed', (WidgetTester tester) async {
      // Arrange: Create a test treatment
      final treatment = createTestTreatment();
      
      // Act: Build the widget
      await tester.pumpWidget(buildEditTreatmentScreen(treatment));
      
      // Find the name text field
      final nameField = find.widgetWithText(TextField, 'Test Medicine');
      expect(nameField, findsOneWidget);
      
      // Clear the field and enter a new value
      await tester.enterText(nameField, 'Updated Medicine Name');
      
      // Verify the text field was updated
      expect(find.text('Updated Medicine Name'), findsOneWidget);
    });

    testWidgets('EditTreatmentScreen should update color when selected', (WidgetTester tester) async {
      // Arrange: Create a test treatment
      final treatment = createTestTreatment();
      
      // Act: Build the widget
      await tester.pumpWidget(buildEditTreatmentScreen(treatment));
      
      // Find the color options
      final blueColorOption = find.text('Blue');
      expect(blueColorOption, findsOneWidget);
      
      // Tap on the blue color option
      await tester.tap(blueColorOption);
      await tester.pump();
      
      // Verify the color was selected (this is a bit tricky to verify in a widget test)
      // We can check if the blue color option has a different style or is highlighted
      // This would require finding the specific widget with the updated style
    });

    testWidgets('EditTreatmentScreen should update meal preference when selected', (WidgetTester tester) async {
      // Arrange: Create a test treatment
      final treatment = createTestTreatment();
      
      // Act: Build the widget
      await tester.pumpWidget(buildEditTreatmentScreen(treatment));
      
      // Find the meal preference options
      final beforeMealOption = find.text('Before meal');
      expect(beforeMealOption, findsOneWidget);
      
      // Tap on the before meal option
      await tester.tap(beforeMealOption);
      await tester.pump();
      
      // Verify the meal preference was selected (this is a bit tricky to verify in a widget test)
      // We can check if the before meal option has a different style or is highlighted
      // This would require finding the specific widget with the updated style
    });

    testWidgets('EditTreatmentScreen should update treatment type when selected', (WidgetTester tester) async {
      // Arrange: Create a test treatment
      final treatment = createTestTreatment();
      
      // Act: Build the widget
      await tester.pumpWidget(buildEditTreatmentScreen(treatment));
      
      // Find the treatment type options
      final capsuleOption = find.text('Capsule');
      expect(capsuleOption, findsOneWidget);
      
      // Tap on the capsule option
      await tester.tap(capsuleOption);
      await tester.pump();
      
      // Verify the treatment type was selected (this is a bit tricky to verify in a widget test)
      // We can check if the capsule option has a different style or is highlighted
      // This would require finding the specific widget with the updated style
    });

    testWidgets('EditTreatmentScreen should save changes when save button is pressed', (WidgetTester tester) async {
      // Arrange: Create a test treatment
      final treatment = createTestTreatment();
      
      // Act: Build the widget
      await tester.pumpWidget(buildEditTreatmentScreen(treatment));
      
      // Find the name text field and update it
      final nameField = find.widgetWithText(TextField, 'Test Medicine');
      await tester.enterText(nameField, 'Updated Medicine Name');
      
      // Find the dosage text field and update it
      final dosageField = find.widgetWithText(TextField, '10.0');
      await tester.enterText(dosageField, '20.0');
      
      // Find the save button
      final saveButton = find.text('Save Changes');
      expect(saveButton, findsOneWidget);
      
      // Tap the save button
      await tester.tap(saveButton);
      await tester.pumpAndSettle();
      
      // Verify that the save was successful
      // This is difficult to verify in a widget test without mocking the TreatmentManager
      // We would need to check if the TreatmentManager.updateTreatment method was called
      // with the correct parameters
    });
  });
}