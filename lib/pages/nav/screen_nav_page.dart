import 'package:flutter/material.dart';
import 'package:order_app/pages/mine/mine_page.dart';
import 'package:order_app/pages/table/table_page.dart';
import 'package:order_app/pages/takeaway/takeaway_page.dart';

class ScreenNavPage extends StatefulWidget {
  @override
  _ScreenNavPageState createState() => _ScreenNavPageState();
}

class _ScreenNavPageState extends State<ScreenNavPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [TablePage(), TakeawayPage(), MinePage()];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 2,
              offset: Offset(0, -1),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            currentIndex: _currentIndex,
            selectedItemColor: Color(0xFFFF9027),
            unselectedItemColor: Colors.grey,
            selectedFontSize: 12,
            unselectedFontSize: 12,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: Image.asset(
                  _currentIndex == 0
                      ? 'assets/order_nav_tables.webp'
                      : 'assets/order_nav_tableu.webp',
                  width: 24,
                  height: 24,
                ),
                label: '桌台',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  _currentIndex == 1
                      ? 'assets/order_nav_takeaways.webp'
                      : 'assets/order_nav_takeawayu.webp',
                  width: 24,
                  height: 24,
                ),
                label: '外卖',
              ),
              BottomNavigationBarItem(
                icon: Image.asset(
                  _currentIndex == 2
                      ? 'assets/order_nav_mines.webp'
                      : 'assets/order_nav_mineu.webp',
                  width: 24,
                  height: 24,
                ),
                label: '我的',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
