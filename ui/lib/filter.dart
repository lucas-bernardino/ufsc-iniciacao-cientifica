import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

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
  final response = await http.get(Uri.parse('http://150.162.217.69:3000/last'));
  final response_json = json.decode(response.body);
  var foo = MicResponse.fromJson(response_json);
  print("O proximos sera bom ein");
  print('Printing response_json: $response_json');
  if (response.statusCode == 200) {
    return MicResponse.fromJson(response_json);
  } else {
    throw Exception('Failed to load album');
  }
}

class MicFilter extends StatefulWidget {
  const MicFilter({super.key});

  @override
  State<MicFilter> createState() => _MicFilterState();
}

class _MicFilterState extends State<MicFilter> {
  late Future<MicResponse> futureAlbum;
  double _decibelsslidervalue = 60;
  double _daysslidervalue = 0;
  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(children: [
        Column(children: [
          Text("Valor máximo Decibéis"),
          Slider(
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
        ],),
        SizedBox(height: 100),
        Column(children: [
          Text("Dias atras"),
          Slider(
            value: _daysslidervalue,
            max: 31,
            min: 0,
            divisions: 31,
            label: _daysslidervalue.round().toString(),
            onChanged: (double value) {
              setState(() {
                _daysslidervalue = value;
              });
            },
          )
        ],),
        SizedBox(height: 100,),
        Column(children: [ElevatedButton(
          onPressed: () { print("Oba"); },
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
