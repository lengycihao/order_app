import 'package:flutter/material.dart';

class CenteredTabBar extends StatelessWidget implements PreferredSizeWidget {
  final List<String> tabs;
  final Color selectedColor;
  final Color unselectedColor;
  final double fontSize;
  final TabController? controller;

  const CenteredTabBar({
    Key? key,
    required this.tabs,
    this.selectedColor = const Color(0xffFF9027),
    this.unselectedColor = const Color(0xff666666),
    this.fontSize = 20,
    this.controller,
  }) : super(key: key);

  @override
  Size get preferredSize => Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false, // 禁用自动返回按钮
      backgroundColor: Colors.white,
      elevation: 0,
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, // **整体居中**
          children: [
            TabBar(
              controller: controller,
              tabs: tabs.map((e) => Tab(text: e)).toList(),
              isScrollable: true, // 根据文字宽度自适应
              dividerColor: Colors.transparent,
              labelPadding: EdgeInsets.symmetric(horizontal: 28), // 每个 Tab 内部间距
              labelColor: selectedColor,
              tabAlignment: TabAlignment.start,
              unselectedLabelColor: unselectedColor,
              labelStyle: TextStyle(fontSize: fontSize),
              overlayColor: MaterialStateProperty.all(
                Colors.transparent,
              ), // 点击无高亮
              indicatorColor: Color(0xffFF9027),
            ),
          ],
        ),
      ),
    );
  }
}
