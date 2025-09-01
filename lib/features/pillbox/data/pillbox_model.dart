import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pinkrain/features/pillbox/presentation/pillbox_notifier.dart';

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

  void removeMed(Medicine medicine) {
    pillStock.removeWhere((item) => item.medicine.name == medicine.name);
  }

  // Serialization for Hive persistence
  List<Map<String, dynamic>> toJsonList() => pillStock.map((e) => MedicineInventorySerialization(e).toJson()).toList();
  static PillBox fromJsonList(List<dynamic> data) {
    return PillBox.populate(
      data.map((e) => MedicineInventorySerialization.fromJson(Map<String, dynamic>.from(e))).toList(),
    );
  }
}

class PillBoxManager{

  static final pillbox = PillBox();
  static late PillBoxNotifier pillBoxNotifier;

  static void init(WidgetRef ref) {
    pillBoxNotifier = ref.read(pillBoxProvider.notifier);
  }

  static IPillBox getSample() {
    final med1 = Medicine(
      name: 'Paracetamol',
      type: 'Pain Killer',
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
}

// --- Serialization for MedicineInventory and Medicine ---
extension MedicineInventorySerialization on MedicineInventory {
  Map<String, dynamic> toJson() => {
    'medicine': MedicineSerialization(medicine).toJson(),
    'quantity': quantity,
  };
  static MedicineInventory fromJson(Map<String, dynamic> json) => MedicineInventory(
    medicine: MedicineSerialization.fromJson(Map<String, dynamic>.from(json['medicine'])),
    quantity: json['quantity'],
  );
}

extension MedicineSerialization on Medicine {
  Map<String, dynamic> toJson() => {
    'name': name,
    'type': type,
    'color': color,
    'specs': SpecificationSerialization(specs).toJson(),
  };
  static Medicine fromJson(Map<String, dynamic> json) {
    final med = Medicine(
      name: json['name'],
      type: json['type'],
      color: json['color'],
    );
    med.addSpecification(SpecificationSerialization.fromJson(Map<String, dynamic>.from(json['specs'])));
    return med;
  }
}

extension SpecificationSerialization on Specification {
  Map<String, dynamic> toJson() => {
    'dosage': dosage,
    'unit': unit,
    'useCase': useCase,
  };
  static Specification fromJson(Map<String, dynamic> json) => Specification(
    dosage: (json['dosage'] as num).toDouble(),
    unit: json['unit'],
    useCase: json['useCase'] ?? '',
  );
}
