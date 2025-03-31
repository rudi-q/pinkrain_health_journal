class SymptomPrediction {
  final String name;
  final double probability;

  SymptomPrediction({
    required this.name, 
    required this.probability,
  });

  @override
  String toString() => '$name (${(probability * 100).toStringAsFixed(1)}%)';
}

const defaultTriggers = {
  'Stress': 0.0,
  'Poor Sleep': 0.0,
  'Caffeine': 0.0,
  'Dehydration': 0.0,
  'Screen Time': 0.0,
  'Exercise': 0.0,
};