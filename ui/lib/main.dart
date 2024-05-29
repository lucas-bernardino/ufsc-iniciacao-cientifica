import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:microphone_ui/chart.dart';
import 'package:microphone_ui/filter.dart';
import 'package:microphone_ui/videos.dart';

/// Flutter code sample for [NavigationRail].

void main() => runApp(const NavigationRailExampleApp());

class NavigationRailExampleApp extends StatelessWidget {
  const NavigationRailExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: NavRailExample(),
    );
  }
}

class NavRailExample extends StatefulWidget {
  const NavRailExample({super.key});

  @override
  State<NavRailExample> createState() => _NavRailExampleState();
}

class _NavRailExampleState extends State<NavRailExample> {
  int _selectedIndex = 0;
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
            backgroundColor: Colors.blueGrey.shade900,
            selectedIndex: _selectedIndex,
            groupAlignment: groupAlignment,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
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
                  gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [Colors.blueGrey.shade900, Colors.blueGrey.shade600, Colors.blueGrey.shade900]
                  )
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  if (_selectedIndex == 0)
                    const SizedBox(
                        height: 800,
                        width: 1500,
                        child: MicChart()
                    ),
                  if (_selectedIndex == 1)
                     const SizedBox(
                      height: 800,
                      width: 1500,
                      child: Videos()
                      ),
                  if (_selectedIndex == 2)
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
