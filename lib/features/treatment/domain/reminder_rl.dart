import 'dart:math';

class ReminderRL {
  List<DateTime> timeSlots;
  Map<DateTime, int> successes;
  Map<DateTime, int> failures;
  Random random = Random();

  ReminderRL(this.timeSlots)
      : successes = {for (var time in timeSlots) time: 0},
        failures = {for (var time in timeSlots) time: 0};

  /// Selects the best reminder time using Thompson Sampling
  DateTime selectBestReminder() {
    Map<DateTime, double> sampledValues = {};
    for (var time in timeSlots) {
      double betaSample = _betaSample(successes[time]! + 1, failures[time]! + 1);
      sampledValues[time] = betaSample;
    }
    return sampledValues.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  void addTimeSlot(DateTime timeSlot) {
    if (timeSlots.contains(timeSlot) == false) {
      timeSlots.add(timeSlot);
      successes[timeSlot] = 0;
      failures[timeSlot] = 0;
    }
  }

  /// Updates success/failure counts after user response
  void updateResults(DateTime selectedTime, bool userTookMeds) {
    addTimeSlot(selectedTime);
    if (userTookMeds) {
      successes[selectedTime] = (successes[selectedTime] ?? 0) + 1;
    } else {
      failures[selectedTime] = (failures[selectedTime] ?? 0) + 1;
    }
  }

  /// Generates a sample from a Beta distribution using the Gamma function
  double _betaSample(int alpha, int beta) {
    double x = _gammaSample(alpha);
    double y = _gammaSample(beta);
    return x / (x + y);
  }

  /// Generates a sample from a Gamma distribution using the Marsaglia-Tsang method
  double _gammaSample(int shape) {
    if (shape < 1) {
      shape += 1;
    }
    double d = shape - 1.0 / 3.0;
    double c = 1.0 / sqrt(9 * d);

    while (true) {
      double x, v;
      do {
        x = _boxMullerTransform(); // Generate Gaussian-distributed random number
        v = pow(1 + c * x, 3).toDouble();
      } while (v <= 0);

      double u = random.nextDouble();
      if (u < 1 - 0.0331 * pow(x, 4) || log(u) < 0.5 * x * x + d * (1 - v + log(v))) {
        return d * v;
      }
    }
  }

  /// Generates a standard normally distributed (Gaussian) random number using Box-Muller Transform
  double _boxMullerTransform() {
    double u1 = random.nextDouble();
    double u2 = random.nextDouble();
    return sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);
  }
}