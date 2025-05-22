import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/medicine_model.dart';
import '../../../core/services/hive_service.dart';
import '../../../core/util/helpers.dart';
import '../data/pillbox_model.dart';

class PillBoxNotifier extends StateNotifier<IPillBox> {
  PillBoxNotifier() : super(PillBox()) {
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    final loaded = await HiveService.loadPillBox();
    devPrint('[PillBoxNotifier._loadFromHive] Setting state: $loaded');
    if (loaded.isNotEmpty) {
      // Use proper deserialization with the extension methods
      final deserializedStock = loaded.map((item) => 
        MedicineInventorySerialization.fromJson(Map<String, dynamic>.from(item))).toList();
      state = PillBox.populate(deserializedStock);
    } else {
      state = PillBox();
    }
  }

  void addMedicine(Medicine medicine, int quantity) {
    final newStock = [...state.pillStock, MedicineInventory(medicine: medicine, quantity: quantity)];
    state = PillBox.populate(newStock);
    devPrint('[PillBoxNotifier.addMedicine] New state: $newStock');
    HiveService.savePillBox(state.pillStock);
  }

  void removeMedicine(Medicine medicine) {
    final newStock = state.pillStock.where((item) => item.medicine.name != medicine.name).toList();
    state = PillBox.populate(newStock);
    devPrint('[PillBoxNotifier.removeMedicine] New state: $newStock');
    HiveService.savePillBox(state.pillStock);
  }

  void updateMedicineQuantity(MedicineInventory inventory, int newQuantity) {
    final newStock = state.pillStock.map((item) {
      if (item.medicine.name == inventory.medicine.name) {
        return MedicineInventory(medicine: item.medicine, quantity: newQuantity);
      }
      return item;
    }).toList();
    state = PillBox.populate(newStock);
    devPrint('[PillBoxNotifier.updateMedicineQuantity] New state: $newStock');
    HiveService.savePillBox(state.pillStock);
  }

  void updatePillbox(List<MedicineInventory> pillStock) {
    state = PillBox.populate(pillStock);
    devPrint('[PillBoxNotifier.updatePillbox] New state: $pillStock');
    HiveService.savePillBox(state.pillStock);
  }
}

final pillBoxProvider = StateNotifierProvider<PillBoxNotifier, IPillBox>((ref) => PillBoxNotifier());