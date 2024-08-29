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

Future<void> fetchCsv(double min, String ordered, bool downloadFlag) async {

  if (!downloadFlag) {
    return;
  }

  final API_URL = dotenv.env["API_URL"];

  final dio = Dio();

  min = min * 10; // Need to do this since our database is all multiplied by ten (10).

  final rs = await dio.get(
    "${API_URL}/filter?min=$min&ordered=$ordered",
    options: Options(responseType: ResponseType.stream),
  );

  final file = File('dados.csv');
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
  double _decibelsslidervalue = 40;
  double _ordenationslidervalue = 0;

  bool _decibels_flag = false;
  bool _ordenation_flag = false;
  bool _download_flag = false;

  final List<bool> _selectedToggleOptions = <bool>[true, false];


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
            SizedBox(height: 10,),
          const Text("Valor mínimo decibéis", style: TextStyle(color: Colors.white),),
          Slider(
            activeColor: Colors.lightBlue.shade800,
            value: _decibelsslidervalue,
            max: 100,
            min: 40,
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
            _ordenation_flag = !_ordenation_flag;
          })}, child: Text("Filtrar ordenação", style: TextStyle(color: Colors.lightBlue.shade900)))],),
        Visibility(visible: _ordenation_flag, child: Column(children: [
          SizedBox(height: 20,),
          // ????? Text("Ordenação decrescente", style: TextStyle(color: Colors.white)),
          ToggleButtons(
            direction: Axis.horizontal,
            onPressed: (int index) {
              setState(() {
                for (int i = 0; i < _selectedToggleOptions.length; i++) {
                  _selectedToggleOptions[i] = i == index;
                }
                _ordenationslidervalue = index.toDouble();
              });
            },
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            selectedBorderColor: Colors.lightBlue.shade400,
            selectedColor: Colors.white,
            fillColor: Colors.lightBlue.shade800,
            color: Colors.white,
            constraints: const BoxConstraints(
              minHeight: 40.0,
              minWidth: 120.0,
            ),
            isSelected: _selectedToggleOptions,
            children: const [
              Text("Decibéis"),
              Text("Data de Criação")
            ],
          ),
        ],)),
        SizedBox(height: 20,),
        Column(
          children: [
            SizedBox(height: 10,),
            ElevatedButton(
          onPressed: () {
            setState(() {
              _download_flag = true;
            });
            processCsv(context, _decibelsslidervalue, _ordenationslidervalue == 0.0 ? "decibels" : "created_at", _download_flag);
            setState(() {});
            },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue.shade800),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download, color: Colors.white,),
              Text("Download CSV", style: TextStyle(color: Colors.white),)
            ],
          ),
        ),
        SizedBox(height: 20,),
        FutureBuilder(
            future: processCsv(context, _decibelsslidervalue, _ordenationslidervalue == 0.0 ? "decibels" : "created_at", _download_flag),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done) {
                return Visibility(
                    visible: !_decibels_flag && !_ordenation_flag,
                    child: ChartImage(context, _cartesianChartKey, snapshot.data)
                );
              } else {
                return const CircularProgressIndicator();
              }
            }),
        SizedBox(height: 10,),
          ],)
      ],),
    );
  }
}
Container ChartImage (BuildContext context, GlobalKey<SfCartesianChartState> cck, csvData) {
  if (csvData == null) {
    return Container (
      child: Column(
        children: [
          CircularProgressIndicator(
            color: Colors.lightBlue.shade800,
          ),
          const SizedBox(height: 10,),
          const Text(
              style: TextStyle(color: Colors.white),
              "Faça o download do csv para visualizar o gráfico"
          )
        ],
      ),
    );
  }
  List<DataPoints> _dataSource = [];
  for (var item in csvData.skip(1)) {
    try {
      String timestampParsed = item[2].toString().substring(11, 23);
      _dataSource.add(DataPoints(timestampParsed, item[1]));
    } catch (e) {
      print("Nao consegui colocar o ponto: ${item} no grafico");
    }
  }
  return Container(
    child: Column(
      children: [
        SfCartesianChart(
          title: const ChartTitle(
            text: "Decibéis ao longo do tempo",
            textStyle: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
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
                  fontSize: 14,
                  fontWeight: FontWeight.w500
              )
          ),
          primaryYAxis: const NumericAxis(
              minimum: 45,
              labelStyle: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w500
              )
          ),
          series: <FastLineSeries<DataPoints, String>>[
            // Initialize line series with data points
            FastLineSeries <DataPoints, String>(
              color: Colors.lightBlue,
              dataSource: _dataSource,
              xValueMapper: (DataPoints value, _) => value.x,
              yValueMapper: (DataPoints value, _) => value.y,
            ),
          ],
        ),
        ElevatedButton(
          onPressed: () { _renderChartAsImage(cck); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue.shade800),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download, color: Colors.white,),
              Text("Gerar imagem", style: TextStyle(color: Colors.white),)
            ],
          ),
        )
      ],
    ),
  );
}

Future<List<List<dynamic>>> processCsv(BuildContext context, double min, String ordered, bool downloadFlag) async {

  await fetchCsv(min, ordered, downloadFlag);

  var result = await File("dados.csv").readAsString();
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

