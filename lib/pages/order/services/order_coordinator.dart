import 'package:get/get.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_base/logging/logging.dart';
import 'package:lib_base/utils/websocket_manager.dart';
import 'package:order_app/utils/websocket_lifecycle_manager.dart';

// 导入各个控制器
import 'cart_controller.dart';
import 'order_controller.dart' as order_service;
import 'allergen_controller.dart';
import 'dish_controller.dart';

// 导入WebSocket相关
import '../order_element/websocket_handler.dart';
import '../order_element/websocket_debounce_manager.dart';

/// 订单页面协调器
/// 负责协调各个子控制器的交互
class OrderCoordinator extends GetxController {
  final String _logTag = 'OrderCoordinator';
  
  // 子控制器
  late final CartController _cartController;
  late final order_service.OrderController _orderController;
  late final AllergenController _allergenController;
  late final DishController _dishController;
  
  // 基础数据
  var table = Rx<TableListModel?>(null);
  var menu = Rx<TableMenuListModel?>(null);
  var adultCount = 0.obs;
  var childCount = 0.obs;
  var source = "".obs; // 订单来源：table(桌台), takeaway(外卖)
  
  // 状态管理
  final isInitialized = false.obs;
  final justSubmittedOrder = false.obs;
  
  // WebSocket相关
  final WebSocketManager _wsManager = wsManager;
  final WebSocketLifecycleManager _wsLifecycleManager = WebSocketLifecycleManager();
  late final WebSocketHandler _wsHandler;
  late final WebSocketDebounceManager _wsDebounceManager;
  final isWebSocketConnected = false.obs;

  @override
  void onInit() {
    super.onInit();
    _initializeControllers();
    _processArguments();
    _initializeWebSocket();
  }

  /// 初始化各个控制器
  void _initializeControllers() {
    _cartController = Get.put(CartController());
    _orderController = Get.put(order_service.OrderController());
    _allergenController = Get.put(AllergenController());
    _dishController = Get.put(DishController());
    
    logDebug('✅ 所有子控制器初始化完成', tag: _logTag);
  }

  /// 处理传递的参数
  void _processArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    logDebug('📦 接收到的参数: $args', tag: _logTag);
    
