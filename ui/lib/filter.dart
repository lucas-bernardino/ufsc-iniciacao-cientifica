import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:dio/dio.dart';

import 'package:csv/csv.dart';

import 'package:syncfusion_flutter_charts/charts.dart';
import 'dart:ui' as ui;

import 'dart:typed_data';

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

Future<void> fetchCsv(double min, double limit, String ordered) async {

  final API_URL = dotenv.env["API_URL"];

  final dio = Dio();

  final rs = await dio.get(
    "${API_URL}/filter?min=$min&limit=${limit.toInt()}",
    options: Options(responseType: ResponseType.stream),
  );

  final file = File('hashua.csv');
  final fileStream = file.openWrite();

  await for (final chunk in rs.data.stream) {
    fileStream.add(chunk);
  }

  await fileStream.close();

}

class MicFilter extends StatefulWidget {
  const MicFilter({super.key});

  @override
  State<MicFilter> createState() => _MicFilterState();
}

class _MicFilterState extends State<MicFilter> {

  late Future<MicResponse> futureAlbum;
  double _decibelsslidervalue = 400;
  double _limitslidervalue = 0;
  double _ordenationslidervalue = 0;

  bool _decibels_flag = false;
  bool _limit_flag = false;
  bool _ordenation_flag = false;

  final GlobalKey<SfCartesianChartState> _cartesianChartKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    //futureAlbum = fetchAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
            onPressed: () => {setState(() {
          _decibels_flag = !_decibels_flag;
           })}, child: Text("Filtrar decibéis", style: TextStyle(color: Colors.lightBlue.shade900)))],),
        Visibility(
          visible: _decibels_flag,
          child: Column(children: [
            SizedBox(height: 30,),
          const Text("Valor mínimo decibéis", style: TextStyle(color: Colors.white),),
          Slider(
            activeColor: Colors.lightBlue.shade800,
            value: _decibelsslidervalue,
            max: 1000,
            min: 400,
            divisions: 30,
            label: _decibelsslidervalue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _decibelsslidervalue = value;
              });
            },
          )
        ],),),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ElevatedButton(onPressed: () => {setState(() {
          _limit_flag = !_limit_flag;
        })}, child: Text("Filtrar quantidade", style: TextStyle(color: Colors.lightBlue.shade900)))],),
        Visibility(visible: _limit_flag, child: Column(children: [
          SizedBox(height: 30,),
          Text("Quantidade de dados", style: TextStyle(color: Colors.white)),
          Slider(
            activeColor: Colors.lightBlue.shade800,
            value: _limitslidervalue,
            max: 1000,
            min: 0,
            divisions: 20,
            label: _limitslidervalue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _limitslidervalue = value;
              });
            },
          )
        ],)),
        SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [ElevatedButton(onPressed: () => {setState(() {
            _ordenation_flag = !_ordenation_flag;
          })}, child: Text("Filtrar ordenação", style: TextStyle(color: Colors.lightBlue.shade900)))],),
        Visibility(visible: _ordenation_flag, child: Column(children: [
          SizedBox(height: 30,),
          Text("Ordenação decrescente", style: TextStyle(color: Colors.white)),
          Slider(
            activeColor: Colors.lightBlue.shade800,
            value: _ordenationslidervalue,
            max: 1,
            min: 0,
            divisions: 1,
            label: _ordenationslidervalue == 0 ? "Decibéis" : "Data de Criação",
            onChanged: (double value) {
              setState(() {
                _ordenationslidervalue = value;
              });
            },
          )
        ],))
        ,
        SizedBox(height: 10,),
        Column(
          children: [
            SizedBox(height: 30,),
            ElevatedButton(
          onPressed: () { fetchCsv(_decibelsslidervalue, _limitslidervalue, _ordenationslidervalue == 0 ? "decibels" : "created_at"); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue.shade800),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download, color: Colors.white,),
              Text("Download CSV", style: TextStyle(color: Colors.white),)
            ],
          ),
        ),
        SizedBox(height: 30,),
        FutureBuilder(
            future: processCsv(context),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return ChartImage(context, _cartesianChartKey, snapshot.data);
              } else {
                return const CircularProgressIndicator();
              }
            }),
        ElevatedButton(
          onPressed: () { _renderChartAsImage(_cartesianChartKey); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue.shade800),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download, color: Colors.white,),
              Text("Gerar imagem", style: TextStyle(color: Colors.white),)
            ],
          ),
        )],)
      ],),
    );
  }
}
Container ChartImage (BuildContext context, GlobalKey<SfCartesianChartState> cck, csvData) {
  List<DataPoints> _dataSource = [];
  for (var item in csvData.skip(1)) {
    double decibelsParsed = item[1] / 10;
    String timestampParsed = item[2].toString().substring(11, 23);
    _dataSource.add(DataPoints(timestampParsed, decibelsParsed));
  }
  return Container(
    child: SfCartesianChart(
      enableAxisAnimation: true,
      tooltipBehavior: TooltipBehavior(
        color: Colors.lightBlue.shade400,
        enable: true,
        borderColor: Colors.deepOrange,
        borderWidth: 2,
        header: "",
      ),
      zoomPanBehavior: ZoomPanBehavior(
        enablePanning: true,
        enableMouseWheelZooming: true,
        enablePinching: true,
      ),
      key: cck,
      // Initialize category axis (e.g., x-axis)
      primaryXAxis: const CategoryAxis(
          labelStyle: TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500
          )
      ),
      primaryYAxis: const NumericAxis(
          labelStyle: TextStyle(
              color: Colors.white,
              fontFamily: 'Roboto',
              fontSize: 14,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w500
          )
      ),
      series: <ColumnSeries<DataPoints, String>>[
        // Initialize line series with data points
        ColumnSeries<DataPoints, String>(
          color: Colors.lightBlue,
          dataSource: _dataSource,
          xValueMapper: (DataPoints value, _) => value.x,
          yValueMapper: (DataPoints value, _) => value.y,
        ),
      ],
    ),
  );
}

Future<List<List<dynamic>>> processCsv(BuildContext context) async {
  var result = await DefaultAssetBundle.of(context).loadString(
    "dados_trator.csv",
  );
  var csvList = const CsvToListConverter().convert(result, eol: "\n");
  return csvList;
}

Future<void> saveImageToFile(Uint8List bytes, String filePath) async {
  await File(filePath).writeAsBytes(bytes);
}

Future<void> _renderChartAsImage(GlobalKey<SfCartesianChartState> cck) async {
  final image = await cck.currentState?.toImage(pixelRatio: 3.0);
  final byteData = await image?.toByteData(format: ImageByteFormat.png);
  Uint8List? uint8List = byteData?.buffer.asUint8List();
  File file = File('image.png'); // Specify the desired file path
  await file.writeAsBytes(uint8List as List<int>);
}

class DataPoints {
  DataPoints (this.x, this.y);
  final String? x;
  final num? y;
}

