import 'package:flutter/material.dart';
import 'package:order_app/services/language_service.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:order_app/utils/toast_utils.dart';

class ChangeLanPage extends StatefulWidget {
  @override
  _ChangeLanPageState createState() => _ChangeLanPageState();
}

class _ChangeLanPageState extends State<ChangeLanPage> {
  late LanguageService _languageService;
  int _selectedIndex = 0;

  final List<Map<String, String>> _languages = [
    {'code': 'zh', 'name': '中文（简体）'},
    {'code': 'en', 'name': 'English'},
    {'code': 'it', 'name': 'Italia'},
  ];

  @override
  void initState() {
    super.initState();
    _languageService = getIt<LanguageService>();
    // 根据当前语言设置选中索引
    final currentLang = _languageService.currentLocale.languageCode;
    _selectedIndex = _languages.indexWhere((lang) => lang['code'] == currentLang);
    if (_selectedIndex == -1) _selectedIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('语言', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: Container(
            margin: EdgeInsets.all(12),
            child: Image.asset(
              'assets/order_arrow_back.webp',
              fit: BoxFit.contain,
            ),
          ),
        ),
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
                    _languages[index]['name']!,
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
                  onPressed: () async {
                    final selectedLang = _languages[_selectedIndex];
                    final newLocale = Locale(selectedLang['code']!);
                    
                    try {
                      await _languageService.changeLanguage(newLocale);
                      if (mounted) {
                        Toast.success(context, '语言切换成功');
                        Navigator.of(context).pop();
                      }
                    } catch (e) {
                      if (mounted) {
                        Toast.error(context, '语言切换失败：$e');
                      }
                    }
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
