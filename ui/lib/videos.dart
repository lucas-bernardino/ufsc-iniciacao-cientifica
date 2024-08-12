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

  Future<List<ListTile>> updateListTile(BuildContext context) async {
    var contents = await getListOfVideos();
    _listTile = [];
    contents?.asMap().forEach((index, element) {
      int hours = int.parse(element.video_hour.substring(0, 2)) - 4; // CONVERTING TO LOCAL TIME
      var minutes = element.video_hour.substring(3, 5);
      var listTile = ListTile(
        key: Key(index.toString()),
        leading: CircleAvatar(child: Text(index.toString())),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Text("Tamanho: ${element.video_size}"),
          Text("Data de Criação: ${element.video_day}/${element.video_month} - ${hours}:${minutes}")
        ],),
        subtitleTextStyle: TextStyle(color: Colors.blueGrey, fontFamily: "SF_BOLD"),
        title: Text(element.video_name, style: TextStyle(color: Colors.white),),
        trailing: SizedBox(
          width: 100,
          child: Row(
            children: [
              IconButton(onPressed: () {
                setState(() {});
                downloadVideo(index);
                }, icon: const Icon(Icons.download, color: Colors.white,),),
              IconButton(onPressed: () {
                deleteVideo(index);
                setState(() {});
                }, icon: const Icon(Icons.delete, color: Colors.white,),),
            ],
          ),
        ),
      );
      _listTile.add(listTile);
    });
    return _listTile;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          IconButton(onPressed: () {
            updateListTile(context);
            setState(() {});
            },
            icon: Icon(Icons.refresh, color: Colors.white,)
          ),
          FutureBuilder(
          future: updateListTile(context),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return ListView(
                  shrinkWrap: true,
                  children: _listTile,
              );
            } else {
              return const CircularProgressIndicator();
            }
          }),
        ],
      )
    );
  }
}

class VideosResponse {
  final String video_name;
  final String video_hour;
  final String video_day;
  final String video_month;
  final String video_size;

  const VideosResponse({
    required this.video_name,
    required this.video_hour,
    required this.video_day,
    required this.video_month,
    required this.video_size,
  });

  factory VideosResponse.fromJson(Map<String, dynamic> json) {
    return switch (json) {
      {
      'video_name': String video_name,
      'video_hour': String video_hour,
      'video_day': String video_day,
      'video_month': String video_month,
      'video_size': String video_size,
      } =>
          VideosResponse(
              video_name: video_name,
              video_hour: video_hour,
              video_day: video_day,
              video_month: video_month,
              video_size: video_size,
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
}

Future <int> deleteVideo(int video_number) async {
  final API_URL = dotenv.env["API_URL"];
  final response = await http.get(Uri.parse('${API_URL}/delete/video/${video_number}'));
  print("Status code: $response");
  return response.statusCode;
}


