import 'dart:async';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

class MicChart extends StatefulWidget {
  const MicChart({super.key});

  @override
  State<MicChart> createState() => _MicChart();
}

class _MicChart extends State<MicChart> {

  DateTime format(String str) {
    int hour = str.substring(11, 13) as int;
    int minutes = str.substring(14, 16) as int;
    int seconds = str.substring(17, 19) as int;
    return DateTime(2024, 04, 18, hour, minutes, seconds);
  }

  Timer? timer;
  int count = 2024;
  List<MicData>? chartData;
  ChartSeriesController<MicData, int>? _chartSeriesController;

  late ChartSeriesController chartSeriesController_;

  @override
  void initState() {
    super.initState();
    chartData = <MicData>[
      MicData(DateTime(2010), 42),
      MicData(DateTime(2011), 47),
      MicData(DateTime(2012), 33),
      MicData(DateTime(2013), 49),
      MicData(DateTime(2014), 54),
      MicData(DateTime(2015), 41),
    ];
    timer = Timer.periodic(const Duration(seconds: 1), _updateDataSource);
  }

  void _updateDataSource(Timer timer) {
    chartData!.add(MicData(DateTime(count++), count / 10));
    if (chartData?.length == 20) {
      chartData?.removeAt(0);
      chartSeriesController_.updateDataSource(
        addedDataIndexes: <int>[chartData!.length - 1],
        removedDataIndexes: <int>[0],
      );
    } else {
      chartSeriesController_.updateDataSource(
        addedDataIndexes: <int>[chartData!.length - 1],
      );
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
        body: Center(
            child: Container(
                child: SfCartesianChart(
                    title: const ChartTitle(
                      text: "Decibéis em tempo real",
                      textStyle: TextStyle(
                        color: Colors.black54,
                        fontFamily: 'Roboto',
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                    enableAxisAnimation: true,
                    tooltipBehavior: TooltipBehavior(
                      enable: true,
                      borderColor: Colors.deepOrange,
                      borderWidth: 2,
                      header: "foo",
                    ),
                    primaryXAxis: const DateTimeAxis(),
                    series: <CartesianSeries>[
                      // Renders line chart
                      LineSeries<MicData, DateTime>(
                        onRendererCreated: (ChartSeriesController controller) {
                          chartSeriesController_ = controller;
                        },
                          color: Colors.black54,
                          width: 3.5,
                          dataSource: chartData,
                          xValueMapper: (MicData sales, _) => sales.date,
                          yValueMapper: (MicData sales, _) => sales.decibels,
                          enableTooltip: true,
                          dataLabelSettings:const DataLabelSettings(isVisible : true)
                      )
                    ]
                )
            )
        )
    );
  }

}

class MicData {
  MicData(this.date, this.decibels);
  final DateTime date;
  final double decibels;
}
