import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:draft_1/pages/add.dart';
import 'package:draft_1/pages/chat.dart';
import 'package:draft_1/pages/home.dart';
import 'package:draft_1/pages/profile.dart';
import 'package:draft_1/pages/tests.dart';
import 'package:draft_1/theme/app_theme.dart';
import 'package:flutter/material.dart';

//import 'package:curved_navigation_bar/curved_navigation_bar.dart';

class HomePage extends StatefulWidget{
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();

}  

class _HomePageState extends State<HomePage>{

  int _selectedIndex = 0;

  void _navigateBottomBar(int index){
    setState(() {
      _selectedIndex = index;
    });
  }

  final List<Widget> _pages = [
    UserHome(),
    UserTests(),
    UserNew(),
    UserChat(),
    UserProfile()
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Scaffold(
      body: _pages[_selectedIndex],
      backgroundColor: colors.background,
      bottomNavigationBar: CurvedNavigationBar(
         //currentIndex: _selectedIndex,
         onTap: _navigateBottomBar,
         //type: BottomNavigationBarType.fixed,
      backgroundColor: colors.background,
      color: colors.navBar,

        items: [
          Icon(Icons.home, color: Colors.white),
          Icon(Icons.list_alt_rounded, color: Colors.white),
          Icon(Icons.add, color: Colors.white),
          Icon(Icons.message, color: Colors.white),
          Icon(Icons.person, color: Colors.white)
          
          
          //BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded), label: 'Tests'),
          //BottomNavigationBarItem(icon: Icon(Icons.add), label: 'New'),
          //BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Chat'),
          //BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile')

        ],
      ),
    );
  }
}