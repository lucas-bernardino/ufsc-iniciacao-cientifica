import 'dart:async';
import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/chart.dart';
import 'package:ui/main.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {

  late IO.Socket socket;

  bool _configOptions = false;
  final _textControllerMin = TextEditingController();
  final _textControllerMax = TextEditingController();

  bool _isSendingData = false;

  // socket.emit("status", "info");

  @override
  void dispose() {
    _textControllerMin.dispose();
    _textControllerMax.dispose();
    super.dispose();
  }

  @override
  void initState() {
    initSocket();
    super.initState();
    _textControllerMin.text = "4";
    _textControllerMax.text = "20";
    //socket.emit("status", "info");
    Timer.periodic(const Duration(milliseconds: 500), (timer) {
      socket.emit("status", "info");
    },);
  }

  initSocket() {
    socket = IO.io("ws://localhost:3000", <String, dynamic>{
      'autoConnect': false,
      'transports': ['websocket'],
    });
    socket.connect();
    socket.onConnect((_) {
      print('Connection established');
    });
    socket.onDisconnect((_) => print('Connection Disconnection'));
    socket.onConnectError((err) => print(err));
    socket.onError((err) => print(err));
    socket.on('update',(data){
      print("Recebi: ${data}");
    });
    socket.on('status',(data){
      print("Recebi do status: ${data}");
      String status = (data.toString().replaceAll("current:", ""));
      if (status == "true") {
        setState(() {
          _isSendingData = true;
        });
      }
      if (status == "false") {
        setState(() {
          _isSendingData = false;
        });
      }
      print("_isSendingData inside of socket.on: $_isSendingData");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1000,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Column(
                children: [
                  Tooltip(
                    message: "Visualizar os dados do microfone em tempo real",
                    height: 35.0,
                    verticalOffset: 100,
                    textStyle: TextStyle(color: Colors.white),
                    decoration: BoxDecoration(color: Colors.transparent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: IconButton(
                      color: Colors.blue,
                      splashColor: Colors.white,
                      iconSize: 100,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NavRailExample(pageIndex: 1)),
                        );
                      },
                      icon: Icon(Icons.insert_chart, color: Colors.lightBlue.shade800),
                    ),
                  ),
                  const Text("Gráficos", style: TextStyle(color: Colors.white)),
                ],
              ),
              Column(
                children: [
                  Tooltip(
                    message: "Baixar vídeos obtidods pela câmera de monitoramento",
                    height: 35.0,
                    verticalOffset: 100,
                    textStyle: TextStyle(color: Colors.white),
                    decoration: BoxDecoration(color: Colors.transparent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: IconButton(
                      color: Colors.blue,
                      splashColor: Colors.white,
                      iconSize: 100,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NavRailExample(pageIndex: 2)),
                        );
                      },
                      icon: Icon(Icons.videocam, color: Colors.lightBlue.shade800),
                    ),
                  ),
                  const Text("Vídeos", style: TextStyle(color: Colors.white)),
                ],
              ),
              Column(
                children: [
                  Tooltip(
                    message: "Baixar e visualizar dados do banco de dados",
                    height: 35.0,
                    verticalOffset: 100,
                    textStyle: TextStyle(color: Colors.white),
                    decoration: BoxDecoration(color: Colors.transparent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                    child: IconButton(
                      color: Colors.blue,
                      splashColor: Colors.white,
                      iconSize: 100,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NavRailExample(pageIndex: 3)),
                        );
                      },
                      icon: Icon(Icons.manage_search, color: Colors.lightBlue.shade800),
                    ),
                  ),
                  const Text("Filtros", style: TextStyle(color: Colors.white)),
                ],
              ),
            ],
          ),
          SizedBox(height: 100),
          Container(
            height: 250,
            width: 550,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Column(
                  children: [
                    Tooltip(
                      message: _isSendingData ? "Pausar captura de dados" : "Continuar captura de dados",
                      height: 35.0,
                      verticalOffset: 70,
                      textStyle: TextStyle(color: Colors.white),
                      decoration: BoxDecoration(color: Colors.transparent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: IconButton(
                        color: Colors.blue,
                        splashColor: Colors.white,
                        iconSize: 50,
                        onPressed: () {
                          setState(() {});
                          print("_isSendingData after emitting: $_isSendingData");
                        },
                        icon: Icon(_isSendingData ? Icons.play_arrow : Icons.pause, color: Colors.lightBlue.shade800),
                      ),
                    ),
                    Text(_isSendingData ? "Pausar" : "Continuar", style: TextStyle(color: Colors.white)),
                  ],
                ),
                SizedBox(width: 110,),
                Column(
                  children: [
                    Tooltip(
                      message: "Deletar todos os dados no banco de dados",
                      height: 35.0,
                      verticalOffset: 70,
                      textStyle: TextStyle(color: Colors.white),
                      decoration: BoxDecoration(color: Colors.transparent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: IconButton(
                        color: Colors.blue,
                        splashColor: Colors.white,
                        iconSize: 50,
                        onPressed: () {
                          print("Deseja deletar permanente todos os dados?");
                        },
                        icon: Icon(Icons.delete_forever_rounded, color: Colors.lightBlue.shade800),
                      ),
                    ),
                    const Text("Apagar", style: TextStyle(color: Colors.white)),
                  ],
                ),
                SizedBox(width: 110,),
                Column(
                  children: [
                    Tooltip(
                      message: _configOptions ? "" : "Configurar parâmetros da gravação de vídeo",
                      height: 35.0,
                      verticalOffset: 70,
                      textStyle: TextStyle(color: Colors.white),
                      decoration: BoxDecoration(color: Colors.transparent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                      child: IconButton(
                        color: Colors.blue,
                        splashColor: Colors.white,
                        iconSize: 50,
                        onPressed: () {
                          setState(() {
                            _configOptions = !_configOptions;
                          });
                        },
                        icon: Icon(Icons.settings, color: Colors.lightBlue.shade800),
                      ),
                    ),
                    const Text("Configurações", style: TextStyle(color: Colors.white)),
                    SizedBox(height: 10,),
                    Visibility(
                        visible: _configOptions,
                        child: Container(
                          decoration: BoxDecoration(
                              border: Border.all(color: Colors.blueAccent),
                              borderRadius: BorderRadius.circular(10)
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      controller: _textControllerMin,
                                      style: TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                        contentPadding: EdgeInsets.symmetric(horizontal: 13),
                                        helperText: "Minimo",
                                        helperStyle: TextStyle(color: Colors.grey),
                                      ),
                                      onSubmitted: (String value) {
                                        print("Enviou ${value}");
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10,),
                                  SizedBox(
                                    width: 70,
                                    child: TextField(
                                      textAlign: TextAlign.center,
                                      controller: _textControllerMax,
                                      style: TextStyle(color: Colors.white),
                                      decoration: const InputDecoration(
                                          contentPadding: EdgeInsets.symmetric(horizontal: 11),
                                          helperText: "Máximo",
                                          helperStyle: TextStyle(color: Colors.grey)
                                      ),
                                      onSubmitted: (String value) {
                                        print("Enviou ${value}");
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10,),
                              ElevatedButton(
                                style: ButtonStyle(
                                    backgroundColor: MaterialStateProperty.all<Color>(Colors.transparent),
                                    shadowColor: MaterialStateProperty.all<Color>(Colors.black45),
                                    foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                                    surfaceTintColor: MaterialStateProperty.all<Color>(Colors.black)
                                ),
                                onPressed: () {
                                  socket.emit("update", "min:${_textControllerMin.text},max:${_textControllerMax.text}");
                                  print("Mandei o valor");
                                },
                                child: const Row(
                                  children: [
                                    Icon(Icons.refresh, size: 20, color: Colors.blue),
                                    SizedBox(width: 3,),
                                    Text("Atualizar", style: TextStyle(color: Colors.blue))
                                  ],
                                ),
                              ),
                              const SizedBox(height: 10,),
                            ],
                          ),
                        ))
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}