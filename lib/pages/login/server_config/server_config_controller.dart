import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lib_base/utils/sp_util.dart';
import 'package:lib_base/logging/logging.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/utils/l10n_utils.dart';

class ServerConfigController extends GetxController {
  // 输入框控制器
  final ipAddressController = TextEditingController();
  final portController = TextEditingController();
  
  // 加载状态
  var isSaving = false.obs;
  
  // SharedPreferences 存储键
  static const String _keyServerIp = 'server_ip_address';
  static const String _keyServerPort = 'server_port';

  @override
  void onInit() {
    super.onInit();
    _loadServerConfig();
  }

  @override
  void onClose() {
    ipAddressController.dispose();
    portController.dispose();
    super.onClose();
  }

  /// 加载已保存的服务器配置
  Future<void> _loadServerConfig() async {
    try {
      final ipAddress = await SpUtil.getString(_keyServerIp);
      final port = await SpUtil.getString(_keyServerPort);
      
      if (ipAddress.isNotEmpty) {
        ipAddressController.text = ipAddress;
      }
      
      if (port.isNotEmpty) {
        portController.text = port;
      }
    } catch (e) {
      logError('加载服务器配置失败: $e', tag: 'ServerConfigController');
    }
  }

  /// 验证IP地址格式
  bool _validateIpAddress(String ip) {
    if (ip.isEmpty) return false;
    
    // 简单的IP地址格式验证
    final ipRegex = RegExp(
      r'^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
    );
    return ipRegex.hasMatch(ip);
  }

  /// 验证端口格式
  bool _validatePort(String port) {
    if (port.isEmpty) return false;
    
    try {
      final portNum = int.parse(port);
      return portNum > 0 && portNum <= 65535;
    } catch (e) {
      return false;
    }
  }

  /// 保存服务器配置
  Future<void> saveServerConfig() async {
    // 获取当前上下文（用于显示Toast）
    final context = Get.context;
    if (context == null) return;
    
    final ipAddress = ipAddressController.text.trim();
    final port = portController.text.trim();

    // 验证IP地址
    if (ipAddress.isEmpty) {
      GlobalToast.error(context.l10n.pleaseEnterIpAddress);
      return;
    }
    
    if (!_validateIpAddress(ipAddress)) {
      GlobalToast.error(context.l10n.invalidIpAddress);
      return;
    }

    // 验证端口
    if (port.isEmpty) {
      GlobalToast.error(context.l10n.pleaseEnterPort);
      return;
    }
    
    if (!_validatePort(port)) {
      GlobalToast.error(context.l10n.invalidPort);
      return;
    }

    // 保存配置
    try {
      isSaving.value = true;
      
      await SpUtil.putString(_keyServerIp, ipAddress);
      await SpUtil.putString(_keyServerPort, port);
      
      logDebug('服务器配置保存成功: IP=$ipAddress, Port=$port', tag: 'ServerConfigController');
      
      if (context.mounted) {
        GlobalToast.success(context.l10n.serverConfigSavedSuccessfully);
        
        // 延迟后返回
        await Future.delayed(const Duration(milliseconds: 500));
        Get.back();
      }
    } catch (e) {
      logError('保存服务器配置失败: $e', tag: 'ServerConfigController');
      if (context.mounted) {
        GlobalToast.error(context.l10n.serverConfigSaveFailed);
      }
    } finally {
      isSaving.value = false;
    }
  }
}

