import 'package:lib_domain/api/base_api.dart';
import 'package:lib_domain/entrity/home/lobby_list_model/lobby_list_model.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_base/logging/logging.dart';
import 'package:lib_base/lib_base.dart';

/// 桌台数据服务
/// 负责所有与桌台相关的API调用
class TableDataService {
  final BaseApi _api = BaseApi();
  final String _logTag = 'TableDataService';

  /// 获取大厅列表
  Future<HttpResultN<LobbyListModel>> getLobbyList() async {
    try {
      logDebug('🔄 获取大厅列表...', tag: _logTag);
      final result = await _api.getLobbyList();
      
      if (result.isSuccess) {
        logDebug('✅ 大厅列表获取成功: ${result.data?.halls?.length ?? 0} 个大厅', tag: _logTag);
      } else {
        logError('❌ 大厅列表获取失败: ${result.msg}', tag: _logTag);
      }
      
      return result;
    } catch (e) {
      logError('❌ 获取大厅列表异常: $e', tag: _logTag);
      return HttpResultN<LobbyListModel>.failure(
        -1,
        '获取大厅列表异常: $e',
      );
    }
  }

  /// 获取桌台列表
  Future<HttpResultN<List<TableListModel>>> getTableList(String hallId, {int retryCount = 0, int maxRetries = 3}) async {
    try {
      logDebug('🔄 获取桌台列表: hallId=$hallId (重试次数: $retryCount/$maxRetries)', tag: _logTag);
      final result = await _api.getTableList(hallId: hallId);
      
      if (result.isSuccess) {
        logDebug('✅ 桌台列表获取成功: ${result.data?.length ?? 0} 个桌台', tag: _logTag);
        
        // 检查桌台数据中的tableId
        if (result.data != null && result.data!.isNotEmpty) {
          for (int i = 0; i < result.data!.length; i++) {
            final table = result.data![i];
            if (table.tableId == 0) {
              logDebug('⚠️ 发现桌台ID为0的异常数据', tag: _logTag);
            } else {
              // logDebug('✅ 桌台数据正常: tableId=${table.tableId}', tag: _logTag);
            }
          }
        }
      } else {
        // 检查是否是状态码210（数据处理中），需要重试
        if ((result.code == 210 || result.msg?.contains('数据处理中') == true) 
            && retryCount < maxRetries) {
          logDebug('⚠️ 数据可能还在处理中，2秒后重试... (${retryCount + 1}/$maxRetries)', tag: _logTag);
          
          // 延迟2秒后重试
          await Future.delayed(Duration(seconds: 2));
          return getTableList(hallId, retryCount: retryCount + 1, maxRetries: maxRetries);
        } else {
          logError('❌ 桌台列表获取失败: ${result.msg} (状态码: ${result.code})', tag: _logTag);
        }
      }
      
      return result;
    } catch (e) {
      logError('❌ 获取桌台列表异常: $e', tag: _logTag);
      return HttpResultN<List<TableListModel>>.failure(
        -1,
        '获取桌台列表异常: $e',
      );
    }
  }

  /// 获取菜单列表
  Future<HttpResultN<List<TableMenuListModel>>> getMenuList() async {
    try {
      logDebug('🔄 获取菜单列表...', tag: _logTag);
      final result = await _api.getTableMenuList();
      
      if (result.isSuccess) {
        logDebug('✅ 菜单列表获取成功: ${result.data?.length ?? 0} 个菜单', tag: _logTag);
      } else {
        logError('❌ 菜单列表获取失败: ${result.msg}', tag: _logTag);
      }
      
      return result;
    } catch (e) {
      logError('❌ 获取菜单列表异常: $e', tag: _logTag);
      return HttpResultN<List<TableMenuListModel>>.failure(
        -1,
        '获取菜单列表异常: $e',
      );
    }
  }

  /// 更改桌台状态
  Future<HttpResultN<void>> changeTableStatus({
    required int tableId,
    required int status,
  }) async {
    try {
      logDebug('🔄 更改桌台状态: tableId=$tableId, status=$status', tag: _logTag);
      final result = await _api.changeTableStatus(
        tableId: tableId,
        status: status,
      );
      
      if (result.isSuccess) {
        logDebug('✅ 桌台状态更改成功', tag: _logTag);
      } else {
        logError('❌ 桌台状态更改失败: ${result.msg}', tag: _logTag);
      }
      
      return result;
    } catch (e) {
      logError('❌ 更改桌台状态异常: $e', tag: _logTag);
      return HttpResultN<void>.failure(
        -1,
        '更改桌台状态异常: $e',
      );
    }
  }
}
