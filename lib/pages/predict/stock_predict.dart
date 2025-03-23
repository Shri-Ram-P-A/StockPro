import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class ChartPage extends StatelessWidget {
  const ChartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Simple Chart")),
      body: Align(
        alignment: Alignment.topCenter,  // Moves the chart to the top
        child: SizedBox(
          width: 400,  
          height: 300, 
          child: Padding(
            padding: const EdgeInsets.only(top: 20.0), // Adjust spacing from top
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(show: false), // Hides labels
                borderData: FlBorderData(
                  show: true,
                  border: Border.all(color: Colors.blue, width: 2),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      const FlSpot(0, 1),
                      const FlSpot(1, 3),
                      const FlSpot(2, 2),
                      const FlSpot(3, 4),
                      const FlSpot(4, 3),
                      const FlSpot(5, 5),
                    ],
                    isCurved: true,
                    color: Colors.blue,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    aboveBarData: BarAreaData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
