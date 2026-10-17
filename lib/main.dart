import 'package:flutter/material.dart';

import 'screens/beranda_screen.dart';
import 'screens/home_screen.dart';
import 'screens/pustaka_screen.dart';
import 'theme.dart';
import 'widgets/floating_nav.dart';
import 'widgets/mini_player.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ContolusticApp());
}

class ContolusticApp extends StatelessWidget {
  const ContolusticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'contolustic',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      home: const RootScaffold(),
    );
  }
}

class RootScaffold extends StatefulWidget {
  const RootScaffold({super.key});

  @override
  State<RootScaffold> createState() => _RootScaffoldState();
}

class _RootScaffoldState extends State<RootScaffold> {
  int _index = 0;

  static const _pages = <Widget>[
    BerandaScreen(),
    HomeScreen(),
    PustakaScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              FloatingNav(
                index: _index,
                onChanged: (i) => setState(() => _index = i),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
