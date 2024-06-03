import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

class Videos extends StatefulWidget {
  const Videos({super.key});

  @override
  State<Videos> createState() => _VideosState();
}

class _VideosState extends State<Videos> {

  int numberOfVideos = 0;
  List<ListTile> _listTile = [];

  Future<void> updateListTile() async {
    var contents = await getListOfVideos();
    var copy = _listTile;
    contents?.asMap().forEach((index, element) {
      var listTile = ListTile(
        key: Key(index.toString()),
        leading: CircleAvatar(child: Text(index.toString())),
        title: Text(element.name, style: TextStyle(color: Colors.white),),
        trailing: IconButton(onPressed: () {downloadVideo(index);}, icon: const Icon(Icons.download, color: Colors.white,),),
      );
      if (!copy.contains(listTile)) {
        copy.add(listTile);
      }
    });
    setState(() {
      _listTile = copy;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          IconButton(onPressed: () {updateListTile();}, icon: Icon(Icons.refresh, color: Colors.white,)),
          ListView(
          shrinkWrap: true,
          children: _listTile,
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

Future<List<VideosResponse>?> getListOfVideos() async {
  try {
    final API_URL = dotenv.env["API_URL"];
    final response = await http.get(Uri.parse('${API_URL}/list'));
    final List<dynamic> response_json = json.decode(response.body);
    var content = response_json.map((elem) => VideosResponse.fromJson(elem)).toList();
    return content;
  } catch (e){
    print("UNEXPECTED RESPONSE IN THE SERVER $e");
    //TODO: Handle this parsing error that might happen when the server's response was different from expected.
  }
  return null;
}

Future<void> downloadVideo(int video_number) async {
  final API_URL = dotenv.env["API_URL"];
  final dio = Dio();
  final rs = await dio.get(
    "${API_URL}/download/video/$video_number",
    options: Options(responseType: ResponseType.stream),
  );

  final file = File('video$video_number.mkv');
  final fileStream = file.openWrite();

  await for (final chunk in rs.data.stream) {
    fileStream.add(chunk);
  }

  await fileStream.close();

  print('Video downloaded successfully!');
}


