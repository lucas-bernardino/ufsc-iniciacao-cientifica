import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

class Videos extends StatefulWidget {
  const Videos({super.key});

  @override
  State<Videos> createState() => _VideosState();
}

class _VideosState extends State<Videos> {

  int numberOfVideos = 0;
  List<ListTile> listTile = [ListTile(
      leading: CircleAvatar(child: Text('1')),
      title: Text('Video 1'),
      subtitle: Text('Tamanho: 11MB'),
      trailing: IconButton(onPressed: () {print("foo");}, icon: const Icon(Icons.download),)
  ), ListTile(
      leading: CircleAvatar(child: Text('2')),
      title: Text('Video 2'),
      subtitle: Text('Tamanho: 14MB'),
      trailing: IconButton(onPressed: () {print("foo");}, icon: const Icon(Icons.download),)
  ),];

  void updateListTile() {
    setState(() {
      numberOfVideos = 5;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [IconButton(onPressed: () {print("foo");}, icon: Icon(Icons.refresh)),ListView(
          shrinkWrap: true,
          children: listTile,
        ),],
      )
    );
  }
}

class VideosResponse {
  final String duration;
  final String name;
  final String size;

  const VideosResponse({
    required this.duration,
    required this.name,
    required this.size,
  });

  factory VideosResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      'duration': String duration,
      'name': String name,
      'size': String size,
      } =>
          VideosResponse(
              duration: duration,
              name: name,
              size: size
          ),
      _ => throw const FormatException('Failed to load album.'),
    };
  }
}

Future<void> getListOfVideos() async {
  final response = await http.get(Uri.parse('http://150.162.216.184:3000/list'));
  final List<dynamic> response_json = json.decode(response.body);
  print("Response_json: ${response_json}");
}
