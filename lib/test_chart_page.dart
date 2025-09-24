import 'package:cristalyse/cristalyse.dart';
import 'package:flutter/material.dart';

class TestChartPage extends StatelessWidget {
  const TestChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    final data = [
      {'x': 1, 'y': 2},
      {'x': 2, 'y': 3},
      {'x': 3, 'y': 1},
      {'x': 4, 'y': 4},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Test Cristalyse Chart')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Testing basic Cristalyse chart:'),
            const SizedBox(height: 20),
            SizedBox(
              height: 300,
              child: CristalyseChart()
                  .data(data)
                  .mapping(x: 'x', y: 'y')
                  .geomPoint(size: 8.0)
                  .scaleXContinuous()
                  .scaleYContinuous()
                  .theme(ChartTheme.defaultTheme())
                  .build(),
            ),
          ],
        ),
      ),
    );
  }
}