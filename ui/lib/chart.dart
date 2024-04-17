import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;

class MicChart extends StatelessWidget {
  const MicChart({super.key});

  @override
  Widget build(BuildContext context) {
    DateTime d1 = DateTime(2005);
    DateTime d2 = DateTime(2006);
    DateTime d3 = DateTime(2007);
    DateTime d4 = DateTime(2008);
    DateTime d5 = DateTime(2009);
    DateTime d6 = DateTime(2010);
    DateTime d7 = DateTime(2011);
    DateTime d8 = DateTime(2012);
    DateTime d9 = DateTime(2013);
    DateTime d10 = DateTime(2014);
    DateTime d11 = DateTime(2015);
    DateTime d12 = DateTime(2016);
    final List<SalesData> chartData = [
      SalesData(d1, 35),
      SalesData(d2, 28),
      SalesData(d3, 34),
      SalesData(d4, 32),
      SalesData(d5, 20),
      SalesData(d6, 26),
      SalesData(d7, 54),
      SalesData(d8, 42),
      SalesData(d9, 60),
      SalesData(d10, 16),
      SalesData(d11, 41),
      SalesData(d12, 33),
    ];

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
                    primaryXAxis: DateTimeAxis(),
                    series: <CartesianSeries>[
                      // Renders line chart
                      LineSeries<SalesData, DateTime>(
                        color: Colors.black54,
                          width: 3.5,
                          dataSource: chartData,
                          xValueMapper: (SalesData sales, _) => sales.year,
                          yValueMapper: (SalesData sales, _) => sales.sales,
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

class SalesData {
  SalesData(this.year, this.sales);
  final DateTime year;
  final double sales;
}