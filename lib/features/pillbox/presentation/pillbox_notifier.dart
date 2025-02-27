import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/medicine_model.dart';
import '../data/pillbox_model.dart';

class PillBoxNotifier extends StateNotifier<IPillBox> {
  PillBoxNotifier() : super(PillBoxManager.getSample());

  void updatePillbox(List<MedicineInventory> pillStock) {
    state = PillBox.populate(pillStock);
  }

}

final pillBoxProvider = StateNotifierProvider<PillBoxNotifier, IPillBox>((ref) => PillBoxNotifier());