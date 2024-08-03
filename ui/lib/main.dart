import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:ui/chart.dart';
import 'package:ui/filter.dart';
import 'package:ui/home.dart';
import 'package:ui/videos.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

Future main() async {
  await dotenv.load(fileName: ".env");
  String? minhaKey = dotenv.env["API_URL"];
  print("Minha key: " + minhaKey!);
  runApp(const NavigationRailExampleApp());
}

class NavigationRailExampleApp extends StatelessWidget {
  const NavigationRailExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NavRailExample(pageIndex: 0,),
    );
  }
}

class NavRailExample extends StatefulWidget {

  final int pageIndex;

  const NavRailExample({super.key, required this.pageIndex});

  @override
  State<NavRailExample> createState() => _NavRailExampleState(selectedIndex: pageIndex);
}

class _NavRailExampleState extends State<NavRailExample> {

  int selectedIndex = 0;

  _NavRailExampleState({required this.selectedIndex});

  NavigationRailLabelType labelType = NavigationRailLabelType.all;
  bool showLeading = false;
  bool showTrailing = false;
  double groupAlignment = -1.0;

  int number_of_videos = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          NavigationRail(
            backgroundColor: Color(0xEE000000),
            selectedIndex: selectedIndex,
            groupAlignment: groupAlignment,
            onDestinationSelected: (int index) {
              setState(() {
                selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.selected,
            leading: showLeading
                ? FloatingActionButton(
              elevation: 2,
              onPressed: () {
                // Add your onPressed code here!
              },
              child: const Icon(Icons.add),
            )
                : const SizedBox(),
            trailing: showTrailing
                ? IconButton(
              onPressed: () {
                // Add your onPressed code here!
              },
              icon: const Icon(Icons.more_horiz_rounded),
            )
                : const SizedBox(),
            destinations: <NavigationRailDestination>[
              NavigationRailDestination(
                icon: Icon(Icons.home, color: Colors.lightBlue.shade800),
                label: const Text('Home', style: TextStyle(color: Colors.white)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.insert_chart, color: Colors.lightBlue.shade800),
                label: const Text('Gráficos', style: TextStyle(color: Colors.white)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.videocam, color: Colors.lightBlue.shade800),
                label: const Text('Vídeos', style: TextStyle(color: Colors.white)),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.manage_search, color: Colors.lightBlue.shade800),
                label: const Text('Filtros', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // This is the main content.
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.black87
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (selectedIndex == 0)
                    const Center(
                        child: Home()
                    ),
                  if (selectedIndex == 1)
                    const SizedBox(
                        height: 800,
                        width: 1500,
                        child: MicChart()
                    ),
                  if (selectedIndex == 2)
                     const SizedBox(
                      height: 800,
                      width: 1500,
                      child: Videos()
                      ),
                  if (selectedIndex == 3)
                    const SizedBox(
                      height: 600,
                      width: 900,
                      child: MicFilter(),
                    )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
