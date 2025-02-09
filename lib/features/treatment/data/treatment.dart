class Treatment {
  final String name;
  final String type;
  final String color;
  final double dose;
  final String doseUnit;
  final String mealOption;
  final String? comment;

  Treatment({
    required this.name,
    required this.type,
    required this.color,
    required this.dose,
    required this.doseUnit,
    required this.mealOption,
    this.comment,
  });

  factory Treatment.fromJson(Map<String, dynamic> json) {
    return Treatment(
      name: json['name'],
      type: json['type'],
      color: json['color'],
      dose: json['dose'],
      doseUnit: json['doseUnit'],
      mealOption: json['mealOption'],
      comment: json['comment'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'color': color,
      'dose': dose,
      'doseUnit': doseUnit,
      'mealOption': mealOption,
      'comment': comment,
    };
  }
}