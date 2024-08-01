import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  @override
  void initState() {
    initSocket();
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    return Column(
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
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Tooltip(
                  message: "Continuar captura dos dados",
                  height: 35.0,
                  verticalOffset: 70,
                  textStyle: TextStyle(color: Colors.white),
                  decoration: BoxDecoration(color: Colors.transparent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: IconButton(
                    color: Colors.blue,
                    splashColor: Colors.white,
                    iconSize: 50,
                    onPressed: () {
                      print("Começou ou parou");
                    },
                    icon: Icon(Icons.play_arrow, color: Colors.lightBlue.shade800),
                  ),
                ),
                const Text("Começar", style: TextStyle(color: Colors.white)),
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
                      print("DELETOU TUDO");
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
                  message: "Configurar parâmetros da gravação de vídeo",
                  height: 35.0,
                  verticalOffset: 70,
                  textStyle: TextStyle(color: Colors.white),
                  decoration: BoxDecoration(color: Colors.transparent.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: IconButton(
                    color: Colors.blue,
                    splashColor: Colors.white,
                    iconSize: 50,
                    onPressed: () {
                      socket.emit("update", "min:4,max:20");
                    },
                    icon: Icon(Icons.settings, color: Colors.lightBlue.shade800),
                  ),
                ),
                const Text("Configurações", style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
