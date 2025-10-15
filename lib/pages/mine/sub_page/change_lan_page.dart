import 'package:flutter/material.dart';
import 'package:order_app/services/language_service.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/pages/nav/screen_nav_page.dart';
import 'package:order_app/pages/table/table_controller.dart';
import 'package:order_app/pages/takeaway/takeaway_controller.dart';
import 'package:order_app/pages/mine/mine_controller.dart';
import 'package:get/get.dart';
import 'package:lib_base/logging/logging.dart';

class ChangeLanPage extends StatefulWidget {
  const ChangeLanPage({super.key});
  
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

  /// 刷新所有首页数据
  /// 语言切换后需要重新获取所有数据，确保新语言的数据正确显示
  Future<void> _refreshAllHomeData() async {
    try {
      logDebug('🔄 开始刷新所有首页数据...', tag: 'ChangeLanPage');
      
      // 刷新桌台页面数据
      if (Get.isRegistered<TableControllerRefactored>()) {
        final tableController = Get.find<TableControllerRefactored>();
        await tableController.forceResetAllData();
        logDebug('✅ 桌台页面数据刷新完成', tag: 'ChangeLanPage');
      }
      
      // 刷新外卖页面数据
      if (Get.isRegistered<TakeawayController>()) {
        final takeawayController = Get.find<TakeawayController>();
        await takeawayController.refreshData(0); // 刷新未结账订单
        await takeawayController.refreshData(1); // 刷新已结账订单
        logDebug('✅ 外卖页面数据刷新完成', tag: 'ChangeLanPage');
      }
      
      // 刷新个人中心页面数据
      if (Get.isRegistered<MineController>()) {
        final mineController = Get.find<MineController>();
        await mineController.refreshUserInfo();
        logDebug('✅ 个人中心页面数据刷新完成', tag: 'ChangeLanPage');
      } else {
        logDebug('⚠️ MineController 未注册，将在页面创建时自动初始化', tag: 'ChangeLanPage');
      }
      
      logDebug('✅ 所有首页数据刷新完成', tag: 'ChangeLanPage');
    } catch (e) {
      logError('❌ 刷新首页数据失败: $e', tag: 'ChangeLanPage');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.language, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
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
                      logDebug('🌐 开始切换语言到: ${selectedLang['code']}', tag: 'ChangeLanPage');
                      
                      // 切换语言
                      await _languageService.changeLanguage(newLocale);
                      
                      if (mounted) {
                        final currentContext = context;
                        GlobalToast.success(currentContext.l10n.languageSwitchedSuccessfully);
                        
                        // 刷新所有首页数据
                        await _refreshAllHomeData();
                        
                        // 等待一小段时间确保数据刷新完成
                        await Future.delayed(const Duration(milliseconds: 200));
                        
                        // 回到首页
                        Get.offAll(() => ScreenNavPage());
                        
                        logDebug('✅ 语言切换完成，已回到首页', tag: 'ChangeLanPage');
                      }
                    } catch (e) {
                      logError('❌ 语言切换失败: $e', tag: 'ChangeLanPage');
                      if (mounted) {
                        final currentContext = context;
                        GlobalToast.error(currentContext.l10n.languageSwitchFailedPleaseRetry);
                      }
                    }
                  },
                  child: Text(
                    context.l10n.confirm,
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
