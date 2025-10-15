import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/utils/l10n_utils.dart';
import '../model/dish.dart';
import 'package:lib_domain/entrity/order/dish_list_model/dish_list_model.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_base/lib_base.dart';
import 'package:lib_domain/api/base_api.dart';
import 'package:lib_domain/entrity/cart/cart_info_model.dart';
import 'package:lib_domain/entrity/order/current_order_model.dart';
import 'package:lib_domain/api/order_api.dart';
import 'package:lib_domain/entrity/waiter/waiter_setting_model.dart';
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
import 'error_handler.dart';
import 'data_converter.dart';
import 'models.dart';
import '../services/cart_controller.dart';
import 'package:order_app/utils/image_cache_manager.dart';
import 'package:order_app/utils/cart_animation_registry.dart';

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
  final isCartOperationLoading = false.obs; // 购物车操作loading状态（兼容性保留）
  final justSubmittedOrder = false.obs; // 标记是否刚刚提交了订单
  
  /// 检查指定菜品是否正在loading
  bool isDishLoading(String dishId) {
    return _cartController.isDishLoading(dishId);
  }
  
  /// 检查指定菜品是否因14005错误而禁用增加按钮
  bool isDishAddDisabled(String dishId) {
    return _cartController.isDishAddDisabled(dishId);
  }
  final isInitialized = false.obs; // 标记是否已完成初始化

  // 从路由传递的数据
  var table = Rx<TableListModel?>(null);
  var menu = Rx<TableMenuListModel?>(null);
  var menuId = 0.obs; // 菜单ID，用于直接获取菜品数据
  var adultCount = 0.obs;
  var childCount = 0.obs;
  var source = "".obs; // 订单来源：table(桌台), takeaway(外卖)
  var remark = "".obs; // 外卖订单备注
  
  // 购物车数据
  var cartInfo = Rx<CartInfoModel?>(null);
  
  // 已点订单数据
  var currentOrder = Rx<CurrentOrderModel?>(null);
  final isLoadingOrdered = false.obs;
  final hasNetworkErrorOrdered = false.obs; // 已点订单网络错误状态
  
  // 通用loading和错误状态 - 为BaseListPageWidget提供接口
  RxBool get isLoading => isLoadingDishes;
  RxBool get hasNetworkError => hasNetworkErrorOrdered;
  
  // 409强制更新相关
  CartItem? _lastOperationCartItem;
  int? _lastOperationQuantity;
  
  // 当前正在处理的消息ID（用于强制更新）
  String? _currentProcessingMessageId;
  
  // WebSocket相关
  final WebSocketManager _wsManager = wsManager;
  final isWebSocketConnected = false.obs;
  final WebSocketLifecycleManager _wsLifecycleManager = WebSocketLifecycleManager();
  
  // 管理器
  late final WebSocketHandler _wsHandler;
  late final WebSocketDebounceManager _wsDebounceManager;
  late final CartManager _cartManager;
  late final ErrorHandler _errorHandler;
  
  // 购物车控制器组件
  late final CartController _cartController;
  
  // API服务
  final BaseApi _api = BaseApi();
  final OrderApi _orderApi = OrderApi();
  
  // 服务员设置
  final waiterSetting = WaiterSettingModel(confirmOrderBeforeSubmit: true).obs;
  

  @override
  void onInit() {
    super.onInit();
    logDebug('🔍 OrderController onInit 开始', tag: OrderConstants.logTag);
    
    // 设置页面类型为点餐页面
    _wsLifecycleManager.setCurrentPageType(WebSocketLifecycleManager.PAGE_ORDER);
    
    // 初始化管理器
    _initializeManagers();
    
    // 处理传递的参数并加载数据
    _processArgumentsAndLoadData();
    
    // WebSocket初始化将在桌台数据处理完成后进行
  }

  /// 初始化管理器
  void _initializeManagers() {
    _cartManager = CartManager(logTag: OrderConstants.logTag);
    _errorHandler = ErrorHandler(logTag: OrderConstants.logTag);
    
    // 初始化购物车控制器组件（不注册到Get）
    _cartController = CartController();
    _cartController.onInit(); // 手动调用初始化
    
    // 监听CartController的购物车状态变化，保持OrderController的cart同步
    ever(_cartController.cart, (Map<CartItem, int> newCart) {
      // 同步购物车状态到OrderController
      cart.clear();
      cart.addAll(newCart);
      cart.refresh();
      update();
      // logDebug('🔄 同步CartController购物车状态到OrderController: ${newCart.length}项', tag: OrderConstants.logTag);
    });
    
    
    // WebSocket处理器将在有tableId后初始化
  }

  /// 处理传递的参数并加载数据
  void _processArgumentsAndLoadData() {
    final args = Get.arguments as Map<String, dynamic>?;
    logDebug('📦 接收到的参数: $args', tag: OrderConstants.logTag);
    
    if (args != null) {
      _processTableData(args);
      _processMenuData(args);
      _processPeopleCount(args);
      _processSource(args);
    }
    
    // 参数处理完成后，加载设置、菜品和购物车数据
    _loadWaiterSetting();
    _loadDishesAndCart();
  }


  /// 处理桌台数据
  void _processTableData(Map<String, dynamic> args) {
    if (args['table'] != null) {
      final tableData = args['table'] as TableListModel;
      table.value = tableData;
      logDebug('✅ 桌台信息已设置: tableId=${tableData.tableId}, tableName=${tableData.tableName}, hallId=${tableData.hallId}', tag: OrderConstants.logTag);
      
      // 检查桌台ID是否有效
      if (tableData.tableId == 0) {
        logDebug('⚠️ 警告：桌台ID为0，这可能导致WebSocket连接失败', tag: OrderConstants.logTag);
      }
      
      // 桌台数据设置完成后，初始化WebSocket连接
      _initializeWebSocketAfterTableData();
    } else {
      logDebug('❌ 未找到桌台信息', tag: OrderConstants.logTag);
    }
  }

  /// 处理菜单数据
  void _processMenuData(Map<String, dynamic> args) {
    logDebug('🔍 处理菜单数据，args: $args', tag: OrderConstants.logTag);
    
    if (args['menu'] != null) {
      final menuData = args['menu'];
      logDebug('📋 菜单数据类型: ${menuData.runtimeType}', tag: OrderConstants.logTag);
      
      if (menuData is TableMenuListModel) {
        menu.value = menuData;
        menuId.value = menuData.menuId ?? 0;
        logDebug('✅ 菜单信息已设置: ${menuData.menuName} (ID: ${menuData.menuId})', tag: OrderConstants.logTag);
      }
    } else if (args['menu_id'] != null) {
      // 如果只有menu_id参数，直接设置menuId
      menuId.value = args['menu_id'] as int;
      logDebug('✅ 直接设置菜单ID: ${menuId.value}', tag: OrderConstants.logTag);
    } else {
      menuId.value = 0;
      logDebug('❌ 没有找到menu参数', tag: OrderConstants.logTag);
    }
  }


  /// 根据menu_id异步获取菜单数据

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
      if (table.value?.tableId != null && table.value!.tableId != 0) {
        source.value = 'table';
        logDebug('✅ 根据桌台信息推断来源为: table', tag: OrderConstants.logTag);
      } else {
        source.value = 'takeaway';
        logDebug('✅ 根据无桌台信息推断来源为: takeaway', tag: OrderConstants.logTag);
      }
    }
  }

  /// 在桌台数据设置后初始化WebSocket连接
  Future<void> _initializeWebSocketAfterTableData() async {
    logDebug('🔌 桌台数据已设置，开始初始化WebSocket连接...', tag: OrderConstants.logTag);
    await _initializeWebSocket();
  }

  /// 初始化WebSocket连接
  Future<void> _initializeWebSocket() async {
    if (table.value?.tableId == null || table.value!.tableId == 0) {
      logDebug('❌ 桌台ID为空或无效，无法初始化WebSocket (tableId: ${table.value?.tableId})', tag: OrderConstants.logTag);
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
        onOperationFailed: _handleOperationFailed,
        onCartOperationSuccess: _handleCartOperationSuccess,
        onDish14005Error: _handleDish14005Error,
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
        
        // 为CartController设置WebSocket处理器和防抖管理器
        _cartController.setWebSocketHandler(_wsHandler);
        _cartController.setWebSocketDebounceManager(_wsDebounceManager);
        
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
    if (table.value?.tableId == null || table.value!.tableId == 0) return;
    
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

  /// 加载服务员设置
  Future<void> _loadWaiterSetting() async {
    try {
      logDebug('🔄 开始加载服务员设置...', tag: OrderConstants.logTag);
      final result = await _api.getWaiterSetting();
      
      if (result.isSuccess && result.data != null) {
        waiterSetting.value = result.data!;
        logDebug('✅ 服务员设置加载成功: confirmOrderBeforeSubmit=${result.data!.confirmOrderBeforeSubmit}', tag: OrderConstants.logTag);
      } else {
        logDebug('⚠️ 服务员设置加载失败，使用默认值: ${result.msg}', tag: OrderConstants.logTag);
        // 保持默认值 true
      }
    } catch (e) {
      logDebug('❌ 加载服务员设置异常: $e', tag: OrderConstants.logTag);
      // 保持默认值 true
    }
  }

  /// 按顺序加载菜品数据和购物车数据
  Future<void> _loadDishesAndCart() async {
    logDebug('🔄 开始按顺序加载菜品和购物车数据', tag: OrderConstants.logTag);
    
    // 先加载菜品数据 - 使用API获取菜品数据
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
  Future<void> _loadCartFromApi({bool silent = false}) async {
    if (table.value?.tableId == null) {
      logDebug('❌ 桌台ID为空，无法加载购物车数据', tag: OrderConstants.logTag);
      return;
    }
    
    try {
      // 委托给CartController处理
      await _cartController.loadCartFromApi(
        tableId: table.value!.tableId.toString(),
        silent: silent,
      );
      
      // 同步数据回到OrderController
      _syncCartFromController();
    } catch (e) {
      // 检查是否是210状态码异常（数据处理中）
      if (e.runtimeType.toString().contains('CartProcessingException')) {
        logDebug('⏳ 购物车数据处理中(210)，保留现有数据不清空', tag: OrderConstants.logTag);
        // 210状态码时不做任何操作，保留现有购物车数据
        return;
      }
      logError('❌ 加载购物车数据异常: $e', tag: OrderConstants.logTag);
      // 其他异常也不清空购物车，保持现有状态
    }
    
    // 预加载购物车图片
    _preloadCartImages();
  }

  /// 预加载购物车图片
  void _preloadCartImages() {
    if (cart.isEmpty) return;
    
    // 收集所有购物车商品的图片URL
    List<String> imageUrls = [];
    List<String> allergenUrls = [];
    
    for (final entry in cart.entries) {
      final cartItem = entry.key;
      
      // 菜品图片
      if (cartItem.dish.image.isNotEmpty) {
        imageUrls.add(cartItem.dish.image);
      }
      
      // 敏感物图标
      if (cartItem.dish.allergens != null) {
        for (final allergen in cartItem.dish.allergens!) {
          if (allergen.icon != null && allergen.icon!.isNotEmpty) {
            allergenUrls.add(allergen.icon!);
          }
        }
      }
    }
    
    // 异步预加载图片
    if (imageUrls.isNotEmpty || allergenUrls.isNotEmpty) {
      ImageCacheManager().preloadImagesAsync([...imageUrls, ...allergenUrls]);
      // logDebug('🖼️ 购物车预加载图片: ${imageUrls.length} 个菜品图片, ${allergenUrls.length} 个敏感物图标', tag: OrderConstants.logTag);
    }
  }

  /// 从API获取菜品数据
  Future<void> _loadDishesFromApi({bool refreshMode = false}) async {
    if (menuId.value == 0) {
      GlobalToast.error('获取菜品数据失败');
      return;
    }

    try {
      isLoadingDishes.value = true; 
      
      final result = await _api.getMenudDishList(
        tableID: table.value?.tableId.toString(),
        menuId: menuId.value.toString(),
      );
      
      if (result.isSuccess && result.data != null) {
         // 刷新模式下不清空现有数据，保持搜索框状态
         _loadDishesFromData(result.data!, clearExisting: !refreshMode);
      } else {
         GlobalToast.error(result.msg ?? '获取菜品数据失败');
      }
    } catch (e) {
       GlobalToast.error('$e');
    } finally {
      isLoadingDishes.value = false;
    }
  }

  /// 从数据加载菜品
  void _loadDishesFromData(List<DishListModel> dishListModels, {bool clearExisting = true}) {
     
    DataConverter.loadDishesFromData(
      dishListModels: dishListModels,
      categories: categories,
      dishes: dishes,
      clearExisting: clearExisting, // 传递清空标志
    );
    
    // 将菜品数据传递给CartController
    _cartController.initializeDependencies(
      dishes: dishes,
      categories: categories,
    );
    
    // 强制刷新UI
    categories.refresh();
    dishes.refresh();
    
    // 预加载菜品图片
    _preloadDishImages();
  }

  /// 预加载菜品图片
  void _preloadDishImages() {
    if (dishes.isNotEmpty) {
      // 异步预加载，不阻塞UI
      ImageCacheManager().preloadDishImages(dishes);
      // logDebug('🖼️ 开始预加载菜品图片: ${dishes.length}个菜品', tag: OrderConstants.logTag);
    }
  }

  // ========== 购物车操作 ==========
  
  /// 从CartController同步购物车状态到OrderController
  void _syncCartFromController() {
    // 保存当前的操作上下文（用于409强制更新）
    final savedOperationCartItem = _lastOperationCartItem;
    final savedOperationQuantity = _lastOperationQuantity;
    
    cart.clear();
    cart.addAll(_cartController.cart);
    cart.refresh();
    update();
    
    // 同步loading状态
    isCartOperationLoading.value = _cartController.isCartOperationLoading.value;
    isLoadingCart.value = _cartController.isLoadingCart.value;
    
    // 同步cartInfo状态
    cartInfo.value = _cartController.cartInfo.value;
    
    // 同步备注状态
    final cartRemark = _cartController.cartInfo.value?.remark;
    if (cartRemark != null && cartRemark.isNotEmpty) {
      remark.value = cartRemark;
    }
    
    // 恢复操作上下文（如果之前有保存的话）
    // 这样可以确保在409强制更新期间，操作上下文不会被清除
    if (savedOperationCartItem != null && savedOperationQuantity != null) {
      _lastOperationCartItem = savedOperationCartItem;
      _lastOperationQuantity = savedOperationQuantity;
      // logDebug('✅ 在同步过程中保留了操作上下文: ${savedOperationCartItem.dish.name}, quantity=$savedOperationQuantity', tag: OrderConstants.logTag);
    }
  }

  void clearCart() {
    // 委托给CartController处理
    _cartController.clearCart();
    
    // 同步状态回到OrderController
    _syncCartFromController();
  }

  /// 设置备注
  void setRemark(String newRemark) {
    remark.value = newRemark;
    logDebug('✅ 设置订单备注: $newRemark', tag: OrderConstants.logTag);
    
    // 发送WebSocket消息
    if (table.value?.tableId != null) {
      _wsHandler.sendCartRemark(newRemark).then((success) {
        if (success) {
          logDebug('✅ 备注WebSocket消息发送成功', tag: OrderConstants.logTag);
        } else {
          logDebug('❌ 备注WebSocket消息发送失败', tag: OrderConstants.logTag);
        }
      });
    } else {
      logDebug('⚠️ 桌台ID为空，跳过发送备注消息', tag: OrderConstants.logTag);
    }
  }

  /// 清空备注
  void clearRemark() {
    remark.value = "";
    logDebug('🧹 清空外卖订单备注', tag: OrderConstants.logTag);
  }

  Future<void> addToCart(Dish dish, {Map<String, List<String>>? selectedOptions}) async {
    // print('🛒 OrderController.addToCart 被调用: ${dish.name}');
    logDebug('📤 委托添加菜品到购物车: ${dish.name}', tag: OrderConstants.logTag);
    
    // 如果菜品有14005错误状态，则禁止添加
    if (isDishAddDisabled(dish.id)) {
      logDebug('⚠️ 菜品有14005错误状态，禁止添加: ${dish.name}', tag: OrderConstants.logTag);
      return;
    }
    
    // 委托给CartController处理
    await _cartController.addToCart(dish, selectedOptions: selectedOptions);
    
    // 同步状态回到OrderController
    _syncCartFromController();
    
    // 同步操作上下文（用于409强制更新）
    _lastOperationCartItem = _cartController.lastOperationCartItem;
    _lastOperationQuantity = _cartController.lastOperationQuantity;
    
    // 注意：WebSocket消息发送由CartController负责，这里不需要重复发送
    
    // logDebug('🔄 同步操作上下文 (addToCart): ${_lastOperationCartItem?.dish.name}, quantity=$_lastOperationQuantity', tag: OrderConstants.logTag);
  }

  /// 添加指定数量的菜品到购物车（用于选规格弹窗）
  void addToCartWithQuantity(Dish dish, {required int quantity, Map<String, List<String>>? selectedOptions}) {
    // logDebug('📤 委托添加指定数量菜品到购物车: ${dish.name} x$quantity', tag: OrderConstants.logTag);
    
    // 委托给CartController处理
    _cartController.addToCartWithQuantity(dish, quantity: quantity, selectedOptions: selectedOptions);
    
    // 同步状态回到OrderController
    _syncCartFromController();
    
    // 同步操作上下文（用于409强制更新）
    _lastOperationCartItem = _cartController.lastOperationCartItem;
    _lastOperationQuantity = _cartController.lastOperationQuantity;
    
    // 注意：WebSocket消息发送由CartController负责，这里不需要重复发送
    
    logDebug('🔄 同步操作上下文 (addToCartWithQuantity): ${_lastOperationCartItem?.dish.name}, quantity=$_lastOperationQuantity', tag: OrderConstants.logTag);
  }
  


  void removeFromCart(dynamic item) {
    // 委托给CartController处理
    _cartController.removeFromCart(item);
    
    // 同步状态回到OrderController
    _syncCartFromController();
    
    // 同步操作上下文（用于409强制更新）
    _lastOperationCartItem = _cartController.lastOperationCartItem;
    _lastOperationQuantity = _cartController.lastOperationQuantity;
  }


  void deleteCartItem(CartItem cartItem) {
    // 委托给CartController处理
    _cartController.deleteCartItem(cartItem);
    
    // 同步状态回到OrderController
    _syncCartFromController();
    
    // 同步操作上下文（用于409强制更新）
    _lastOperationCartItem = _cartController.lastOperationCartItem;
    _lastOperationQuantity = _cartController.lastOperationQuantity;
  }

  void addCartItemQuantity(CartItem cartItem) {
    // 委托给CartController处理
    _cartController.addCartItemQuantity(cartItem);
    
    // 同步状态回到OrderController
    _syncCartFromController();
    
    // 同步操作上下文（用于409强制更新）
    _lastOperationCartItem = _cartController.lastOperationCartItem;
    _lastOperationQuantity = _cartController.lastOperationQuantity;
    logDebug('🔄 同步操作上下文 (addCartItemQuantity): ${_lastOperationCartItem?.dish.name}, quantity=$_lastOperationQuantity', tag: OrderConstants.logTag);
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

    // 如果是增加数量且菜品有14005错误状态，则禁止操作
    if (newQuantity > oldQuantity && isDishAddDisabled(cartItem.dish.id)) {
      onError(14005, '该菜品暂时无法增加数量，请稍后再试');
      return;
    }

    // 保存操作上下文，用于可能的409强制更新
    // 注意：对于手动更新数量，保存的是变化量而不是绝对数量
    _lastOperationCartItem = cartItem;
    _lastOperationQuantity = newQuantity - oldQuantity; // 保存变化量
    
    // 直接设置数量
    _cartController.setCartItemQuantity(cartItem, newQuantity);
    
    onSuccess();
    logDebug('🔄 设置购物车项数量: ${cartItem.dish.name} -> $newQuantity', tag: OrderConstants.logTag);
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

  // 保持现有的getter方法以确保UI兼容性
  int get totalCount => _cartController.totalCount;
  double get totalPrice => _cartController.totalPrice;
  double get baseTotalPrice => _cartController.baseTotalPrice;
  
  // API返回的总价格
  double get apiTotalPrice => cartInfo.value?.totalPrice ?? 0.0;

  int getCategoryCount(int categoryIndex) {
    return _cartController.getCategoryCount(categoryIndex);
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



  /// WebSocket防抖失败回调
  void _onWebSocketDebounceFailed(CartItem cartItem, int quantity) {
    // 通知CartController处理失败
    _cartController.handleWebSocketFailure(cartItem);
    logDebug('❌ WebSocket防抖失败: ${cartItem.dish.name}', tag: OrderConstants.logTag);
  }

  // ========== WebSocket消息处理 ==========

  void _handleCartRefresh() {
    logDebug('🔄 收到服务器刷新购物车消息', tag: OrderConstants.logTag);
    // 收到refresh消息时，先尝试普通刷新，如果遇到210状态码则延迟重试
    if (table.value?.tableId != null) {
      _refreshCartWithRetry(table.value!.tableId.toString());
    } else {
      logDebug('❌ 桌台ID为空，无法刷新购物车', tag: OrderConstants.logTag);
    }
  }

  /// 带重试机制的购物车刷新
  Future<void> _refreshCartWithRetry(String tableId, {int retryCount = 0}) async {
    const maxRetries = 3;
    const retryDelay = Duration(milliseconds: 1000);
    
    try {
      // 先尝试普通刷新（不强制清空）
      await _cartController.refreshCartFromApi(
        tableId: tableId,
        forceRefresh: false,
      );
      logDebug('✅ 购物车刷新成功', tag: OrderConstants.logTag);
    } catch (e) {
      // 检查是否是210状态码异常
      if (e.runtimeType.toString().contains('CartProcessingException')) {
        if (retryCount < maxRetries) {
          logDebug('⏳ 遇到210状态码，${retryDelay.inMilliseconds}ms后重试 (${retryCount + 1}/$maxRetries)', tag: OrderConstants.logTag);
          Future.delayed(retryDelay, () {
            _refreshCartWithRetry(tableId, retryCount: retryCount + 1);
          });
        } else {
          logDebug('⚠️ 重试次数已达上限，保留本地购物车数据', tag: OrderConstants.logTag);
        }
      } else {
        logError('❌ 购物车刷新异常: $e', tag: OrderConstants.logTag);
      }
    }
  }

  void _handleCartAdd() {
    logDebug('➕ 收到服务器购物车添加消息', tag: OrderConstants.logTag);
    // loading状态由CartController管理，这里不需要手动设置
  }

  void _handleCartUpdate() {
    logDebug('🔄 收到服务器购物车更新消息', tag: OrderConstants.logTag);
    // loading状态由CartController管理，这里不需要手动设置
  }

  void _handleCartDelete() {
    logDebug('🗑️ 收到服务器购物车删除消息', tag: OrderConstants.logTag);
    // loading状态由CartController管理，这里不需要手动设置
    _cartManager.refreshCartFromServer(() => _loadCartFromApi(silent: true));
  }

  void _handleCartClear() {
    logDebug('🧹 收到服务器购物车清空消息', tag: OrderConstants.logTag);
    // loading状态由CartController管理，这里不需要手动设置
    _cartManager.refreshCartFromServer(() => _loadCartFromApi(silent: true));
  }

  void _handleOrderRefresh() {
    logDebug('🔄 收到服务器刷新已点订单消息', tag: OrderConstants.logTag);
    logDebug('🔄 当前loading状态: ${isLoadingOrdered.value}', tag: OrderConstants.logTag);
    // WebSocket刷新已点订单时，静默刷新（不显示loading）
    loadCurrentOrder(showLoading: false);
  }

  /// WebSocket确认成功后触发动画播放
  void _handleCartOperationSuccess(String messageId) {
    try {
      logDebug('🎯 处理WebSocket操作成功: messageId=$messageId', tag: OrderConstants.logTag);
      
      // 检查是否是减少操作，如果是则清除14005错误状态
      final operationContext = _cartController.getOperationContextByMessageId(messageId);
      if (operationContext != null) {
        final dishId = operationContext.cartItem.dish.id;
        final quantity = operationContext.quantity;
        
        // 如果是减少操作（quantity < 0），清除该菜品的14005错误状态
        if (quantity < 0) {
          _cartController.setDish14005Error(dishId, false);
          logDebug('✅ 减少操作成功，已清除菜品14005错误状态: ${operationContext.cartItem.dish.name}', tag: OrderConstants.logTag);
        }
      }
      
      // 通知CartController WebSocket操作成功
      _cartController.handleWebSocketResponse(messageId, true);
      
      final context = Get.context;
      if (context != null) {
        // 延迟少许，确保UI overlay可用
        Future.delayed(Duration(milliseconds: 0), () {
          print('🎬 播放动画: messageId=$messageId');
          // 通过注册表播放与该messageId绑定的动画
          CartAnimationRegistry.playForMessageId(messageId, context);
        });
      } else {
        print('❌ 无法获取context，跳过动画播放');
      }
    } catch (e) {
      logDebug('❌ 处理操作成功动画时异常: $e', tag: OrderConstants.logTag);
    }
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
        _errorHandler.handleApiError('人数更新', result.msg ?? Get.context!.l10n.failed);
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
        // 同步更新menuId，确保菜品数据能正确加载
        this.menuId.value = targetMenu.menuId ?? 0;
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
        orderId: currentTable.orderId,
        mainTable: currentTable.mainTable,
        mergedTables: currentTable.mergedTables,
      );
      table.value = updatedTable;
    }
  }


  /// 处理强制更新需求（409状态码）
  void _handleForceUpdateRequired(String message, Map<String, dynamic>? data) {
    logDebug('⚠️ 处理409状态码，立即显示强制更新确认弹窗: $message', tag: OrderConstants.logTag);
    logDebug('📋 收到的完整409数据: $data', tag: OrderConstants.logTag);
    
    // 从409响应数据中提取消息ID
    String? messageId;
    if (data != null) {
      final nestedData = data['data'] as Map<String, dynamic>?;
      if (nestedData != null) {
        messageId = nestedData['message_id'] as String?;
      }
    }
    
    logDebug('🔍 提取到的消息ID: $messageId', tag: OrderConstants.logTag);
    
    // 根据消息ID从CartController查找对应的操作上下文
    dynamic operationContext;
    if (messageId != null) {
      operationContext = _cartController.getOperationContextByMessageId(messageId);
      if (operationContext != null) {
        logDebug('✅ 找到操作上下文: dish=${operationContext.cartItem.dish.name}, quantity=${operationContext.quantity}', tag: OrderConstants.logTag);
        
        // 更新全局的操作上下文（兼容旧的强制更新逻辑）
        _lastOperationCartItem = operationContext.cartItem;
        _lastOperationQuantity = operationContext.quantity;
        
        // 存储当前处理的消息ID（用于强制更新时传递）
        _currentProcessingMessageId = messageId;
      } else {
        logDebug('❌ 未找到消息ID对应的操作上下文: $messageId', tag: OrderConstants.logTag);
      }
    }
    
    // 获取当前上下文
    final context = Get.context;
    if (context != null) {
      // 立即显示确认弹窗，不等待任何延迟
      ModalUtils.showConfirmDialog(
        context: context,
        title: context.l10n.operationConfirmed,
        message: message,
        confirmText: context.l10n.confirm,
        cancelText: context.l10n.cancel,
        confirmColor: const Color(0xFFFF8C00),
        onConfirm: () {
          logDebug('✅ 用户确认409强制更新', tag: OrderConstants.logTag);
          _performForceUpdate();
        },
        onCancel: () {
          logDebug('❌ 用户取消强制更新，回滚本地状态', tag: OrderConstants.logTag);
          _rollbackLocalState();
        },
      );
    } else {
      logDebug('❌ 无法获取上下文，无法显示强制更新弹窗', tag: OrderConstants.logTag);
    }
  }

  /// 执行强制更新操作
  void _performForceUpdate() {
    logDebug('🔄 执行强制更新操作', tag: OrderConstants.logTag);
    logDebug('🔍 当前操作上下文状态: _lastOperationCartItem=${_lastOperationCartItem?.dish.name}, _lastOperationQuantity=$_lastOperationQuantity', tag: OrderConstants.logTag);
    
    try {
      // 使用保存的操作上下文
      if (_lastOperationCartItem != null && _lastOperationQuantity != null) {
        final cartItem = _lastOperationCartItem!;
        final quantity = _lastOperationQuantity!;
        
        logDebug('✅ 使用保存的操作上下文执行强制更新: ${cartItem.dish.name}, quantity=$quantity', tag: OrderConstants.logTag);
        logDebug('📋 购物车项详情: cartId=${cartItem.cartId}, cartSpecificationId=${cartItem.cartSpecificationId}', tag: OrderConstants.logTag);
        
        // 获取操作上下文以获取完整的选项信息
        dynamic operationContext;
        if (_currentProcessingMessageId != null) {
          operationContext = _cartController.getOperationContextByMessageId(_currentProcessingMessageId!);
        }
        
        final selectedOptions = operationContext?.selectedOptions ?? cartItem.selectedOptions;
        
        // 二次确认时，应该重新发送原始的add操作，而不是update操作
        // 因为409状态码表示的是add操作的冲突，需要强制执行add操作
        logDebug('🔄 执行强制添加操作（重新发送add请求）', tag: OrderConstants.logTag);
        
        // 使用原始消息ID进行强制操作
        _wsHandler.sendAddDish(
          dish: cartItem.dish,
          quantity: quantity,
          selectedOptions: selectedOptions,
          forceOperate: true,
          customMessageId: _currentProcessingMessageId,
        );
        
        // 强制更新成功后清理数据
        _lastOperationCartItem = null;
        _lastOperationQuantity = null;
        
        // 清理映射关系
        if (_currentProcessingMessageId != null) {
          _cartController.clearOperationContext(_currentProcessingMessageId!);
          _currentProcessingMessageId = null;
        }
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

  /// 取消409确认时的处理
  void _rollbackLocalState() {
    logDebug('🔙 用户取消了409确认，清理操作上下文', tag: OrderConstants.logTag);
    
    try {
      // 清理操作上下文
      _lastOperationCartItem = null;
      _lastOperationQuantity = null;
      
      // 刷新购物车数据，从服务器获取最新状态
      _loadCartFromApi(silent: true);
      
      logDebug('✅ 操作上下文清理完成', tag: OrderConstants.logTag);
    } catch (e) {
      logDebug('❌ 清理操作上下文异常: $e', tag: OrderConstants.logTag);
    }
  }

  /// 处理操作失败（非409错误）
  void _handleOperationFailed(String? messageId, String errorMessage) {
    logDebug('❌ 处理操作失败: messageId=$messageId, error=$errorMessage', tag: OrderConstants.logTag);
    
    try {
      if (messageId != null) {
        // 通知CartController WebSocket操作失败（但不回滚）
        _cartController.handleWebSocketResponse(messageId, false, errorMessage: errorMessage);
        logDebug('✅ 已通知操作失败，等待服务器数据同步', tag: OrderConstants.logTag);
      } else {
        logDebug('⚠️ 消息ID为空，尝试通过最近操作上下文处理', tag: OrderConstants.logTag);
        
        // 尝试通过最近的操作上下文来处理失败
        if (_lastOperationCartItem != null) {
          final dishId = _lastOperationCartItem!.dish.id;
          _cartController.setDishLoading(dishId, false);
          logDebug('🔄 通过最近操作上下文清理loading状态: ${_lastOperationCartItem!.dish.name}', tag: OrderConstants.logTag);
          
          // 尝试查找所有相关的操作上下文并处理
          final allContexts = _cartController.getAllOperationContexts();
          for (final entry in allContexts.entries) {
            final context = entry.value;
            if (context.cartItem.dish.id == dishId) {
              logDebug('🎯 找到匹配的操作上下文: messageId=${entry.key}, dish=${context.cartItem.dish.name}', tag: OrderConstants.logTag);
              _cartController.handleWebSocketResponse(entry.key, false, errorMessage: errorMessage);
              break; // 只处理第一个匹配的
            }
          }
        } else {
          logDebug('⚠️ 无最近操作上下文，无法精确处理失败', tag: OrderConstants.logTag);
        }
      }
      
      // 显示错误提示
      if (errorMessage.isNotEmpty) {
        GlobalToast.error(errorMessage);
      } else {
        GlobalToast.error('操作失败，请重试');
      }
    } catch (e) {
      logDebug('❌ 处理操作失败异常: $e', tag: OrderConstants.logTag);
    }
  }
  
  /// 处理14005错误（禁用增加按钮）
  void _handleDish14005Error(String? messageId, String errorMessage) {
    logDebug('🚫 处理14005错误: messageId=$messageId, error=$errorMessage', tag: OrderConstants.logTag);
    
    try {
      String? dishId;
      
      // 尝试从操作上下文中获取菜品ID
      if (messageId != null) {
        final operationContext = _cartController.getOperationContextByMessageId(messageId);
        if (operationContext != null) {
          dishId = operationContext.cartItem.dish.id;
          logDebug('🎯 从操作上下文获取菜品ID: $dishId (${operationContext.cartItem.dish.name})', tag: OrderConstants.logTag);
        }
      }
      
      // 如果没有找到，尝试从最近操作上下文获取
      if (dishId == null && _lastOperationCartItem != null) {
        dishId = _lastOperationCartItem!.dish.id;
        logDebug('🔄 从最近操作上下文获取菜品ID: $dishId (${_lastOperationCartItem!.dish.name})', tag: OrderConstants.logTag);
      }
      
      // 设置菜品的14005错误状态（禁用增加按钮）
      if (dishId != null) {
        _cartController.setDish14005Error(dishId, true);
        logDebug('✅ 已设置菜品14005错误状态，增加按钮已禁用: $dishId', tag: OrderConstants.logTag);
        
        // 14005错误时，强制刷新购物车数据以确保数量显示正确
        logDebug('🔄 14005错误，强制刷新购物车数据确保数量正确', tag: OrderConstants.logTag);
        _cartController.refreshCartFromApi();
      } else {
        logDebug('⚠️ 无法确定菜品ID，无法设置14005错误状态', tag: OrderConstants.logTag);
      }
    } catch (e) {
      logDebug('❌ 处理14005错误异常: $e', tag: OrderConstants.logTag);
    }
  }

  // ========== 公开方法 ==========

  Future<void> refreshOrderData() async {
    logDebug('🔄 开始刷新点餐页面数据...', tag: OrderConstants.logTag);
    await _loadDishesFromApi(refreshMode: true);
    logDebug('✅ 点餐页面数据刷新完成', tag: OrderConstants.logTag);
  }
  
  // 通用刷新方法 - 为BaseListPageWidget提供接口
  Future<void> refreshData() async {
    await refreshOrderData();
  }

  Future<void> forceRefreshCart({bool silent = false}) async {
    logDebug('🔄 强制刷新购物车数据', tag: OrderConstants.logTag);
    await _loadCartFromApi(silent: silent);
  }
  
  void forceRefreshCartUI() {
    logDebug('🔄 强制刷新购物车UI', tag: OrderConstants.logTag);
    
    // 委托给CartController刷新UI
    _cartController.forceRefreshCartUI();
    
    // 同步状态并刷新OrderController的UI
    _syncCartFromController();
    
    Future.delayed(Duration(milliseconds: 100), () {
      _syncCartFromController();
    });
  }

  @override
  void onReady() {
    super.onReady();
    // 移除初始化完成后的强制刷新，避免210状态码导致数据清空
    // 购物车数据已经在初始化时加载完成，不需要再次强制刷新
    logDebug('✅ OrderController onReady 完成，购物车数据已加载', tag: OrderConstants.logTag);
  }

  // ========== 已点订单相关方法 ==========

  /// 加载当前订单数据
  Future<void> loadCurrentOrder({bool showLoading = true}) async {
    if (table.value?.tableId == null) {
      logDebug('❌ 桌台ID为空，无法加载已点订单', tag: OrderConstants.logTag);
      return;
    }

    try {
      if (showLoading) {
        isLoadingOrdered.value = true;
      }
      
      logDebug('📋 开始加载已点订单数据...', tag: OrderConstants.logTag);

      final result = await _orderApi.getCurrentOrder(
        tableId: table.value!.tableId.toString(),
      );

      if (result.isSuccess && result.data != null) {
        currentOrder.value = result.data;
        hasNetworkErrorOrdered.value = false;
        logDebug('✅ 已点订单数据加载成功: ${result.data?.details?.length ?? 0}个订单', tag: OrderConstants.logTag);
      } else {
        // API调用成功但无数据，显示空状态
        logDebug('📭 当前桌台没有已点订单', tag: OrderConstants.logTag);
        currentOrder.value = null;
        hasNetworkErrorOrdered.value = false;
      }
    } catch (e) {
      logDebug('❌ 已点订单数据加载失败: $e', tag: OrderConstants.logTag);
      hasNetworkErrorOrdered.value = true;
      currentOrder.value = null;
    } finally {
      if (showLoading) {
        isLoadingOrdered.value = false;
      }
    }
  }

  /// 提交订单
  Future<Map<String, dynamic>> submitOrder() async {
    if (table.value?.tableId == null) {
      logDebug('❌ 桌台ID为空，无法提交订单', tag: OrderConstants.logTag);
      return {
        'success': false,
        'message': Get.context!.l10n.operationTooFrequentPleaseTryAgainLater
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
        
        // 提交成功后刷新已点订单数据
        await loadCurrentOrder(showLoading: false);
        
        // 刷新服务器购物车数据以确保同步
        logDebug('🔄 刷新服务器购物车数据以确保同步', tag: OrderConstants.logTag);
        await _loadCartFromApi(silent: true);
        
        return {
          'success': true,
          'message': Get.context!.l10n.orderPlacedSuccessfully
        };
      } else {
        logDebug('❌ 订单提交失败: ${result.msg}', tag: OrderConstants.logTag);
        return {
          'success': false,
          'message': result.msg ?? Get.context!.l10n.failed
        };
      }
    } catch (e, stackTrace) {
      logDebug('❌ 订单提交异常: $e', tag: OrderConstants.logTag);
      logDebug('❌ StackTrace: $stackTrace', tag: OrderConstants.logTag);
      return {
        'success': false,
        'message': '$e'
      };
    }
  }


  /// 强制清理所有缓存数据
  void forceClearAllCache() {
    logDebug('🧹 开始强制清理所有缓存数据', tag: OrderConstants.logTag);
    
    // 清理菜品数据
    categories.clear();
    dishes.clear();
    selectedCategory.value = 0;
    searchKeyword.value = "";
    sortType.value = SortType.none;
    
    // 清理购物车数据
    cart.clear();
    cartInfo.value = null;
    
    // 🔧 修复：强制清理时也清除所有14005错误状态
    _cartController.dish14005ErrorStates.clear();
    logDebug('🧹 强制清理时已清除所有14005错误状态', tag: OrderConstants.logTag);
    
    // 清理订单数据
    currentOrder.value = null;
    
    // 清理敏感物数据
    selectedAllergens.clear();
    tempSelectedAllergens.clear();
    allAllergens.clear();
    
    // 清理菜单和桌台数据
    table.value = null;
    menu.value = null;
    adultCount.value = 0;
    childCount.value = 0;
    source.value = "";
    
    // 重置状态
    isInitialized.value = false;
    justSubmittedOrder.value = false;
    isLoadingDishes.value = false;
    isLoadingCart.value = false;
    isCartOperationLoading.value = false;
    isLoadingOrdered.value = false;
    hasNetworkErrorOrdered.value = false;
    
    // 强制刷新UI
    categories.refresh();
    dishes.refresh();
    cart.refresh();
    selectedAllergens.refresh();
    tempSelectedAllergens.refresh();
    allAllergens.refresh();
    table.refresh();
    menu.refresh();
    adultCount.refresh();
    childCount.refresh();
    source.refresh();
    cartInfo.refresh();
    currentOrder.refresh();
    
    logDebug('✅ 所有缓存数据已清理完成', tag: OrderConstants.logTag);
  }

  @override
  void onClose() {
    logDebug('🔍 OrderController onClose 开始', tag: OrderConstants.logTag);
    
    // 清理WebSocket连接
    _wsHandler.dispose();
    _wsDebounceManager.dispose();
    _cartManager.dispose();
    
    // 清理CartController
    _cartController.onClose();
    
    // 清理所有WebSocket连接
    _wsLifecycleManager.cleanupAllConnections();
    
    logDebug('✅ OrderController onClose 完成，WebSocket连接已清理', tag: OrderConstants.logTag);
    super.onClose();
  }
}

