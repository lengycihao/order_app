import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../model/dish.dart';
import 'package:lib_domain/entrity/order/dish_list_model/dish_list_model.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_base/lib_base.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:lib_domain/entrity/cart/cart_info_model.dart';
import 'package:lib_domain/entrity/order/current_order_model.dart';
import 'package:lib_domain/api/order_api.dart';
import 'package:lib_base/utils/websocket_manager.dart';
import 'package:lib_base/logging/logging.dart';
import 'package:lib_base/network/interceptor/auth_service.dart';
import 'package:order_app/service/service_locator.dart';
import 'package:order_app/utils/modal_utils.dart';
import 'package:order_app/utils/toast_utils.dart';
import 'package:order_app/utils/websocket_lifecycle_manager.dart';

// 导入优化后的类
import 'order_constants.dart';
import 'websocket_handler.dart';
import 'websocket_debounce_manager.dart';
import 'cart_manager.dart';
import 'local_cart_manager.dart';
import 'error_handler.dart';
import 'data_converter.dart';
import 'models.dart';

enum SortType { none, priceAsc, priceDesc }

class OrderController extends GetxController {
  // 基础数据
  final categories = <String>[].obs;
  final selectedCategory = 0.obs;
  final searchKeyword = "".obs;
  final sortType = SortType.none.obs;
  final dishes = <Dish>[].obs;
  final cart = <CartItem, int>{}.obs;
  final selectedAllergens = <int>[].obs;
  final tempSelectedAllergens = <int>[].obs;
  final allAllergens = <Allergen>[].obs;
  final isLoadingAllergens = false.obs;
  final isSearchVisible = false.obs;
  final isLoadingDishes = false.obs;
  final isLoadingCart = false.obs;
  final isCartOperationLoading = false.obs; // 购物车操作loading状态
  final justSubmittedOrder = false.obs; // 标记是否刚刚提交了订单
  final isInitialized = false.obs; // 标记是否已完成初始化

  // 从路由传递的数据
  var table = Rx<TableListModel?>(null);
  var menu = Rx<TableMenuListModel?>(null);
  var adultCount = 0.obs;
  var childCount = 0.obs;
  var source = "".obs; // 订单来源：table(桌台), takeaway(外卖)
  
  // 购物车数据
  var cartInfo = Rx<CartInfoModel?>(null);
  
  // 已点订单数据
  var currentOrder = Rx<CurrentOrderModel?>(null);
  final isLoadingOrdered = false.obs;
  
  // 409强制更新相关
  CartItem? _lastOperationCartItem;
  int? _lastOperationQuantity;
  
  // WebSocket相关
  final WebSocketManager _wsManager = wsManager;
  final isWebSocketConnected = false.obs;
  final WebSocketLifecycleManager _wsLifecycleManager = WebSocketLifecycleManager();
  
  // 管理器
  late final WebSocketHandler _wsHandler;
  late final WebSocketDebounceManager _wsDebounceManager;
  late final CartManager _cartManager;
  late final LocalCartManager _localCartManager;
  late final ErrorHandler _errorHandler;
  
  // API服务
  final BaseApi _api = BaseApi();
  final OrderApi _orderApi = OrderApi();
  

  @override
  void onInit() {
    super.onInit();
    logDebug('🔍 OrderController onInit 开始', tag: OrderConstants.logTag);
    
    // 设置页面类型为点餐页面
    _wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_ORDER);
    
    // 初始化管理器
    _initializeManagers();
    
    // 处理传递的参数
    _processArguments();
    
    // 初始化WebSocket连接
    _initializeWebSocket();
    
