import 'package:flutter/material.dart';

class ChangeLanPage extends StatefulWidget {
  @override
  _ChangeLanPageState createState() => _ChangeLanPageState();
}

class _ChangeLanPageState extends State<ChangeLanPage> {
  int _selectedIndex = 0;

  final List<String> _languages = ['中文（简体）', 'Italiano', 'English'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('选择语言'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _languages.length,
              itemBuilder: (context, index) {
                final bool isSelected = _selectedIndex == index;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    padding: EdgeInsets.symmetric(vertical: 18, horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? Color(0x33FF9027) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _languages[index],
                      style: TextStyle(
                        color: isSelected ? Color(0xFFFF9027) : Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 60, right: 60, bottom: 200),
              child: Container(
                width: double.infinity,
                height: 48,
                decoration: BoxDecoration(
                  // 从左到右渐变：#9C90FB -> #7FA1F6
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF9C90FB), // #9C90FB
                      Color(0xFF7FA1F6), // #7FA1F6
                    ],
                    begin: Alignment.centerLeft, // 左起点
                    end: Alignment.centerRight, // 右终点
                  ),
                  borderRadius: BorderRadius.circular(28), // 圆角
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    elevation: 0, // 移除阴影
                    padding: EdgeInsets.zero,
                    // foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  onPressed: () {
                    Navigator.of(context).pop(_selectedIndex);
                  },
                  child: Text(
                    '确认',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      backgroundColor: Colors.white,
    );
  }
}
