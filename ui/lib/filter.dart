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
  final response = await http.get(Uri.parse('http://150.162.217.35:3000/last'));
  final response_json = json.decode(response.body); // '{"decibels":504,"createdAt":"2024-04-18T11:35:12.703293Z"}'
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

  @override
  void initState() {
    super.initState();
    futureAlbum = fetchAlbum();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FutureBuilder<MicResponse>(
          future: futureAlbum,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return Text("Valor: EAE MONARK AQUI");
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              return const CircularProgressIndicator();
            }
        ),
      ),
    );
  }
}
