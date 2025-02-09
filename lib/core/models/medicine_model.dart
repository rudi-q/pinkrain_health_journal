class Specification{
  final double dosage;
  final String unit;
  final String useCase;

  Specification({
    this.dosage = 1.0,
    this.unit = 'mg',
    this.useCase = '',
  });
}

class Medicine {
  final String name;
  final String type;
  final String color;
  late Specification specs;

  Medicine({
    required this.name,
    required this.type,
    this.color = 'green',
  });

  addSpecification(Specification specification) {
    specs = specification;
  }
}

class MedicineInventory {
  final Medicine medicine;
  final int quantity;

  MedicineInventory({
    required this.medicine,
    required this.quantity,
  });
}