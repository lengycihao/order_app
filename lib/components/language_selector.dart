import 'package:flutter/material.dart';
import 'package:order_app/services/language_service.dart';
import '../l10n/app_localizations.dart';
import 'package:lib_base/logging/logging.dart';

/// 语言选择器组件
class LanguageSelector extends StatelessWidget {
  final LanguageService languageService;
  final bool showAsDialog;
  
  const LanguageSelector({
    super.key,
    required this.languageService,
    this.showAsDialog = false,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (showAsDialog) {
      return _buildDialog(context, l10n);
    } else {
      return _buildDropdown(context, l10n);
    }
  }
  
  /// 构建下拉选择器
  Widget _buildDropdown(BuildContext context, AppLocalizations l10n) {
    return DropdownButton<Locale>(
      value: languageService.currentLocale,
      onChanged: (Locale? newLocale) {
        if (newLocale != null) {
          languageService.changeLanguage(newLocale);
        }
      },
      items: LanguageService.supportedLocales.map((Locale locale) {
        return DropdownMenuItem<Locale>(
          value: locale,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _getLanguageFlag(locale.languageCode),
              const SizedBox(width: 8),
              Text(LanguageService.languageNames[locale.languageCode] ?? ''),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  /// 构建对话框选择器
  Widget _buildDialog(BuildContext context, AppLocalizations l10n) {
    return AlertDialog(
      title: Text(l10n.selectLanguage),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: LanguageService.supportedLocales.map((Locale locale) {
          final isSelected = languageService.currentLocale == locale;
          return ListTile(
            leading: _getLanguageFlag(locale.languageCode),
            title: Text(LanguageService.languageNames[locale.languageCode] ?? ''),
            trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
            onTap: () {
              languageService.changeLanguage(locale);
              Navigator.of(context).pop();
            },
          );
        }).toList(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.cancel),
        ),
      ],
    );
  }
  
  /// 获取语言对应的国旗图标
  Widget _getLanguageFlag(String languageCode) {
    String flag;
    switch (languageCode) {
      case 'zh':
        flag = '🇨🇳';
        break;
      case 'en':
        flag = '🇺🇸';
        break;
      case 'it':
        flag = '🇮🇹';
        break;
      default:
        flag = '🌐';
    }
    
    return Text(
      flag,
      style: const TextStyle(fontSize: 20),
    );
  }
}

/// 语言切换按钮
class LanguageSwitchButton extends StatelessWidget {
  final LanguageService languageService;
  
  const LanguageSwitchButton({
    super.key,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.language),
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => LanguageSelector(
            languageService: languageService,
            showAsDialog: true,
          ),
        );
      },
      tooltip: AppLocalizations.of(context)?.language ?? 'Language',
    );
  }
}

/// 语言切换底部弹窗
class LanguageBottomSheet extends StatelessWidget {
  final LanguageService languageService;
  
  const LanguageBottomSheet({
    super.key,
    required this.languageService,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 标题
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.selectLanguage,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // 语言选项
          ...LanguageService.supportedLocales.map((Locale locale) {
            final isSelected = languageService.currentLocale == locale;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: _getLanguageFlag(locale.languageCode),
                title: Text(
                  LanguageService.languageNames[locale.languageCode] ?? '',
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? Colors.blue : null,
                  ),
                ),
                trailing: isSelected ? const Icon(Icons.check, color: Colors.blue) : null,
                onTap: () async {
                  logDebug('切换语言到: ${locale.languageCode}', tag: 'LanguageSelector');
                  await languageService.changeLanguage(locale);
                  logDebug('语言切换完成，当前语言: ${languageService.currentLocale.languageCode}', tag: 'LanguageSelector');
                  Navigator.of(context).pop();
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                tileColor: isSelected ? Colors.blue.withOpacity(0.1) : null,
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  /// 获取语言对应的国旗图标
  Widget _getLanguageFlag(String languageCode) {
    String flag;
    switch (languageCode) {
      case 'zh':
        flag = '🇨🇳';
        break;
      case 'en':
        flag = '🇺🇸';
        break;
      case 'it':
        flag = '🇮🇹';
        break;
      default:
        flag = '🌐';
    }
    
    return Text(
      flag,
      style: const TextStyle(fontSize: 24),
    );
  }
  
  /// 显示语言选择底部弹窗
  static void show(BuildContext context, LanguageService languageService) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => LanguageBottomSheet(languageService: languageService),
    );
  }
}
