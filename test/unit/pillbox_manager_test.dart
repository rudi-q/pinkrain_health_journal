import 'package:flutter_test/flutter_test.dart';
import 'package:pillow/core/models/medicine_model.dart';
import 'package:pillow/features/pillbox/data/pillbox_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillow/features/pillbox/presentation/pillbox_notifier.dart';

void main() {
  group('PillBoxManager Tests', () {
    late ProviderContainer container;
    
    setUp(() {
      container = ProviderContainer();
      PillBoxManager.pillBoxNotifier = container.read(pillBoxProvider.notifier);
    });
    
    test('addMedicine adds a medicine to the pillbox', () {
      // Arrange
      final medicine = Medicine(
        name: 'Test Medicine',
        type: 'Tablet',
        color: 'White',
      );
      medicine.addSpecification(Specification(dosage: 20, unit: 'mg'));
      
      // Get initial count
      final initialCount = PillBoxManager.pillbox.pillStock.length;
      
      // Act
      PillBoxManager.addMedicine(medicine: medicine, quantity: 10);
      
      // Assert
      expect(PillBoxManager.pillbox.pillStock.length, initialCount + 1);
      
      // Find the added medicine
      final addedMedicine = PillBoxManager.pillbox.pillStock.firstWhere(
        (item) => item.medicine.name == 'Test Medicine',
        orElse: () => MedicineInventory(medicine: medicine, quantity: 0),
      );
      
      expect(addedMedicine.medicine.name, 'Test Medicine');
      expect(addedMedicine.quantity, 10);
    });
    
    test('removeMedicine removes a medicine from the pillbox', () {
      // Arrange
      final medicine = Medicine(
        name: 'Test Medicine To Remove',
        type: 'Tablet',
        color: 'White',
      );
      medicine.addSpecification(Specification(dosage: 20, unit: 'mg'));
      
      // Add the medicine first
      PillBoxManager.addMedicine(medicine: medicine, quantity: 10);
      
      // Get count after adding
      final countAfterAdd = PillBoxManager.pillbox.pillStock.length;
      
      // Act
      PillBoxManager.removeMedicine(medicine: medicine);
      
      // Assert
      expect(PillBoxManager.pillbox.pillStock.length, countAfterAdd - 1);
      
      // Verify the medicine is no longer in the pillbox
      final found = PillBoxManager.pillbox.pillStock.any(
        (item) => item.medicine.name == 'Test Medicine To Remove'
      );
      
      expect(found, false);
    });
  });
}