class SymptomPrediction {
  final String name;
  final double probability;

  SymptomPrediction({required this.name, required this.probability});

  @override
  String toString() => '$name (${(probability * 100).toStringAsFixed(1)}%)';
}