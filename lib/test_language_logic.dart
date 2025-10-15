import 'package:flutter/material.dart';
import 'package:order_app/services/language_service.dart';
import 'package:order_app/service/service_locator.dart';

/// 测试语言设置逻辑
class LanguageTestPage extends StatefulWidget {
  const LanguageTestPage({Key? key}) : super(key: key);

  @override
  State<LanguageTestPage> createState() => _LanguageTestPageState();
}

class _LanguageTestPageState extends State<LanguageTestPage> {
  late LanguageService _languageService;
  bool _hasUserSetLanguage = false;

  @override
  void initState() {
    super.initState();
    _languageService = getIt<LanguageService>();
    _checkUserLanguageSetting();
  }

  Future<void> _checkUserLanguageSetting() async {
    final hasSet = await _languageService.hasUserSetLanguage();
    setState(() {
      _hasUserSetLanguage = hasSet;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('语言设置测试'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '当前语言设置状态',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('当前语言: ${_languageService.currentLanguageName}'),
                    Text('语言代码: ${_languageService.currentLocale.languageCode}'),
                    Text('网络请求头语言: ${_languageService.getNetworkLanguageCode()}'),
                    Text('用户是否设置过语言: ${_hasUserSetLanguage ? "是" : "否"}'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              '语言切换测试',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _changeLanguage(const Locale('zh')),
                  child: const Text('中文'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _changeLanguage(const Locale('en')),
                  child: const Text('English'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _changeLanguage(const Locale('it')),
                  child: const Text('Italia'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _checkUserLanguageSetting,
              child: const Text('刷新状态'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _changeLanguage(Locale locale) async {
    await _languageService.changeLanguage(locale);
    await _checkUserLanguageSetting();
    setState(() {});
  }
}
