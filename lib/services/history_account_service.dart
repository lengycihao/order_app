import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:order_app/models/history_account.dart';
import 'package:lib_base/logging/logging.dart';

class HistoryAccountService {
  static const String _key = 'history_accounts';
  static const int _maxHistoryCount = 10; // 最多保存10个历史账号

  // 获取历史账号列表
  static Future<List<HistoryAccount>> getHistoryAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? accountsJson = prefs.getString(_key);
      
      if (accountsJson == null || accountsJson.isEmpty) {
        return [];
      }
      
      final List<dynamic> accountsList = json.decode(accountsJson);
      return accountsList
          .map((json) => HistoryAccount.fromJson(json))
          .toList()
        ..sort((a, b) => b.lastLoginTime.compareTo(a.lastLoginTime)); // 按登录时间倒序排列
    } catch (e) {
      logError('获取历史账号失败: $e', tag: 'HistoryAccountService');
      return [];
    }
  }

  // 保存历史账号
  static Future<void> saveHistoryAccount(HistoryAccount account) async {
    try {
      final List<HistoryAccount> accounts = await getHistoryAccounts();
      
      // 移除已存在的相同账号
      accounts.removeWhere((a) => a.username == account.username);
      
      // 添加新账号到列表开头
      accounts.insert(0, account);
      
      // 限制历史账号数量
      if (accounts.length > _maxHistoryCount) {
        accounts.removeRange(_maxHistoryCount, accounts.length);
      }
      
      // 保存到本地存储
      final prefs = await SharedPreferences.getInstance();
      final String accountsJson = json.encode(
        accounts.map((account) => account.toJson()).toList(),
      );
      await prefs.setString(_key, accountsJson);
    } catch (e) {
      logError('保存历史账号失败: $e', tag: 'HistoryAccountService');
    }
  }

  // 删除历史账号
  static Future<void> removeHistoryAccount(String username) async {
    try {
      final List<HistoryAccount> accounts = await getHistoryAccounts();
      accounts.removeWhere((account) => account.username == username);
      
      final prefs = await SharedPreferences.getInstance();
      if (accounts.isEmpty) {
        await prefs.remove(_key);
      } else {
        final String accountsJson = json.encode(
          accounts.map((account) => account.toJson()).toList(),
        );
        await prefs.setString(_key, accountsJson);
      }
    } catch (e) {
      logError('删除历史账号失败: $e', tag: 'HistoryAccountService');
    }
  }

  // 清空所有历史账号
  static Future<void> clearAllHistoryAccounts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_key);
    } catch (e) {
      logError('清空历史账号失败: $e', tag: 'HistoryAccountService');
    }
  }

  // 更新账号的登录时间
  static Future<void> updateLoginTime(String username) async {
    try {
      final List<HistoryAccount> accounts = await getHistoryAccounts();
      final accountIndex = accounts.indexWhere((account) => account.username == username);
      
      if (accountIndex != -1) {
        accounts[accountIndex] = accounts[accountIndex].copyWith(
          lastLoginTime: DateTime.now(),
        );
        
        final prefs = await SharedPreferences.getInstance();
        final String accountsJson = json.encode(
          accounts.map((account) => account.toJson()).toList(),
        );
        await prefs.setString(_key, accountsJson);
      }
    } catch (e) {
      logError('更新登录时间失败: $e', tag: 'HistoryAccountService');
    }
  }
}
