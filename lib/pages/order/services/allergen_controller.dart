import 'package:get/get.dart';
import 'package:lib_base/logging/logging.dart';
import 'package:lib_base/lib_base.dart';
import '../order_element/order_constants.dart';
import '../model/dish.dart';
import '../order_element/models.dart';

/// 敏感物控制器
/// 负责管理敏感物筛选相关功能
class AllergenController extends GetxController {
  final String _logTag = 'AllergenController';
  
  // 敏感物数据
  final selectedAllergens = <int>[].obs;
  final tempSelectedAllergens = <int>[].obs;
  final allAllergens = <Allergen>[].obs;
  final isLoadingAllergens = false.obs;

  /// 加载敏感物数据
  Future<void> loadAllergens() async {
    if (isLoadingAllergens.value) return;
    
    isLoadingAllergens.value = true;
    try {
      final result = await HttpManagerN.instance.executeGet(OrderConstants.allergensApiPath);
      
      if (result.isSuccess) {
        final data = _extractAllergensData(result.dataJson);
        if (data is List) {
          allAllergens.value = data.map<Allergen>((item) => Allergen.fromJson(item as Map<String, dynamic>)).toList();
          logDebug('✅ 敏感物数据加载成功: ${allAllergens.length} 个', tag: _logTag);
        }
      }
    } catch (e) {
      logError('❌ 敏感物数据加载异常: $e', tag: _logTag);
    } finally {
      isLoadingAllergens.value = false;
    }
  }

  /// 提取敏感物数据
  dynamic _extractAllergensData(dynamic dataJson) {
    dynamic data = dataJson;
    if (data is Map<String, dynamic>) {
      data = data['data'];
      if (data is Map<String, dynamic> && data['allergens'] != null) {
        data = data['allergens'];
      }
    }
    return data;
  }

  /// 切换敏感物选择状态
  void toggleAllergen(int allergenId) {
    if (selectedAllergens.contains(allergenId)) {
      selectedAllergens.remove(allergenId);
    } else {
      selectedAllergens.add(allergenId);
    }
    selectedAllergens.refresh();
    logDebug('🔄 敏感物选择状态切换: $allergenId', tag: _logTag);
  }

  /// 清空敏感物选择
  void clearAllergenSelection() {
    selectedAllergens.clear();
    selectedAllergens.refresh();
    logDebug('🧹 敏感物选择已清空', tag: _logTag);
  }

  /// 切换临时敏感物选择状态（用于弹窗）
  void toggleTempAllergen(int allergenId) {
    if (tempSelectedAllergens.contains(allergenId)) {
      tempSelectedAllergens.remove(allergenId);
    } else {
      tempSelectedAllergens.add(allergenId);
    }
    tempSelectedAllergens.refresh();
    logDebug('🔄 临时敏感物选择状态切换: $allergenId', tag: _logTag);
  }

  /// 确认敏感物选择
  void confirmAllergenSelection() {
    selectedAllergens.value = List.from(tempSelectedAllergens);
    selectedAllergens.refresh();
    logDebug('✅ 敏感物选择已确认', tag: _logTag);
  }

  /// 取消敏感物选择
  void cancelAllergenSelection() {
    tempSelectedAllergens.value = List.from(selectedAllergens);
    tempSelectedAllergens.refresh();
    logDebug('❌ 敏感物选择已取消', tag: _logTag);
  }

  /// 清空所有敏感物数据
  void clearAllAllergenData() {
    selectedAllergens.clear();
    tempSelectedAllergens.clear();
    allAllergens.clear();
    selectedAllergens.refresh();
    tempSelectedAllergens.refresh();
    allAllergens.refresh();
    logDebug('🧹 已清空所有敏感物筛选和缓存', tag: _logTag);
  }

  /// 获取选中的敏感物名称列表
  List<String> get selectedAllergenNames {
    return selectedAllergens.map((id) {
      final allergen = allAllergens.firstWhereOrNull((a) => a.id == id);
      return allergen?.label ?? '未知敏感物';
    }).toList();
  }

  /// 检查菜品是否包含选中的敏感物
  bool isDishFilteredByAllergens(Dish dish) {
    if (selectedAllergens.isEmpty || dish.allergens == null) {
      return false;
    }
    
    for (var allergen in dish.allergens!) {
      if (selectedAllergens.contains(allergen.id)) {
        return true;
      }
    }
    
    return false;
  }

  /// 获取敏感物统计信息
  Map<String, dynamic> getAllergenStats() {
    return {
      'totalAllergens': allAllergens.length,
      'selectedCount': selectedAllergens.length,
      'tempSelectedCount': tempSelectedAllergens.length,
      'isLoading': isLoadingAllergens.value,
    };
  }
}