    // 加载数据
    _loadDishesAndCart();
  }

  /// 初始化管理器
  void _initializeManagers() {
    _cartManager = CartManager(logTag: OrderConstants.logTag);
    _localCartManager = LocalCartManager(logTag: OrderConstants.logTag);
    _errorHandler = ErrorHandler(logTag: OrderConstants.logTag);
    
    // 设置本地购物车管理器的回调
    _localCartManager.setCallbacks(
      onQuantityChanged: _onLocalQuantityChanged,
      onWebSocketSend: _onLocalWebSocketSend,
      onWebSocketFailed: _onLocalWebSocketFailed,
    );
    
    // WebSocket处理器将在有tableId后初始化
  }

  /// 处理传递的参数
  void _processArguments() {
    final args = Get.arguments as Map<String, dynamic>?;
    logDebug('📦 接收到的参数: $args', tag: OrderConstants.logTag);
    
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
      logDebug('✅ 桌台信息已设置', tag: OrderConstants.logTag);
    }
  }

  /// 处理菜单数据
  void _processMenuData(Map<String, dynamic> args) {
    if (args['menu'] != null) {
      final menuData = args['menu'];
      if (menuData is TableMenuListModel) {
        menu.value = menuData;
        logDebug('✅ 菜单信息已设置: ${menuData.menuName}', tag: OrderConstants.logTag);
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
        logDebug('✅ 菜单信息已设置(根据menu_id): ${targetMenu.menuName} (ID: ${targetMenu.menuId})', tag: OrderConstants.logTag);
      } else {
        menu.value = menuData[0];
        logDebug('✅ 菜单信息已设置(从列表): ${menuData[0].menuName}', tag: OrderConstants.logTag);
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
    logDebug('✅ 成人数量: ${adultCount.value}', tag: OrderConstants.logTag);
    
    // 处理儿童数量
    if (args['childCount'] != null) {
      childCount.value = args['childCount'] as int;
    } else if (args['child_count'] != null) {
      childCount.value = args['child_count'] as int;
    }
    logDebug('✅ 儿童数量: ${childCount.value}', tag: OrderConstants.logTag);
  }

  /// 处理订单来源
  void _processSource(Map<String, dynamic> args) {
    if (args['source'] != null) {
      source.value = args['source'] as String;
      logDebug('✅ 订单来源: ${source.value}', tag: OrderConstants.logTag);
    } else if (args['fromTakeaway'] == true) {
      source.value = 'takeaway';
      logDebug('✅ 订单来源: takeaway (fromTakeaway参数)', tag: OrderConstants.logTag);
    } else {
      // 根据是否有桌台信息判断来源
      if (table.value?.tableId != null) {
        source.value = 'table';
        logDebug('✅ 根据桌台信息推断来源为: table', tag: OrderConstants.logTag);
      } else {
        source.value = 'takeaway';
        logDebug('✅ 根据无桌台信息推断来源为: takeaway', tag: OrderConstants.logTag);
      }
    }
  }

  /// 初始化WebSocket连接
  Future<void> _initializeWebSocket() async {
    if (table.value?.tableId == null) {
      logDebug('❌ 桌台ID为空，无法初始化WebSocket', tag: OrderConstants.logTag);
      return;
    }

    try {
      final tableId = table.value!.tableId.toString();
      final tableName = table.value!.tableName.toString();
      logDebug('🔌 开始初始化桌台ID: ${table.value?.tableId} 桌台名字 $tableName 的WebSocket连接...', tag: OrderConstants.logTag);

      // 获取用户token
      String? token = _getUserToken();

      // 初始化WebSocket处理器
      _wsHandler = WebSocketHandler(
        wsManager: _wsManager,
        tableId: tableId,
        logTag: OrderConstants.logTag,
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
          logTag: OrderConstants.logTag,
        );
        // 设置失败回调
        _wsDebounceManager.setFailureCallback(_onWebSocketDebounceFailed);
        logDebug('📋 桌台ID: $tableId ✅ 桌台 $tableName WebSocket连接初始化成功', tag: OrderConstants.logTag);
        
        // 启动连接状态监控
        _startWebSocketStatusMonitoring();
      } else {
        logDebug('📋 桌台ID: $tableId ❌ 桌台 $tableName WebSocket连接初始化失败', tag: OrderConstants.logTag);
        // 连接失败，尝试重连
        _scheduleWebSocketReconnect();
      }
    } catch (e) {
      logDebug('❌ WebSocket初始化异常: $e', tag: OrderConstants.logTag);
      isWebSocketConnected.value = false;
      // 异常情况下也尝试重连
      _scheduleWebSocketReconnect();
    }
  }
  
  /// 启动WebSocket连接状态监控
  void _startWebSocketStatusMonitoring() {
    Timer.periodic(Duration(seconds: 5), (timer) {
      if (!isWebSocketConnected.value) {
        logDebug('⚠️ WebSocket连接已断开，尝试重连', tag: OrderConstants.logTag);
        _reconnectWebSocket();
      }
    });
  }
  
  /// 安排WebSocket重连
  void _scheduleWebSocketReconnect() {
    Timer(Duration(seconds: 3), () {
      if (table.value?.tableId != null) {
        logDebug('🔄 尝试重新连接WebSocket...', tag: OrderConstants.logTag);
        _reconnectWebSocket();
      }
    });
  }
  
  /// 重连WebSocket
  Future<void> _reconnectWebSocket() async {
    if (table.value?.tableId == null) return;
    
    try {
      final tableId = table.value!.tableId.toString();
      final token = _getUserToken();
      
      logDebug('🔄 重新连接桌台 $tableId 的WebSocket...', tag: OrderConstants.logTag);
      
      final success = await _wsManager.initializeTableConnection(
        tableId: tableId,
        token: token,
      );
      
      isWebSocketConnected.value = success;
      
      if (success) {
        logDebug('✅ WebSocket重连成功', tag: OrderConstants.logTag);
      } else {
        logDebug('❌ WebSocket重连失败，3秒后再次尝试', tag: OrderConstants.logTag);
        _scheduleWebSocketReconnect();
      }
    } catch (e) {
      logDebug('❌ WebSocket重连异常: $e', tag: OrderConstants.logTag);
      _scheduleWebSocketReconnect();
    }
  }

  /// 获取用户token
  String? _getUserToken() {
    try {
      final authService = getIt<AuthService>();
      final token = authService.getCurrentToken();
      if (token != null) {
        logDebug('🔑 获取到用户token: ${token.substring(0, 20)}...', tag: OrderConstants.logTag);
      } else {
        logDebug('⚠️ 用户token为空，将使用默认token', tag: OrderConstants.logTag);
      }
      return token;
    } catch (e) {
      logDebug('❌ 获取用户token失败: $e', tag: OrderConstants.logTag);
      return null;
    }
  }

  /// 按顺序加载菜品数据和购物车数据
  Future<void> _loadDishesAndCart() async {
    logDebug('🔄 开始按顺序加载菜品和购物车数据', tag: OrderConstants.logTag);
    
    // 先加载菜品数据
    await _loadDishesFromApi();
    
    // 等待菜品数据加载完成后再加载购物车
    if (dishes.isNotEmpty) {
      await _loadCartFromApi();
    } else {
      logDebug('⚠️ 菜品数据未加载完成，延迟加载购物车', tag: OrderConstants.logTag);
      Future.delayed(Duration(milliseconds: 1000), () {
        if (dishes.isNotEmpty) {
          _loadCartFromApi();
        }
      });
    }
    
    // 强制刷新UI以确保显示更新
    Future.delayed(Duration(milliseconds: OrderConstants.uiRefreshDelayMs), () {
      cart.refresh();
      update();
      logDebug('🔄 初始化后延迟刷新UI，确保购物车显示更新', tag: OrderConstants.logTag);
    });
    
    // 标记初始化完成
    isInitialized.value = true;
    logDebug('✅ 菜品和购物车数据加载完成，初始化标记已设置', tag: OrderConstants.logTag);
  }

  /// 从API加载购物车数据
  Future<void> _loadCartFromApi({int retryCount = 0, bool silent = false}) async {
    if (table.value?.tableId == null) {
      logDebug('❌ 桌台ID为空，无法加载购物车数据', tag: OrderConstants.logTag);
      return;
    }
    
    if (isLoadingCart.value && !silent) {
      logDebug('⏳ 购物车数据正在加载中，跳过重复请求', tag: OrderConstants.logTag);
      return;
    }
    
    // 静默刷新时不设置loading状态，避免显示骨架图
    if (!silent) {
      isLoadingCart.value = true;
    }
    try {
      final tableId = table.value!.tableId.toString();
      final cartData = await _cartManager.loadCartFromApi(tableId);
      
      if (cartData != null) {
        cartInfo.value = cartData;
        _convertApiCartToLocalCart();
        
        // 如果购物车为空但本地有数据，可能是状态码210，延迟重试
        if ((cartInfo.value?.items == null || cartInfo.value!.items!.isEmpty) && cart.isNotEmpty && retryCount < 2) {
          logDebug('⚠️ 购物车数据可能不稳定，2秒后重试 (${retryCount + 1}/2)', tag: OrderConstants.logTag);
          Future.delayed(Duration(seconds: 2), () {
            if (isLoadingCart.value == false) {
              _loadCartFromApi(retryCount: retryCount + 1, silent: silent);
            }
          });
        }
      } else {
        logDebug('🛒 购物车API返回空数据，保留本地购物车', tag: OrderConstants.logTag);
        // 状态码210时，保留本地购物车数据，不进行任何操作
      }
    } catch (e) {
      logDebug('❌ 购物车数据加载异常: $e', tag: OrderConstants.logTag);
    } finally {
      // 静默刷新时不重置loading状态
      if (!silent) {
        isLoadingCart.value = false;
      }
    }
  }

  /// 将API购物车数据转换为本地购物车格式
  void _convertApiCartToLocalCart() {
    if (cartInfo.value?.items == null || cartInfo.value!.items!.isEmpty) {
      // 服务器购物车为空，但只在非初始化时清空本地购物车
      // 初始化时保留本地购物车数据，避免角标闪烁
      if (isInitialized.value) {
        logDebug('🛒 服务器购物车为空，清空本地购物车', tag: OrderConstants.logTag);
        cart.clear();
        cart.refresh();
        update();
      } else {
        logDebug('🛒 初始化时服务器购物车为空，保留本地购物车数据', tag: OrderConstants.logTag);
      }
      return;
    }
    
    // 确保菜品数据已加载
    if (dishes.isEmpty) {
      logDebug('⚠️ 菜品数据未加载完成，延迟转换购物车', tag: OrderConstants.logTag);
      Future.delayed(Duration(milliseconds: 500), () {
        if (dishes.isNotEmpty) {
          _convertApiCartToLocalCart();
        }
      });
      return;
    }
    
    final newCart = _cartManager.convertApiCartToLocalCart(
      cartInfo: cartInfo.value,
      dishes: dishes,
      categories: categories,
    );
    
    // 更新购物车
    cart.clear();
    cart.addAll(newCart);
    cart.refresh();
    update();
    logDebug('✅ 购物车数据已更新: ${cart.length} 种商品', tag: OrderConstants.logTag);
    
    // 强制刷新UI以确保显示更新
    Future.delayed(Duration(milliseconds: 100), () {
      cart.refresh();
      update();
      logDebug('🔄 延迟刷新UI，确保购物车显示更新', tag: OrderConstants.logTag);
    });
  }

  /// 从API获取菜品数据
  Future<void> _loadDishesFromApi() async {
    if (menu.value == null) {
      logDebug('❌ 没有菜单信息，无法获取菜品数据', tag: OrderConstants.logTag);
      return;
    }

    try {
      isLoadingDishes.value = true;
      logDebug('🔄 开始从API获取菜品数据...', tag: OrderConstants.logTag);
      
      final result = await _api.getMenudDishList(
        tableID: table.value?.tableId.toString(),
        menuId: menu.value!.menuId.toString(),
      );
      
      if (result.isSuccess && result.data != null) {
        logDebug('✅ 成功获取菜品数据，类目数量: ${result.data!.length}', tag: OrderConstants.logTag);
        _loadDishesFromData(result.data!);
      } else {
        logDebug('❌ 获取菜品数据失败: ${result.msg}', tag: OrderConstants.logTag);
        GlobalToast.error(result.msg ?? '获取菜品数据失败');
      }
    } catch (e) {
      logDebug('❌ 获取菜品数据异常: $e', tag: OrderConstants.logTag);
      GlobalToast.error('获取菜品数据异常');
    } finally {
      isLoadingDishes.value = false;
    }
  }

  /// 从数据加载菜品
  void _loadDishesFromData(List<DishListModel> dishListModels) {
    logDebug('🔄 开始加载菜品数据...', tag: OrderConstants.logTag);
    
    DataConverter.loadDishesFromData(
      dishListModels: dishListModels,
      categories: categories,
      dishes: dishes,
    );
    
    // 强制刷新UI
    categories.refresh();
    dishes.refresh();
  }

  // ========== 购物车操作 ==========

  void clearCart() {
    _cartManager.debounceOperation('clear_cart', () {
      cart.clear();
      update();
      _wsHandler.sendClearCart();
      logDebug('🧹 购物车已清空', tag: OrderConstants.logTag);
    }, milliseconds: OrderConstants.cartDebounceTimeMs);
  }

  void addToCart(Dish dish, {Map<String, List<String>>? selectedOptions}) {
    logDebug('📤 发送添加菜品请求: ${dish.name}', tag: OrderConstants.logTag);
    logDebug('  规格选项: $selectedOptions', tag: OrderConstants.logTag);
    logDebug('  当前购物车项数: ${cart.length}', tag: OrderConstants.logTag);
    
    // 查找是否已存在相同的购物车项
    CartItem? existingCartItem;
    for (var entry in cart.entries) {
      logDebug('  检查购物车项: ${entry.key.dish.name}, 规格: ${entry.key.selectedOptions}', tag: OrderConstants.logTag);
      if (entry.key.dish.id == dish.id && 
          _areOptionsEqual(entry.key.selectedOptions, selectedOptions ?? {})) {
        existingCartItem = entry.key;
        logDebug('  找到相同的购物车项: ${entry.key.dish.name}', tag: OrderConstants.logTag);
        break;
      }
    }
    
    if (existingCartItem != null) {
      // 如果已存在，使用本地购物车管理器增加数量
      final currentQuantity = cart[existingCartItem]!;
      final newQuantity = currentQuantity + 1;
      logDebug('  当前数量: $currentQuantity', tag: OrderConstants.logTag);
      
      // 保存操作上下文，用于可能的409强制更新
      _lastOperationCartItem = existingCartItem;
      _lastOperationQuantity = newQuantity;
      
      _localCartManager.addDishQuantity(existingCartItem, currentQuantity);
      logDebug('➕ 本地增加已存在菜品数量: ${dish.name}', tag: OrderConstants.logTag);
    } else {
      // 如果不存在，创建新的购物车项并添加到本地购物车
      final newCartItem = CartItem(
        dish: dish,
        selectedOptions: selectedOptions ?? {},
        cartSpecificationId: null, // 服务器会返回
        cartItemId: null, // 服务器会返回
        cartId: null, // 服务器会返回
      );
      
      // 保存操作上下文，用于可能的409强制更新
      _lastOperationCartItem = newCartItem;
      _lastOperationQuantity = 1;
      
      // 立即添加到本地购物车
      cart[newCartItem] = 1;
      cart.refresh();
      update();
      
      // 直接发送WebSocket添加消息（不通过LocalCartManager）
      _sendAddDishWebSocket(dish, selectedOptions);
      
      logDebug('➕ 本地添加新菜品: ${dish.name}', tag: OrderConstants.logTag);
    }
  }

  /// 添加指定数量的菜品到购物车（用于选规格弹窗）
  void addToCartWithQuantity(Dish dish, {required int quantity, Map<String, List<String>>? selectedOptions}) {
    logDebug('📤 发送添加指定数量菜品请求: ${dish.name} x$quantity', tag: OrderConstants.logTag);
    logDebug('  规格选项: $selectedOptions', tag: OrderConstants.logTag);
    logDebug('  当前购物车项数: ${cart.length}', tag: OrderConstants.logTag);
    
    // 查找是否已存在相同的购物车项
    CartItem? existingCartItem;
    for (var entry in cart.entries) {
      logDebug('  检查购物车项: ${entry.key.dish.name}, 规格: ${entry.key.selectedOptions}', tag: OrderConstants.logTag);
      if (entry.key.dish.id == dish.id && 
          _areOptionsEqual(entry.key.selectedOptions, selectedOptions ?? {})) {
        existingCartItem = entry.key;
        logDebug('  找到相同的购物车项: ${entry.key.dish.name}', tag: OrderConstants.logTag);
        break;
      }
    }
    
    if (existingCartItem != null) {
      // 如果已存在，直接增加指定数量
      final currentQuantity = cart[existingCartItem]!;
      final newQuantity = currentQuantity + quantity;
      logDebug('  当前数量: $currentQuantity, 增加数量: $quantity, 新数量: $newQuantity', tag: OrderConstants.logTag);
      
      // 保存操作上下文，用于可能的409强制更新
      _lastOperationCartItem = existingCartItem;
      _lastOperationQuantity = newQuantity;
      
      // 立即更新本地购物车状态
      cart[existingCartItem] = newQuantity;
      cart.refresh();
      update();
      
      // 发送WebSocket消息
      _sendAddDishWebSocketWithQuantity(dish, quantity, selectedOptions);
      
      logDebug('➕ 本地增加已存在菜品数量: ${dish.name} +$quantity = $newQuantity', tag: OrderConstants.logTag);
    } else {
      // 如果不存在，创建新的购物车项并添加到本地购物车
      final newCartItem = CartItem(
        dish: dish,
        selectedOptions: selectedOptions ?? {},
        cartSpecificationId: null, // 服务器会返回
        cartItemId: null, // 服务器会返回
        cartId: null, // 服务器会返回
      );
      
      // 保存操作上下文，用于可能的409强制更新
      _lastOperationCartItem = newCartItem;
      _lastOperationQuantity = quantity;
      
      // 立即添加到本地购物车
      cart[newCartItem] = quantity;
      cart.refresh();
      update();
      
      // 发送WebSocket消息
      _sendAddDishWebSocketWithQuantity(dish, quantity, selectedOptions);
      
      logDebug('➕ 本地添加新菜品: ${dish.name} x$quantity', tag: OrderConstants.logTag);
    }
  }
  
  /// 发送添加指定数量菜品的WebSocket消息
  Future<void> _sendAddDishWebSocketWithQuantity(Dish dish, int quantity, Map<String, List<String>>? selectedOptions) async {
    try {
      logDebug('🆕 发送WebSocket添加指定数量菜品: ${dish.name} x$quantity', tag: OrderConstants.logTag);
      
      // 构建规格选项数据
      List<Map<String, dynamic>> optionsData = [];
      if (selectedOptions != null && selectedOptions.isNotEmpty) {
        selectedOptions.forEach((optionId, itemIds) {
          optionsData.add({
            'id': int.parse(optionId),
            'item_ids': itemIds.map((id) => int.parse(id)).toList(),
            'custom_values': <String>[],
          });
        });
      }
      
      // 发送WebSocket消息
      final success = await _wsHandler.sendAddDish(
        dish: dish,
        quantity: quantity,
        selectedOptions: selectedOptions,
      );
      
      if (success) {
        logDebug('✅ WebSocket添加指定数量菜品成功: ${dish.name} x$quantity', tag: OrderConstants.logTag);
      } else {
        logDebug('❌ WebSocket添加指定数量菜品失败: ${dish.name} x$quantity', tag: OrderConstants.logTag);
      }
    } catch (e) {
      logDebug('❌ 发送WebSocket添加指定数量菜品异常: $e', tag: OrderConstants.logTag);
    }
  }

  /// 发送添加菜品的WebSocket消息
  Future<void> _sendAddDishWebSocket(Dish dish, Map<String, List<String>>? selectedOptions) async {
    try {
      logDebug('🆕 发送WebSocket添加菜品: ${dish.name}', tag: OrderConstants.logTag);
      
      final success = await _wsHandler.sendAddDish(
        dish: dish,
        quantity: 1,
        selectedOptions: selectedOptions,
      );
      
      if (success) {
        logDebug('✅ WebSocket添加菜品成功: ${dish.name}', tag: OrderConstants.logTag);
        // WebSocket发送成功，等待服务器确认
        // 服务器会通过cart_add消息通知我们，然后我们会在_loadCartFromApi中获取完整的购物车数据
      } else {
        logDebug('❌ WebSocket添加菜品失败: ${dish.name}', tag: OrderConstants.logTag);
        // WebSocket失败，显示错误提示
        GlobalToast.error('添加菜品失败，请重试');
      }
    } catch (e) {
      logDebug('❌ 发送WebSocket添加菜品异常: $e', tag: OrderConstants.logTag);
      GlobalToast.error('添加菜品异常，请重试');
    }
  }

  void removeFromCart(dynamic item) {
    if (item is CartItem) {
      _removeCartItem(item);
    } else if (item is Dish) {
      _removeDishFromCart(item);
    }
  }

  void _removeCartItem(CartItem cartItem) {
    if (!cart.containsKey(cartItem)) return;
    
    // 开始loading状态
    isCartOperationLoading.value = true;
    
    final currentQuantity = cart[cartItem]!;
    final newQuantity = currentQuantity - 1;
    
    // 保存操作上下文，用于可能的409强制更新
    _lastOperationCartItem = cartItem;
    _lastOperationQuantity = newQuantity;
    
    // 使用本地购物车管理器进行本地优先的增减操作
    _localCartManager.removeDishQuantity(cartItem, currentQuantity);
    
    logDebug('➖ 本地减少购物车项数量: ${cartItem.dish.name}', tag: OrderConstants.logTag);
    
    // 检查WebSocket连接状态
    if (!isWebSocketConnected.value) {
      logDebug('⚠️ WebSocket未连接，无法同步减少操作', tag: OrderConstants.logTag);
      GlobalToast.warning('网络连接异常，操作可能未同步到服务器');
      isCartOperationLoading.value = false;
      return;
    }
    
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 减少的菜品缺少ID，无法同步到WebSocket: ${cartItem.dish.name}', tag: OrderConstants.logTag);
      isCartOperationLoading.value = false;
      return;
    }
    
    // 同步到WebSocket
    _wsHandler.sendUpdateQuantity(cartItem: cartItem, quantity: newQuantity).then((success) {
      if (success) {
        logDebug('✅ 减少菜品数量同步到WebSocket成功: ${cartItem.dish.name}', tag: OrderConstants.logTag);
      } else {
        logDebug('❌ 减少菜品数量同步到WebSocket失败', tag: OrderConstants.logTag);
        GlobalToast.error('减少菜品失败，请重试');
      }
      isCartOperationLoading.value = false;
    }).catchError((error) {
      logDebug('❌ 减少菜品数量同步到WebSocket异常: $error', tag: OrderConstants.logTag);
      GlobalToast.error('减少菜品异常，请重试');
      isCartOperationLoading.value = false;
    });
  }

  void deleteCartItem(CartItem cartItem) {
    if (!cart.containsKey(cartItem)) return;
    
    // 开始loading状态
    isCartOperationLoading.value = true;
    
    // 保存操作上下文，用于可能的409强制更新
    _lastOperationCartItem = cartItem;
    _lastOperationQuantity = 0; // 删除操作的目标数量为0
    
    // 从本地购物车中移除
    cart.remove(cartItem);
    cart.refresh();
    update();
    
    // 检查WebSocket连接状态
    if (!isWebSocketConnected.value) {
      logDebug('⚠️ WebSocket未连接，无法同步删除操作', tag: OrderConstants.logTag);
      GlobalToast.warning('网络连接异常，删除操作可能未同步到服务器');
      isCartOperationLoading.value = false;
      return;
    }
    
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 删除的菜品缺少ID，无法同步到WebSocket: ${cartItem.dish.name}', tag: OrderConstants.logTag);
      isCartOperationLoading.value = false;
      return;
    }
    
    // 同步到WebSocket
    _wsHandler.sendDeleteDish(cartItem).then((success) {
      if (success) {
        logDebug('✅ 删除菜品同步到WebSocket成功: ${cartItem.dish.name}', tag: OrderConstants.logTag);
      } else {
        logDebug('❌ 删除菜品同步到WebSocket失败', tag: OrderConstants.logTag);
        GlobalToast.error('删除菜品失败，请重试');
      }
      isCartOperationLoading.value = false;
    }).catchError((error) {
      logDebug('❌ 删除菜品同步到WebSocket异常: $error', tag: OrderConstants.logTag);
      GlobalToast.error('删除菜品异常，请重试');
      isCartOperationLoading.value = false;
    });
    
    logDebug('🗑️ 完全删除购物车项: ${cartItem.dish.name}', tag: OrderConstants.logTag);
  }

  void addCartItemQuantity(CartItem cartItem) {
    if (!cart.containsKey(cartItem)) return;
    
    // 开始loading状态
    isCartOperationLoading.value = true;
    
    final currentQuantity = cart[cartItem]!;
    final newQuantity = currentQuantity + 1;
    
    // 保存操作上下文，用于可能的409强制更新
    _lastOperationCartItem = cartItem;
    _lastOperationQuantity = newQuantity;
    
    // 使用本地购物车管理器进行本地优先的增减操作
    _localCartManager.addDishQuantity(cartItem, currentQuantity);
    
    logDebug('➕ 本地增加购物车项数量: ${cartItem.dish.name}', tag: OrderConstants.logTag);
    
    // 检查WebSocket连接状态
    if (!isWebSocketConnected.value) {
      logDebug('⚠️ WebSocket未连接，无法同步增加操作', tag: OrderConstants.logTag);
      GlobalToast.warning('网络连接异常，操作可能未同步到服务器');
      isCartOperationLoading.value = false;
      return;
    }
    
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 增加的菜品缺少ID，无法同步到WebSocket: ${cartItem.dish.name}', tag: OrderConstants.logTag);
      isCartOperationLoading.value = false;
      return;
    }
    
    // 同步到WebSocket
    _wsHandler.sendUpdateQuantity(cartItem: cartItem, quantity: newQuantity).then((success) {
      if (success) {
        logDebug('✅ 增加菜品数量同步到WebSocket成功: ${cartItem.dish.name}', tag: OrderConstants.logTag);
      } else {
        logDebug('❌ 增加菜品数量同步到WebSocket失败', tag: OrderConstants.logTag);
        GlobalToast.error('增加菜品失败，请重试');
      }
      isCartOperationLoading.value = false;
    }).catchError((error) {
      logDebug('❌ 增加菜品数量同步到WebSocket异常: $error', tag: OrderConstants.logTag);
      GlobalToast.error('增加菜品异常，请重试');
      isCartOperationLoading.value = false;
    });
  }

  /// 手动更新购物车项数量
  Future<void> updateCartItemQuantity({
    required CartItem cartItem,
    required int newQuantity,
    required VoidCallback onSuccess,
    required Function(int code, String message) onError,
  }) async {
    if (!cart.containsKey(cartItem)) {
      onError(404, '购物车项不存在');
      return;
    }

    if (newQuantity < 0) {
      onError(400, '数量不能为负数');
      return;
    }

    if (newQuantity == 0) {
      // 数量为0，删除商品
      deleteCartItem(cartItem);
      onSuccess();
      return;
    }

    final oldQuantity = cart[cartItem]!;
    if (oldQuantity == newQuantity) {
      onSuccess();
      return;
    }

    // 保存操作上下文，用于可能的409强制更新
    _lastOperationCartItem = cartItem;
    _lastOperationQuantity = newQuantity;
    
    // 使用本地购物车管理器进行本地优先的数量设置
    _localCartManager.setDishQuantity(cartItem, newQuantity);
    
    onSuccess();
    logDebug('🔄 本地设置购物车项数量: ${cartItem.dish.name} -> $newQuantity', tag: OrderConstants.logTag);
  }



  void _removeDishFromCart(Dish dish) {
    CartItem? targetCartItem;
    
    // 首先查找无规格的版本
    for (var entry in cart.entries) {
      if (entry.key.dish.id == dish.id && entry.key.selectedOptions.isEmpty) {
        targetCartItem = entry.key;
        break;
      }
    }
    
    // 如果没有找到无规格的，就选择第一个匹配的
    if (targetCartItem == null) {
      for (var entry in cart.entries) {
        if (entry.key.dish.id == dish.id) {
          targetCartItem = entry.key;
          break;
        }
      }
    }
    
    if (targetCartItem != null) {
      _removeCartItem(targetCartItem);
    }
  }

  /// 比较两个选项映射是否相等
  bool _areOptionsEqual(Map<String, List<String>> options1, Map<String, List<String>> options2) {
    if (options1.length != options2.length) return false;
    
    for (var key in options1.keys) {
      if (!options2.containsKey(key)) return false;
      
      final list1 = options1[key]!;
      final list2 = options2[key]!;
      
      if (list1.length != list2.length) return false;
      
      // 对列表进行排序后比较
      final sortedList1 = List<String>.from(list1)..sort();
      final sortedList2 = List<String>.from(list2)..sort();
      
      for (int i = 0; i < sortedList1.length; i++) {
        if (sortedList1[i] != sortedList2[i]) return false;
      }
    }
    
    return true;
  }

  // ========== 数据获取方法 ==========

  List<Dish> get filteredDishes {
    var list = dishes.where((d) {
      // 搜索关键词筛选
      if (searchKeyword.value.isNotEmpty) {
        final keyword = searchKeyword.value.toLowerCase();
        final dishName = d.name.toLowerCase();
        final pinyin = DataConverter.getPinyinInitials(d.name);
        
        if (!dishName.contains(keyword) && !pinyin.contains(keyword)) {
          return false;
        }
      }
      
      // 敏感物筛选
      if (selectedAllergens.isNotEmpty && d.allergens != null) {
        for (var allergen in d.allergens!) {
          if (selectedAllergens.contains(allergen.id)) {
            return false;
          }
        }
      }
      
      return true;
    }).toList();

    switch (sortType.value) {
      case SortType.priceAsc:
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case SortType.priceDesc:
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        break;
    }
    return list;
  }

  int get totalCount => cart.values.fold(0, (sum, e) => sum + e);
  double get totalPrice => cart.entries.fold(0.0, (sum, e) => sum + e.key.dish.price * e.value);

  int getCategoryCount(int categoryIndex) {
    int count = 0;
    cart.forEach((cartItem, quantity) {
      if (cartItem.dish.categoryId == categoryIndex) {
        count += quantity;
      }
    });
    return count;
  }

  String getTableDisplayText() {
    return DataConverter.buildTableDisplayText(
      tableName: table.value?.tableName,
      adultCount: adultCount.value,
      childCount: childCount.value,
    );
  }

  List<String> get selectedAllergenNames {
    return DataConverter.buildSelectedAllergenNames(
      selectedAllergens: selectedAllergens,
      allAllergens: allAllergens,
    );
  }

  // ========== 敏感物相关 ==========

  void toggleAllergen(int allergenId) {
    if (selectedAllergens.contains(allergenId)) {
      selectedAllergens.remove(allergenId);
    } else {
      selectedAllergens.add(allergenId);
    }
    selectedAllergens.refresh();
  }

  void clearAllergenSelection() {
    selectedAllergens.clear();
    selectedAllergens.refresh();
  }

  Future<void> loadAllergens() async {
    if (isLoadingAllergens.value) return;
    
    isLoadingAllergens.value = true;
    try {
      final result = await HttpManagerN.instance.executeGet(OrderConstants.allergensApiPath);
      
      if (result.isSuccess) {
        final data = _extractAllergensData(result.dataJson);
        if (data is List) {
          allAllergens.value = data.map<Allergen>((item) => Allergen.fromJson(item as Map<String, dynamic>)).toList();
          logDebug('✅ 敏感物数据加载成功: ${allAllergens.length} 个', tag: OrderConstants.logTag);
        }
      }
    } catch (e) {
      logDebug('❌ 敏感物数据加载异常: $e', tag: OrderConstants.logTag);
    } finally {
      isLoadingAllergens.value = false;
    }
  }

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

  // ========== 搜索相关 ==========

  void showSearchBox() {
    isSearchVisible.value = true;
  }

  void hideSearchBox() {
    isSearchVisible.value = false;
    searchKeyword.value = '';
  }

  // ========== 敏感物弹窗相关 ==========

  void toggleTempAllergen(int allergenId) {
    if (tempSelectedAllergens.contains(allergenId)) {
      tempSelectedAllergens.remove(allergenId);
    } else {
      tempSelectedAllergens.add(allergenId);
    }
    tempSelectedAllergens.refresh();
  }

  void confirmAllergenSelection() {
    selectedAllergens.value = List.from(tempSelectedAllergens);
    selectedAllergens.refresh();
  }

  void cancelAllergenSelection() {
    tempSelectedAllergens.value = List.from(selectedAllergens);
    tempSelectedAllergens.refresh();
  }

  void clearAllAllergenData() {
    selectedAllergens.clear();
    tempSelectedAllergens.clear();
    allAllergens.clear();
    selectedAllergens.refresh();
    tempSelectedAllergens.refresh();
    allAllergens.refresh();
    logDebug('🧹 已清空所有敏感物筛选和缓存', tag: OrderConstants.logTag);
  }


  // ========== 本地购物车管理器回调 ==========

  /// 本地数量变化回调
  void _onLocalQuantityChanged(CartItem cartItem, int quantity) {
    logDebug('🔍 _onLocalQuantityChanged 调试信息:', tag: OrderConstants.logTag);
    logDebug('  菜品: ${cartItem.dish.name}', tag: OrderConstants.logTag);
    logDebug('  新数量: $quantity', tag: OrderConstants.logTag);
    logDebug('  规格选项: ${cartItem.selectedOptions}', tag: OrderConstants.logTag);
    logDebug('  更新前购物车项数: ${cart.length}', tag: OrderConstants.logTag);
    
    // 立即更新本地购物车状态
    if (quantity > 0) {
      cart[cartItem] = quantity;
    } else {
      cart.remove(cartItem);
    }
    cart.refresh();
    update();
    
    logDebug('  更新后购物车项数: ${cart.length}', tag: OrderConstants.logTag);
    logDebug('🔄 本地数量变化: ${cartItem.dish.name} -> $quantity', tag: OrderConstants.logTag);
  }

  /// 本地WebSocket发送回调
  void _onLocalWebSocketSend(CartItem cartItem, int quantity) {
    // 检查是否有必要的ID
    if (cartItem.cartSpecificationId == null || cartItem.cartId == null) {
      logDebug('⚠️ 新菜品缺少ID，跳过WebSocket同步: ${cartItem.dish.name}', tag: OrderConstants.logTag);
      // 对于新菜品，应该通过addToCart方法处理，这里不应该被调用
      return;
    }
    
    // 使用WebSocket防抖管理器发送消息
    if (quantity > 0) {
      _wsDebounceManager.debounceUpdateQuantity(
        cartItem: cartItem,
        quantity: quantity,
      );
    } else {
      // 数量为0，发送删除消息
      _wsHandler.sendDeleteDish(cartItem);
    }
    
    logDebug('📤 本地WebSocket发送: ${cartItem.dish.name} -> $quantity', tag: OrderConstants.logTag);
  }

  /// 本地WebSocket失败回调
  void _onLocalWebSocketFailed(CartItem cartItem, int originalQuantity) {
    // 本地购物车管理器已经处理了数量回滚，这里只需要记录日志
    logDebug('❌ 本地WebSocket失败，已回滚: ${cartItem.dish.name} -> $originalQuantity', tag: OrderConstants.logTag);
  }

  /// WebSocket防抖失败回调
  void _onWebSocketDebounceFailed(CartItem cartItem, int quantity) {
    // 通知本地购物车管理器处理失败
    _localCartManager.handleWebSocketFailure(cartItem);
    logDebug('❌ WebSocket防抖失败，已回滚: ${cartItem.dish.name}', tag: OrderConstants.logTag);
  }

  // ========== WebSocket消息处理 ==========

  void _handleCartRefresh() {
    logDebug('🔄 收到服务器刷新购物车消息', tag: OrderConstants.logTag);
    _loadCartFromApi(silent: true);
  }

  void _handleCartAdd() {
    logDebug('➕ 收到服务器购物车添加消息', tag: OrderConstants.logTag);
    // 停止loading状态
    isCartOperationLoading.value = false;
  }

  void _handleCartUpdate() {
    logDebug('🔄 收到服务器购物车更新消息', tag: OrderConstants.logTag);
    // 停止loading状态
    isCartOperationLoading.value = false;
  }

  void _handleCartDelete() {
    logDebug('🗑️ 收到服务器购物车删除消息', tag: OrderConstants.logTag);
    // 停止loading状态
    isCartOperationLoading.value = false;
    _cartManager.refreshCartFromServer(() => _loadCartFromApi(silent: true));
  }

  void _handleCartClear() {
    logDebug('🧹 收到服务器购物车清空消息', tag: OrderConstants.logTag);
    // 停止loading状态
    isCartOperationLoading.value = false;
    _cartManager.refreshCartFromServer(() => _loadCartFromApi(silent: true));
  }

  void _handleOrderRefresh() {
    logDebug('🔄 收到服务器刷新已点订单消息', tag: OrderConstants.logTag);
    logDebug('🔄 当前loading状态: ${isLoadingOrdered.value}', tag: OrderConstants.logTag);
    // WebSocket刷新已点订单时，静默刷新（不显示loading）
    loadCurrentOrder(showLoading: false);
  }

  void _handlePeopleCountChange(int adultCount, int childCount) {
    logDebug('👥 收到服务器修改人数消息: 成人$adultCount, 儿童$childCount', tag: OrderConstants.logTag);
    _updatePeopleCountViaApi(adultCount, childCount);
  }

  void _handleMenuChange(int menuId) {
    logDebug('📋 收到服务器修改菜单消息: $menuId', tag: OrderConstants.logTag);
    _updateMenuById(menuId);
  }

  void _handleTableChange(String tableName) {
    logDebug('🔄 收到服务器更换桌子消息: $tableName', tag: OrderConstants.logTag);
    _updateTableName(tableName);
  }


  // ========== API调用 ==========

  Future<void> _updatePeopleCountViaApi(int adultCount, int childCount) async {
    try {
      final tableId = table.value?.tableId.toInt();
      if (tableId == null) return;

      final result = await _api.changePeopleCount(
        tableId: tableId,
        adultCount: adultCount,
        childCount: childCount,
      );

      if (result.isSuccess) {
        this.adultCount.value = adultCount;
        this.childCount.value = childCount;
        logDebug('✅ 人数更新成功', tag: OrderConstants.logTag);
      } else {
        _errorHandler.handleApiError('人数更新', result.msg ?? '未知错误');
      }
    } catch (e) {
      _errorHandler.handleException('人数更新', e);
    }
  }

  Future<void> _updateMenuById(int menuId) async {
    try {
      if (menu.value?.menuId == menuId) {
        await _loadDishesAndCart();
        return;
      }
      
      final result = await _api.getTableMenuList();
      if (result.isSuccess && result.data != null) {
        final targetMenu = result.data!.firstWhere(
          (menu) => menu.menuId == menuId,
          orElse: () => result.data!.first,
        );
        
        menu.value = targetMenu;
        await _loadDishesAndCart();
        logDebug('✅ 菜单信息已更新: ${targetMenu.menuName}', tag: OrderConstants.logTag);
      }
    } catch (e) {
      _errorHandler.handleException('菜单更新', e);
    }
  }

  void _updateTableName(String tableName) {
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

  /// 处理强制更新需求（409状态码）
  void _handleForceUpdateRequired(String message, Map<String, dynamic>? data) {
    logDebug('⚠️ 处理409状态码，显示强制更新确认弹窗: $message', tag: OrderConstants.logTag);
    logDebug('📋 收到的完整409数据: $data', tag: OrderConstants.logTag);
    
    
    // 获取当前上下文
    final context = Get.context;
    if (context != null) {
      // 使用ModalUtils显示确认弹窗
      ModalUtils.showConfirmDialog(
        context: context,
        title: '操作确认',
        message: message,
        confirmText: '确认',
        cancelText: '取消',
        confirmColor: const Color(0xFFFF8C00),
        onConfirm: () {
          logDebug('✅ 用户确认409强制更新', tag: OrderConstants.logTag);
          _performForceUpdate();
        },
        onCancel: () {
          logDebug('❌ 用户取消强制更新', tag: OrderConstants.logTag);
        },
      );
    } else {
      logDebug('❌ 无法获取上下文，无法显示强制更新弹窗', tag: OrderConstants.logTag);
    }
  }

  /// 执行强制更新操作
  void _performForceUpdate() {
    logDebug('🔄 执行强制更新操作', tag: OrderConstants.logTag);
    
    try {
      // 使用保存的操作上下文
      if (_lastOperationCartItem != null && _lastOperationQuantity != null) {
        final cartItem = _lastOperationCartItem!;
        final quantity = _lastOperationQuantity!;
        
        logDebug('✅ 使用保存的操作上下文执行强制更新: ${cartItem.dish.name}, quantity=$quantity', tag: OrderConstants.logTag);
        logDebug('📋 购物车项详情: cartId=${cartItem.cartId}, cartSpecificationId=${cartItem.cartSpecificationId}', tag: OrderConstants.logTag);
        
        // 检查是否有cartId和cartSpecificationId
        if (cartItem.cartId != null && cartItem.cartSpecificationId != null) {
          // 有完整的购物车项信息，使用sendUpdateQuantity
          _wsHandler.sendUpdateQuantity(
            cartItem: cartItem,
            quantity: quantity,
            forceOperate: true,
          );
        } else {
          // 没有购物车项信息，可能是添加操作，使用sendAddDish
          logDebug('🔄 使用sendAddDish执行强制添加操作', tag: OrderConstants.logTag);
          _wsHandler.sendAddDish(
            dish: cartItem.dish,
            quantity: quantity,
            selectedOptions: cartItem.selectedOptions,
            forceOperate: true,
          );
        }
        
        // 强制更新成功后清理数据
        _lastOperationCartItem = null;
        _lastOperationQuantity = null;
        logDebug('✅ 强制更新操作完成，已清理操作上下文', tag: OrderConstants.logTag);
      } else {
        logDebug('❌ 没有保存的操作上下文，无法执行强制更新', tag: OrderConstants.logTag);
        logDebug('💡 _lastOperationCartItem=$_lastOperationCartItem, _lastOperationQuantity=$_lastOperationQuantity', tag: OrderConstants.logTag);
        
      }
    } catch (e) {
      logDebug('❌ 执行强制更新操作异常: $e', tag: OrderConstants.logTag);
      
      // 异常时也要清理数据
      _lastOperationCartItem = null;
      _lastOperationQuantity = null;
    }
  }

  // ========== 公开方法 ==========

  Future<void> refreshOrderData() async {
    logDebug('🔄 开始刷新点餐页面数据...', tag: OrderConstants.logTag);
    await _loadDishesFromApi();
    logDebug('✅ 点餐页面数据刷新完成', tag: OrderConstants.logTag);
  }

  Future<void> forceRefreshCart({bool silent = false}) async {
    logDebug('🔄 强制刷新购物车数据', tag: OrderConstants.logTag);
    await _loadCartFromApi(silent: silent);
  }
  
  void forceRefreshCartUI() {
    logDebug('🔄 强制刷新购物车UI', tag: OrderConstants.logTag);
    cart.refresh();
    update();
    Future.delayed(Duration(milliseconds: 100), () {
      cart.refresh();
      update();
    });
  }

  @override
  void onReady() {
    super.onReady();
    Future.delayed(Duration(milliseconds: 500), () {
      if (table.value?.tableId != null) {
        forceRefreshCart(silent: true).then((_) {
          cart.refresh();
          update();
        });
      }
    });
  }

  // ========== 已点订单相关方法 ==========

  /// 加载当前订单数据
  Future<void> loadCurrentOrder({int retryCount = 0, int maxRetries = 3, bool showRetryDialog = false, bool showLoading = true}) async {
    if (table.value?.tableId == null) {
      logDebug('❌ 桌台ID为空，无法加载已点订单', tag: OrderConstants.logTag);
      return;
    }

    try {
      if (showLoading) {
        isLoadingOrdered.value = true;
        logDebug('📋 设置loading状态为true', tag: OrderConstants.logTag);
      } else {
        logDebug('📋 静默刷新，不设置loading状态 (当前状态: ${isLoadingOrdered.value})', tag: OrderConstants.logTag);
      }
      logDebug('📋 开始加载已点订单数据... (重试次数: $retryCount, 显示loading: $showLoading)', tag: OrderConstants.logTag);

      final result = await _orderApi.getCurrentOrder(
        tableId: table.value!.tableId.toString(),
      );

      if (result.isSuccess && result.data != null) {
        currentOrder.value = result.data;
        logDebug('✅ 已点订单数据加载成功: ${result.data?.details?.length ?? 0}个订单', tag: OrderConstants.logTag);
      } else {
        // 检查是否是真正的空数据（没有订单）还是服务器处理中
        if (result.msg == '响应数据为空' || (result.code == 0 && result.msg == 'success' && result.data == null)) {
          // 这是真正的空数据，直接显示空状态，不重试
          logDebug('📭 当前桌台没有已点订单，显示空状态', tag: OrderConstants.logTag);
          currentOrder.value = null;
        } else if ((result.code == 210 || result.msg?.contains('数据处理中') == true) 
            && retryCount < maxRetries) {
          // 只有服务器明确表示数据处理中时才重试
          logDebug('⚠️ 数据可能还在处理中，${2}秒后重试... (${retryCount + 1}/$maxRetries)', tag: OrderConstants.logTag);
          
          // 延迟2秒后重试
          await Future.delayed(Duration(seconds: 2));
          return loadCurrentOrder(retryCount: retryCount + 1, maxRetries: maxRetries, showRetryDialog: showRetryDialog);
        } else {
          logDebug('❌ 已点订单数据加载失败: ${result.msg} (状态码: ${result.code})', tag: OrderConstants.logTag);
          currentOrder.value = null;
        }
      }
    } catch (e, stackTrace) {
      logDebug('❌ 已点订单数据加载异常: $e', tag: OrderConstants.logTag);
      logDebug('❌ StackTrace: $stackTrace', tag: OrderConstants.logTag);
      
      // 对于异常情况，如果还有重试机会，也进行重试
      if (retryCount < maxRetries && (e.toString().contains('null') || e.toString().contains('NoSuchMethodError'))) {
        logDebug('⚠️ 检测到空指针异常，${2}秒后重试... (${retryCount + 1}/$maxRetries)', tag: OrderConstants.logTag);
        await Future.delayed(Duration(seconds: 2));
        return loadCurrentOrder(retryCount: retryCount + 1, maxRetries: maxRetries, showRetryDialog: showRetryDialog);
      } else {
        currentOrder.value = null;
      }
    } finally {
      // 在以下情况下停止loading：
      // 1. 达到最大重试次数
      // 2. 有数据返回
      // 3. 确认是空数据（不需要重试）
      bool shouldStopLoading = retryCount >= maxRetries || 
                               currentOrder.value != null ||
                               (retryCount == 0); // 首次请求完成，无论结果如何都停止loading
      
      if (shouldStopLoading) {
        // 无论showLoading参数如何，都要确保loading状态被正确重置
        logDebug('📋 停止loading状态 (之前状态: ${isLoadingOrdered.value})', tag: OrderConstants.logTag);
        isLoadingOrdered.value = false;
      } else {
        logDebug('📋 继续loading状态，不停止 (重试次数: $retryCount)', tag: OrderConstants.logTag);
      }
    }
  }

  /// 提交订单
  Future<Map<String, dynamic>> submitOrder() async {
    if (table.value?.tableId == null) {
      logDebug('❌ 桌台ID为空，无法提交订单', tag: OrderConstants.logTag);
      return {
        'success': false,
        'message': '桌台ID为空，无法提交订单'
      };
    }

    try {
      logDebug('📤 开始提交订单...', tag: OrderConstants.logTag);

      final result = await _orderApi.submitOrder(
        tableId: table.value!.tableId.toInt(),
      );

      if (result.isSuccess) {
        logDebug('✅ 订单提交成功', tag: OrderConstants.logTag);
        
        // 设置标记，表示刚刚提交了订单
        justSubmittedOrder.value = true;
        
        // 等待1秒让服务器处理订单数据，然后刷新已点订单数据
        logDebug('⏳ 等待服务器处理订单数据...', tag: OrderConstants.logTag);
        await Future.delayed(Duration(seconds: 1));
        
        // 提交成功后刷新已点订单数据，使用重试机制
        await loadCurrentOrder(showLoading: false);
        
        // 刷新服务器购物车数据以确保同步
        logDebug('🔄 刷新服务器购物车数据以确保同步', tag: OrderConstants.logTag);
        await _loadCartFromApi(silent: true);
        
        return {
          'success': true,
          'message': '订单提交成功'
        };
      } else {
        logDebug('❌ 订单提交失败: ${result.msg}', tag: OrderConstants.logTag);
        return {
          'success': false,
          'message': result.msg ?? '订单提交失败'
        };
      }
    } catch (e, stackTrace) {
      logDebug('❌ 订单提交异常: $e', tag: OrderConstants.logTag);
      logDebug('❌ StackTrace: $stackTrace', tag: OrderConstants.logTag);
      return {
        'success': false,
        'message': '订单提交异常: $e'
      };
    }
  }

  // // ========== WebSocket回调处理方法 ==========

  // /// 处理菜单变更
  // void _handleMenuChange(int menuId) {
  //   logDebug('📋 收到菜单变更通知: $menuId', tag: OrderConstants.logTag);
  //   // TODO: 处理菜单变更逻辑
  // }

  // /// 处理桌台变更
  // void _handleTableChange(String tableName) {
  //   logDebug('📋 收到桌台变更通知: $tableName', tag: OrderConstants.logTag);
  //   // TODO: 处理桌台变更逻辑
  // }

  // /// 处理强制更新要求（409冲突）
  // void _handleForceUpdateRequired(String message, Map<String, dynamic>? data) {
  //   logDebug('⚠️ 收到强制更新要求: $message', tag: OrderConstants.logTag);
  //   logDebug('📦 强制更新数据: $data', tag: OrderConstants.logTag);
    
  //   _pendingForceUpdateData = data;
    
  //   // 获取当前上下文
  //   final context = Get.context;
  //   if (context != null) {
  //     // 显示强制更新确认弹窗
  //     ForceUpdateDialog.show(
  //       context,
  //       message: message,
  //       onConfirm: _performForceUpdate,
  //       onCancel: () {
  //         logDebug('❌ 用户取消强制更新', tag: OrderConstants.logTag);
  //         _pendingForceUpdateData = null;
  //         _lastOperationCartItem = null;
  //         _lastOperationQuantity = null;
  //       },
  //     );
  //   } else {
  //     logDebug('❌ 无法获取上下文，无法显示强制更新弹窗', tag: OrderConstants.logTag);
  //   }
  // }

  // /// 执行强制更新操作
  // void _performForceUpdate() {
  //   logDebug('🔄 执行强制更新操作', tag: OrderConstants.logTag);
    
  //   try {
  //     // 使用保存的操作上下文
  //     if (_lastOperationCartItem != null && _lastOperationQuantity != null) {
  //       final cartItem = _lastOperationCartItem!;
  //       final quantity = _lastOperationQuantity!;
        
  //       logDebug('✅ 使用保存的操作上下文执行强制更新: ${cartItem.dish.name}, quantity=$quantity', tag: OrderConstants.logTag);
  //       logDebug('📋 购物车项详情: cartId=${cartItem.cartId}, cartSpecificationId=${cartItem.cartSpecificationId}', tag: OrderConstants.logTag);
        
  //       // 使用现有的sendUpdateQuantity方法，设置forceOperate为true
  //       _wsHandler.sendUpdateQuantity(
  //         cartItem: cartItem,
  //         quantity: quantity,
  //         forceOperate: true,
  //       );
  //     } else {
  //       logDebug('❌ 没有保存的操作上下文，无法执行强制更新', tag: OrderConstants.logTag);
  //       logDebug('💡 _lastOperationCartItem=$_lastOperationCartItem, _lastOperationQuantity=$_lastOperationQuantity', tag: OrderConstants.logTag);
  //     }
  //   } catch (e) {
  //     logDebug('❌ 执行强制更新操作异常: $e', tag: OrderConstants.logTag);
  //   } finally {
  //     // 清理数据
  //     _pendingForceUpdateData = null;
  //     _lastOperationCartItem = null;
  //     _lastOperationQuantity = null;
  //   }
  // }

  @override
  void onClose() {
    logDebug('🔍 OrderController onClose 开始', tag: OrderConstants.logTag);
    
    // 清理WebSocket连接
    _wsHandler.dispose();
    _wsDebounceManager.dispose();
    _cartManager.dispose();
    
    // 清理所有WebSocket连接
    _wsLifecycleManager.cleanupAllConnections();
    
    logDebug('✅ OrderController onClose 完成，WebSocket连接已清理', tag: OrderConstants.logTag);
    super.onClose();
  }
}
