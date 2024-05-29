import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;

class MicChart extends StatefulWidget {
  const MicChart({super.key});

  @override
  State<MicChart> createState() => _MicChart();
}

class _MicChart extends State<MicChart> {
  DateTime format(String str) {
    int hour = int.parse(str.substring(11, 13));
    int minutes = int.parse(str.substring(14, 16));
    int seconds = int.parse(str.substring(17, 19));
    int milis = int.parse(str.substring(20, 22));
    return DateTime(2024, 04, 19, hour, minutes, seconds, milis);
  }

  Timer? timer;
  List<MicData>? chartData;
  ChartSeriesController<MicData, int>? _chartSeriesController;

  late ChartSeriesController chartSeriesController_;

  @override
  void initState() {
    super.initState();
    chartData = <MicData>[];
    timer = Timer.periodic(const Duration(milliseconds: 500), _updateDataSource);
  }

  Future<void> _updateDataSource(Timer timer) async {
    var micResponse = await fetchAlbum();
    double decibels_value = micResponse.decibels / 10;
    DateTime time = format(micResponse.createdAt);
    chartData!.add(MicData(time, decibels_value));
    if (chartData?.length == 100) {
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
        backgroundColor: Colors.transparent,
        body: Center(
            child: Container(
                child: SfCartesianChart(
                    title: const ChartTitle(
                      text: "Decibéis em tempo real",
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Roboto',
                        fontStyle: FontStyle.italic,
                        fontSize: 14,
                      ),
                    ),
                    enableAxisAnimation: true,
                    tooltipBehavior: TooltipBehavior(
                      color: Colors.lightBlue.shade400,
                      enable: true,
                      borderColor: Colors.deepOrange,
                      borderWidth: 2,
                      header: "foo",
                    ),
                    primaryXAxis: const DateTimeAxis(),
                    plotAreaBackgroundColor: Colors.teal[100],
                    series: <CartesianSeries>[
                      // Renders line chart
                      LineSeries<MicData, DateTime>(
                          onRendererCreated: (ChartSeriesController controller) {
                          chartSeriesController_ = controller;
                        },
                          color: Colors.lightBlue.shade900,
                          width: 3.5,
                          dataSource: chartData,
                          xValueMapper: (MicData sales, _) => sales.date,
                          yValueMapper: (MicData sales, _) => sales.decibels,
                          enableTooltip: true,
                          dataLabelSettings:DataLabelSettings(isVisible : true, color: Colors.lightBlue.shade700, borderRadius: 20)
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


class MicResponse {
  final num decibels;
  final String createdAt;

  const MicResponse({
    required this.decibels,
    required this.createdAt,
  });

  factory MicResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      'decibels': num decibels,
      'createdAt': String createdAt,
      } =>
          MicResponse(
            decibels: decibels,
            createdAt: createdAt,
          ),
      _ => throw const FormatException('Failed to load album.'),
    };
  }
}

Future<MicResponse> fetchAlbum() async {
  final response = await http.get(Uri.parse('http://150.162.217.170:3000/last'));
  final response_json = json.decode(response.body);
  if (response.statusCode == 200) {
    return MicResponse.fromJson(response_json);
  } else {
    throw Exception('Failed to load album');
  }
}
