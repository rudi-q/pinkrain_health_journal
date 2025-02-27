import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pillow/features/pillbox/presentation/pillbox_notifier.dart';

import '../../../core/models/medicine_model.dart';

abstract class IPillBox {
  List<MedicineInventory> pillStock = [];
}

class PillBox implements IPillBox {
  @override
  List<MedicineInventory> pillStock = [];

  PillBox();

  PillBox.populate(this.pillStock);

  void addMedicineInventory(MedicineInventory medicine) {
    pillStock.add(medicine);
  }

  void addMed(Medicine medicine, int? quantity) {
    pillStock.add(MedicineInventory(medicine: medicine, quantity: quantity ?? 0));
  }

}

class PillBoxManager{

  static final pillbox = PillBox();
  static late PillBoxNotifier pillBoxNotifier;

  static init(WidgetRef ref) {
    pillBoxNotifier = ref.read(pillBoxProvider.notifier);
  }

  static IPillBox getSample() {

    final med1 = Medicine(
      name: 'Paracetamol',
      type: 'ADHD medication',
      color: 'White',
    );

    med1.addSpecification(Specification(dosage: 20, unit: 'mg'));

    final med2 = Medicine(
      name: 'Levocetirizine',
      type: 'Antihistamine',
      color: 'White',
    );


    med2.addSpecification(Specification(dosage: 20, unit: 'mg'));

    final med3 = Medicine(
      name: 'Valdoxan',
      type: 'Depression, GAD',
      color: 'White',
    );


    med3.addSpecification(Specification(dosage: 20, unit: 'mg'));

    pillbox.addMed(med1, 180);
    pillbox.addMed(med2, 63);
    pillbox.addMed(med3, 42);

    return pillbox;
  }

  static void addMedicine({required Medicine medicine, int? quantity}) {
    pillbox.addMed(medicine, quantity);
    pillBoxNotifier.updatePillbox(pillbox.pillStock);
    }

}
