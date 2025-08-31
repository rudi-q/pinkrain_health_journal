import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pinkrain/core/models/medicine_model.dart';
import 'package:pinkrain/features/pillbox/data/pillbox_model.dart';
import 'package:pinkrain/features/pillbox/presentation/pillbox_notifier.dart';
import 'package:pinkrain/features/pillbox/presentation/pillbox_screen.dart';

// Create a testable version of PillBox
class TestPillBox implements PillBox {
  @override
  List<MedicineInventory> pillStock = [
    MedicineInventory(
      medicine: _createMockMedicine('Paracetamol', 'Tablet'),
      quantity: 30,
    ),
    MedicineInventory(
      medicine: _createMockMedicine('Levocetirizine', 'Tablet'),
      quantity: 15,
    ),
  ];

  @override
  void addMedicineInventory(MedicineInventory medicine) {
    pillStock.add(medicine);
  }

  @override
  void addMed(Medicine medicine, int? quantity) {
    pillStock
        .add(MedicineInventory(medicine: medicine, quantity: quantity ?? 0));
  }

  @override
  void removeMed(Medicine medicine) {
    pillStock.removeWhere((item) => item.medicine.name == medicine.name);
  }
}

// Helper to create mock medicines for testing
Medicine _createMockMedicine(String name, String type) {
  final medicine = Medicine(name: name, type: type, color: 'White');
  medicine.addSpecification(Specification(dosage: 20, unit: 'mg'));
  return medicine;
}

void main() {
  testWidgets('PillboxScreen renders correctly', (WidgetTester tester) async {
    // Create the test pill box
    final testPillBox = TestPillBox();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the provider with a fixed value provider
          pillBoxProvider.overrideWith(
              (ref) => PillBoxNotifier()..updatePillbox(testPillBox.pillStock)),
        ],
        child: const MaterialApp(
          home: PillboxScreen(),
        ),
      ),
    );

    // Verify basic UI elements
    expect(find.text('Pill Box'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget); // Search field
    expect(find.byType(GridView), findsOneWidget);

    // Verify medicine cards render correctly
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.text('Levocetirizine'), findsOneWidget);
    expect(find.text('30 pills left'), findsOneWidget);
    expect(find.text('15 pills left'), findsOneWidget);
  });

  testWidgets('PillboxScreen navigation works correctly',
      (WidgetTester tester) async {
    // Create the test pill box
    final testPillBox = TestPillBox();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the provider with a fixed value provider
          pillBoxProvider.overrideWith(
              (ref) => PillBoxNotifier()..updatePillbox(testPillBox.pillStock)),
        ],
        child: const MaterialApp(
          home: PillboxScreen(),
        ),
      ),
    );

    // Find and tap on the first medicine card
    final firstCard = find.text('Paracetamol').first;
    await tester.tap(firstCard);
    await tester.pumpAndSettle(); // Wait for navigation animation

    // Verify we navigated to the medicine detail screen
    expect(find.text('Paracetamol'), findsOneWidget);
    expect(find.text('Treatment Plan'), findsOneWidget);
    expect(find.text('Pill Information'), findsOneWidget);
  });

  testWidgets('Add medicine dialog appears on FAB tap',
      (WidgetTester tester) async {
    // Create the test pill box
    final testPillBox = TestPillBox();

    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Override the provider with a fixed value provider
          pillBoxProvider.overrideWith(
              (ref) => PillBoxNotifier()..updatePillbox(testPillBox.pillStock)),
        ],
        child: const MaterialApp(
          home: PillboxScreen(),
        ),
      ),
    );

    // Find and tap on the FAB
    final fab = find.byType(FloatingActionButton);
    await tester.tap(fab);
    await tester.pumpAndSettle(); // Wait for dialog animation

    // Verify the add medication dialog appears
    expect(find.text('Add New Medication'), findsOneWidget);
    expect(find.byType(TextField),
        findsAtLeastNWidgets(4)); // Name, Quantity, Unit, Use Case fields
  });
}