    if (args != null) {
      _processTableData(args);
      _processMenuData(args);
      _processPeopleCount(args);
      _processSource(args);
    }
  }

  /// 处理桌台数据
  void _processTableData(Map<String, dynamic> args) {
    if (args['table'] != null) {
      table.value = args['table'] as TableListModel;
      logDebug('✅ 桌台信息已设置', tag: _logTag);
    }
  }

  /// 处理菜单数据
  void _processMenuData(Map<String, dynamic> args) {
    if (args['menu'] != null) {
      final menuData = args['menu'];
      if (menuData is TableMenuListModel) {
        menu.value = menuData;
        logDebug('✅ 菜单信息已设置: ${menuData.menuName}', tag: _logTag);
      } else if (menuData is List<TableMenuListModel>) {
        _processMenuList(menuData, args);
      }
    }
  }

  /// 处理菜单列表
  void _processMenuList(List<TableMenuListModel> menuData, Map<String, dynamic> args) {
    if (menuData.isNotEmpty) {
      if (args['menu_id'] != null) {
        final targetMenuId = args['menu_id'] as int;
        final targetMenu = menuData.firstWhere(
          (menu) => menu.menuId == targetMenuId,
          orElse: () => menuData[0],
        );
        menu.value = targetMenu;
        logDebug('✅ 菜单信息已设置(根据menu_id): ${targetMenu.menuName} (ID: ${targetMenu.menuId})', tag: _logTag);
      } else {
        menu.value = menuData[0];
        logDebug('✅ 菜单信息已设置(从列表): ${menuData[0].menuName}', tag: _logTag);
      }
    }
  }

  /// 处理人数数据
  void _processPeopleCount(Map<String, dynamic> args) {
    // 处理成人数量
    if (args['adultCount'] != null) {
      adultCount.value = args['adultCount'] as int;
    } else if (args['adult_count'] != null) {
      adultCount.value = args['adult_count'] as int;
    }
    logDebug('✅ 成人数量: ${adultCount.value}', tag: _logTag);
    
    // 处理儿童数量
    if (args['childCount'] != null) {
      childCount.value = args['childCount'] as int;
    } else if (args['child_count'] != null) {
      childCount.value = args['child_count'] as int;
    }
    logDebug('✅ 儿童数量: ${childCount.value}', tag: _logTag);
  }

  /// 处理订单来源
  void _processSource(Map<String, dynamic> args) {
    if (args['source'] != null) {
      source.value = args['source'] as String;
      logDebug('✅ 订单来源: ${source.value}', tag: _logTag);
    } else if (args['fromTakeaway'] == true) {
      source.value = 'takeaway';
      logDebug('✅ 订单来源: takeaway (fromTakeaway参数)', tag: _logTag);
    } else {
      // 根据是否有桌台信息判断来源
      if (table.value?.tableId != null) {
        source.value = 'table';
        logDebug('✅ 根据桌台信息推断来源为: table', tag: _logTag);
      } else {
        source.value = 'takeaway';
        logDebug('✅ 根据无桌台信息推断来源为: takeaway', tag: _logTag);
      }
    }
  }

  /// 初始化WebSocket连接
  Future<void> _initializeWebSocket() async {
    if (table.value?.tableId == null) {
      logDebug('❌ 桌台ID为空，无法初始化WebSocket', tag: _logTag);
      return;
    }

    try {
      final tableId = table.value!.tableId.toString();
      final tableName = table.value!.tableName.toString();
      logDebug('🔌 开始初始化桌台ID: ${table.value?.tableId} 桌台名字 $tableName 的WebSocket连接...', tag: _logTag);

      // 获取用户token
      String? token = _getUserToken();

      // 初始化WebSocket处理器
      _wsHandler = WebSocketHandler(
        wsManager: _wsManager,
        tableId: tableId,
        logTag: _logTag,
        onCartRefresh: _handleCartRefresh,
        onCartAdd: _handleCartAdd,
        onCartUpdate: _handleCartUpdate,
        onCartDelete: _handleCartDelete,
        onCartClear: _handleCartClear,
        onOrderRefresh: _handleOrderRefresh,
        onPeopleCountChange: _handlePeopleCountChange,
        onMenuChange: _handleMenuChange,
        onTableChange: _handleTableChange,
        onForceUpdateRequired: _handleForceUpdateRequired,
      );

      final success = await _wsHandler.initialize(token);
      isWebSocketConnected.value = success;
      
      if (success) {
        // 初始化WebSocket防抖管理器
        _wsDebounceManager = WebSocketDebounceManager(
          wsHandler: _wsHandler,
          logTag: _logTag,
        );
        
        // 设置购物车控制器的WebSocket处理器
        _cartController.setWebSocketHandler(_wsHandler);
        
        logDebug('📋 桌台ID: $tableId ✅ 桌台 $tableName WebSocket连接初始化成功', tag: _logTag);
      } else {
        logDebug('📋 桌台ID: $tableId ❌ 桌台 $tableName WebSocket连接初始化失败', tag: _logTag);
      }
    } catch (e) {
      logError('❌ WebSocket初始化异常: $e', tag: _logTag);
      isWebSocketConnected.value = false;
    }
  }

  /// 获取用户token
  String? _getUserToken() {
    try {
      // 这里需要根据实际情况获取token
      return null;
    } catch (e) {
      logError('❌ 获取用户token失败: $e', tag: _logTag);
      return null;
    }
  }

  /// 加载所有数据
  Future<void> loadAllData() async {
    logDebug('🔄 开始加载所有数据', tag: _logTag);
    
    // 设置页面类型为点餐页面
    _wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_ORDER);
    
    // 加载敏感物数据
    await _allergenController.loadAllergens();
    
    // 加载菜品数据
    if (menu.value != null && menu.value!.menuId != null) {
      await _dishController.loadDishesFromApi(
        tableId: table.value?.tableId.toString(),
        menuId: menu.value!.menuId!,
      );
    }
    
    // 加载购物车数据
    if (table.value?.tableId != null) {
      await _cartController.loadCartFromApi(
        tableId: table.value!.tableId.toString(),
      );
      
      // 转换购物车数据
      _cartController.convertApiCartToLocalCart(
        dishes: _dishController.dishes,
        categories: _dishController.categories,
        isInitialized: isInitialized.value,
      );
    }
    
    // 标记初始化完成
    isInitialized.value = true;
    logDebug('✅ 所有数据加载完成', tag: _logTag);
  }

  /// 提交订单
  Future<Map<String, dynamic>> submitOrder() async {
    if (table.value?.tableId == null) {
      return {
        'success': false,
        'message': '桌台ID为空，无法提交订单'
      };
    }

    final result = await _orderController.submitOrder(
      tableId: table.value!.tableId.toInt(),
    );

    if (result['success'] == true) {
      // 设置标记，表示刚刚提交了订单
      justSubmittedOrder.value = true;
      
      // 等待1秒让服务器处理订单数据，然后刷新已点订单数据
      await Future.delayed(Duration(seconds: 1));
      
      // 提交成功后刷新已点订单数据
      await _orderController.loadCurrentOrder(
        tableId: table.value!.tableId.toString(),
        showLoading: false,
      );
      
      // 刷新服务器购物车数据以确保同步
      await _cartController.loadCartFromApi(
        tableId: table.value!.tableId.toString(),
        silent: true,
      );
    }

    return result;
  }

  // ========== WebSocket消息处理 ==========

  void _handleCartRefresh() {
    logDebug('🔄 收到服务器刷新购物车消息', tag: _logTag);
    if (table.value?.tableId != null) {
      _cartController.loadCartFromApi(
        tableId: table.value!.tableId.toString(),
        silent: true,
      );
    }
  }

  void _handleCartAdd() {
    logDebug('➕ 收到服务器购物车添加消息', tag: _logTag);
  }

  void _handleCartUpdate() {
    logDebug('🔄 收到服务器购物车更新消息', tag: _logTag);
  }

  void _handleCartDelete() {
    logDebug('🗑️ 收到服务器购物车删除消息', tag: _logTag);
    if (table.value?.tableId != null) {
      _cartController.loadCartFromApi(
        tableId: table.value!.tableId.toString(),
        silent: true,
      );
    }
  }

  void _handleCartClear() {
    logDebug('🧹 收到服务器购物车清空消息', tag: _logTag);
    if (table.value?.tableId != null) {
      _cartController.loadCartFromApi(
        tableId: table.value!.tableId.toString(),
        silent: true,
      );
    }
  }

  void _handleOrderRefresh() {
    logDebug('🔄 收到服务器刷新已点订单消息', tag: _logTag);
    if (table.value?.tableId != null) {
      _orderController.loadCurrentOrder(
        tableId: table.value!.tableId.toString(),
        showLoading: false,
      );
    }
  }

  void _handlePeopleCountChange(int adultCount, int childCount) {
    logDebug('👥 收到服务器修改人数消息: 成人$adultCount, 儿童$childCount', tag: _logTag);
    this.adultCount.value = adultCount;
    this.childCount.value = childCount;
  }

  void _handleMenuChange(int menuId) {
    logDebug('📋 收到服务器修改菜单消息: $menuId', tag: _logTag);
    // 这里需要重新加载菜单和菜品数据
  }

  void _handleTableChange(String tableName) {
    logDebug('🔄 收到服务器更换桌子消息: $tableName', tag: _logTag);
    if (table.value != null) {
      final currentTable = table.value!;
      final updatedTable = TableListModel(
        hallId: currentTable.hallId,
        hallName: currentTable.hallName,
        tableId: currentTable.tableId,
        tableName: tableName,
        standardAdult: currentTable.standardAdult,
        standardChild: currentTable.standardChild,
        currentAdult: currentTable.currentAdult,
        currentChild: currentTable.currentChild,
        status: currentTable.status,
        businessStatus: currentTable.businessStatus,
        businessStatusName: currentTable.businessStatusName,
        mainTableId: currentTable.mainTableId,
        menuId: currentTable.menuId,
        openTime: currentTable.openTime,
        orderTime: currentTable.orderTime,
        orderDuration: currentTable.orderDuration,
        openDuration: currentTable.openDuration,
        checkoutTime: currentTable.checkoutTime,
        orderAmount: currentTable.orderAmount,
        mainTable: currentTable.mainTable,
      );
      table.value = updatedTable;
    }
  }

  void _handleForceUpdateRequired(String message, Map<String, dynamic>? data) {
    logDebug('⚠️ 处理409状态码: $message', tag: _logTag);
    _cartController.handleForceUpdateRequired(message, data);
  }

  // ========== 公开方法 ==========

  /// 获取购物车控制器
  CartController get cartController => _cartController;

  /// 获取订单控制器
  order_service.OrderController get orderController => _orderController;

  /// 获取敏感物控制器
  AllergenController get allergenController => _allergenController;

  /// 获取菜品控制器
  DishController get dishController => _dishController;

  /// 获取筛选后的菜品列表
  List<dynamic> get filteredDishes {
    return _dishController.getFilteredDishes(
      selectedAllergens: _allergenController.selectedAllergens,
    );
  }

  /// 获取桌台显示文本
  String getTableDisplayText() {
    return '${table.value?.tableName ?? ''} (成人${adultCount.value}人, 儿童${childCount.value}人)';
  }

  @override
  void onClose() {
    // 清理WebSocket连接
    _wsHandler.dispose();
    _wsDebounceManager.dispose();
    
    // 清理所有WebSocket连接
    _wsLifecycleManager.cleanupAllConnections();
    
    logDebug('✅ OrderCoordinator 已销毁', tag: _logTag);
    super.onClose();
  }
}
