import 'package:flutter/material.dart';
import 'package:vriksha/pages/member/create/member_create_page.dart';
import 'package:vriksha/pages/member/list/member_list_page.dart';
import 'package:vriksha/pages/rsal/create/create_rsal_page.dart';
import 'package:vriksha/pages/rsal/list/rsal_list_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'Vriksha',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.purple.shade900),
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  static const _widgetOptions = [
    RsalsList(),
    MembersList(),
  ];
  static const _widgetItems = [
    BottomNavigationBarItem(icon: Icon(Icons.groups), label: 'Rsals'),
    BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Members'),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Vriksha'),
      ),
      body: _widgetOptions.elementAt(_selectedIndex),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => _selectedIndex == 0
                  ? const CreateRsalPage()
                  : const CreateMemberPage(),
            ),
          );
        },
        child: _selectedIndex == 0
            ? const Icon(Icons.group_add)
            : const Icon(Icons.person_add_alt_rounded),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: _widgetItems,
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.purple.shade900,
        onTap: _onItemTapped,
      ),
    );
  }
}
