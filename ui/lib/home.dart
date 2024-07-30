import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/chart.dart';
import 'package:ui/main.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Column(
          children: [
            Tooltip(
              message: "Visualizar os dados do microfone em tempo real",
              height: 60.0,
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
              height: 60.0,
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
              height: 60.0,
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
    );
  }
}
