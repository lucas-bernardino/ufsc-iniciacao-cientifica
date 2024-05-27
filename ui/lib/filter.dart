import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'package:dio/dio.dart';

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
  final dio = Dio();
  
  print("limit is " + limit.toString());

  final rs = await dio.get(
    "http://150.162.216.92:3000/filter?min=$min&limit=${limit as int}",
    options: Options(responseType: ResponseType.stream),
  );


  final file = File('TENTATIVA.csv');
  final fileStream = file.openWrite();

  await for (final chunk in rs.data.stream) {
    fileStream.add(chunk);
  }

  await fileStream.close();

  print("Apos os chunks\n");

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

  bool _decibels_flag = false;
  bool _limit_flag = false;

  @override
  void initState() {
    super.initState();
    //futureAlbum = fetchAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Row(children: [ElevatedButton(onPressed: () => {setState(() {
          _decibels_flag = !_decibels_flag;
        })}, child: Text("Filtrar decibéis"))],),
        Visibility(
          visible: _decibels_flag,
          child: Column(children: [
          const Text("Valor mínimo Decibéis"),
          Slider(
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
        SizedBox(height: 100),
        Row(children: [ElevatedButton(onPressed: () => {setState(() {
          _limit_flag = !_limit_flag;
        })}, child: Text("Filtrar quantidade"))],),
        Visibility(visible: _limit_flag, child: Column(children: [
          Text("Quantidade de dados"),
          Slider(
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
        ],))
        ,
        SizedBox(height: 100,),
        Column(children: [ElevatedButton(
          onPressed: () { fetchCsv(_decibelsslidervalue, _limitslidervalue, "created_at"); },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          child: const Row(
            children: [
              Icon(Icons.download),
              Text("Download")
            ],
          ),
        )],)
      ],),
    );
  }
}
