class ApiRequest {
  static const authLoginByCode = '/api/waiter/login';

  static const lobbyList = '/api/waiter/store/halls';

  static const tableList = '/api/waiter/table/list';

  static const tableMeneList = '/api/waiter/menus';

  static const dishList = '/api/waiter/dish/list';

  static const changeTable = '/api/waiter/table/change_table';

  static const openTable = '/api/waiter/table/open';

  static const changeTableStatus = '/api/waiter/table/change_status';

  static const changeMenu = '/api/waiter/table/change_menu';

  static const changePeopleCount = '/api/waiter/table/change_people_count';

  static const tableDetail = '/api/waiter/table/detail';

  static const cartInfo = '/api/waiter/cart/info';

  static const submitOrder = '/api/waiter/cart/submit_order';

  static const currentOrder = '/api/waiter/order/current';

  static const mergeTable = '/api/waiter/table/merge';

  static const changeInfo = '/api/waiter/table/change_info';

  static const reserveInfo = '/api/waiter/table/reserve_info';

  static const unmergeTable = '/api/waiter/table/unmerge';

  // 外卖相关接口
  static const takeoutList = '/api/waiter/order/takeout/list';
  
  static const takeoutDetail = '/api/waiter/order/takeout/detail';
  
  // 虚拟开桌接口
  static const openVirtualTable = '/api/waiter/table/open_virtual';
  
  // 修改密码接口
  static const changePassword = '/api/waiter/change/password';
  
  // 服务员信息接口
  static const waiterInfo = '/api/waiter/info';
  
  // 服务员设置接口
  static const waiterSetting = '/api/waiter/setting/info';
}
