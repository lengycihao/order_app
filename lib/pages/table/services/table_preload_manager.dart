import 'package:get/get.dart';
import 'package:lib_domain/entrity/home/lobby_list_model/lobby_list_model.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_base/logging/logging.dart';
import 'table_data_service.dart';

/// 桌台预加载管理器
/// 负责管理tab的预加载逻辑
class TablePreloadManager {
  final TableDataService _dataService;
  final String _logTag = 'TablePreloadManager';
  
  // 预加载状态管理
  final RxSet<int> _preloadedTabs = <int>{}.obs;
  final RxSet<int> _preloadingTabs = <int>{}.obs;
  final int _maxPreloadRange = 1; // 预加载范围：前后各1个tab

  TablePreloadManager({required TableDataService dataService}) 
      : _dataService = dataService;

  /// 获取预加载状态
  RxSet<int> get preloadedTabs => _preloadedTabs;
  RxSet<int> get preloadingTabs => _preloadingTabs;

  /// 检查指定tab是否已预加载
  bool isTabPreloaded(int index) {
    return _preloadedTabs.contains(index);
  }

  /// 检查指定tab是否正在预加载
  bool isTabPreloading(int index) {
    return _preloadingTabs.contains(index);
  }

  /// 预加载相邻tab的数据
  void preloadAdjacentTabs({
    required int currentIndex,
    required int totalTabs,
    required LobbyListModel lobbyListModel,
    required List<RxList<TableListModel>> tabDataList,
    required Function(int) onDataLoaded,
  }) {
    if (totalTabs <= 1) return; // 只有一个tab时不需要预加载
    
    // 计算需要预加载的tab范围
    final startIndex = (currentIndex - _maxPreloadRange).clamp(0, totalTabs - 1);
    final endIndex = (currentIndex + _maxPreloadRange).clamp(0, totalTabs - 1);
    
    // 预加载范围内的tab（排除当前tab）
    for (int i = startIndex; i <= endIndex; i++) {
      if (i != currentIndex && 
          i < tabDataList.length && 
          !_preloadedTabs.contains(i) && 
          !_preloadingTabs.contains(i)) {
        _preloadTabData(
          index: i,
          lobbyListModel: lobbyListModel,
          tabDataList: tabDataList,
          onDataLoaded: onDataLoaded,
        );
      }
    }
  }

  /// 预加载指定tab的数据
  Future<void> _preloadTabData({
    required int index,
    required LobbyListModel lobbyListModel,
    required List<RxList<TableListModel>> tabDataList,
    required Function(int) onDataLoaded,
  }) async {
    if (index >= tabDataList.length) return;
    
    // 检查大厅数据是否有效
    if (lobbyListModel.halls == null || 
        lobbyListModel.halls!.isEmpty || 
        index >= lobbyListModel.halls!.length) {
      logError('❌ 预加载tab $index 失败: 大厅数据无效或索引越界', tag: _logTag);
      return;
    }
    
    _preloadingTabs.add(index);
    
    try {
      final hallId = lobbyListModel.halls![index].hallId.toString();
          
      final result = await _dataService.getTableList(hallId);
      
      if (result.isSuccess) {
        List<TableListModel> data = result.data!;
        tabDataList[index].value = data;
        _preloadedTabs.add(index);
        onDataLoaded(index);
       } else {
        logError('❌ 预加载tab $index 数据失败: ${result.msg}', tag: _logTag);
      }
    } catch (e) {
      logError('❌ 预加载tab $index 数据异常: $e', tag: _logTag);
    } finally {
      _preloadingTabs.remove(index);
    }
  }

  /// 刷新已预加载的tab数据
  void refreshPreloadedTabs({
    required int currentIndex,
    required int totalTabs,
    required LobbyListModel lobbyListModel,
    required List<RxList<TableListModel>> tabDataList,
    required Function(int) onDataLoaded,
  }) {
    // 计算需要刷新的tab范围
    final startIndex = (currentIndex - _maxPreloadRange).clamp(0, totalTabs - 1);
    final endIndex = (currentIndex + _maxPreloadRange).clamp(0, totalTabs - 1);
    
    // 刷新范围内的已预加载tab（排除当前tab）
    for (int i = startIndex; i <= endIndex; i++) {
      if (i != currentIndex && 
          i < tabDataList.length && 
          _preloadedTabs.contains(i) &&
          !_preloadingTabs.contains(i)) {
        _preloadTabData(
          index: i,
          lobbyListModel: lobbyListModel,
          tabDataList: tabDataList,
          onDataLoaded: onDataLoaded,
        );
      }
    }
  }

  /// 手动触发预加载（用于测试或特殊场景）
  void triggerPreload({
    required int index,
    required LobbyListModel lobbyListModel,
    required List<RxList<TableListModel>> tabDataList,
    required Function(int) onDataLoaded,
  }) {
    if (index >= 0 && 
        index < tabDataList.length && 
        !_preloadedTabs.contains(index)) {
      _preloadTabData(
        index: index,
        lobbyListModel: lobbyListModel,
        tabDataList: tabDataList,
        onDataLoaded: onDataLoaded,
      );
    }
  }

  /// 清空预加载状态
  void clearPreloadStatus() {
    _preloadedTabs.clear();
    _preloadingTabs.clear();
    logDebug('🧹 预加载状态已清空', tag: _logTag);
  }

  /// 获取预加载状态信息
  Map<String, dynamic> getPreloadStatus() {
    return {
      'preloadedTabs': _preloadedTabs.toList(),
      'preloadingTabs': _preloadingTabs.toList(),
      'maxPreloadRange': _maxPreloadRange,
    };
  }

  /// 销毁管理器
  void dispose() {
    _preloadedTabs.clear();
    _preloadingTabs.clear();
    logDebug('🗑️ TablePreloadManager 已销毁', tag: _logTag);
  }
}
