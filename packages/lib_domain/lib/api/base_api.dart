import 'package:lib_domain/cons/api_request.dart';
import 'package:lib_domain/entrity/home/lobby_list_model/lobby_list_model.dart';
import 'package:lib_base/lib_base.dart';
import 'package:lib_domain/entrity/home/table_list_model/table_list_model.dart';
import 'package:lib_domain/entrity/home/table_menu_list_model/table_menu_list_model.dart';
import 'package:lib_domain/entrity/order/dish_list_model/dish_list_model.dart';

class BaseApi {
  //大厅列表
  Future<HttpResultN<LobbyListModel>> getLobbyList() async {
    final result = await HttpManagerN.instance.executeGet(ApiRequest.lobbyList);
    if (result.isSuccess) {
      return result.convert(
        data: LobbyListModel.fromJson(result.getDataJson()),
      );
    } else {
      return result.convert();
    }
  }

  //桌台列表
  Future<HttpResultN<List<TableListModel>>> getTableList({
    String? queryType = "0",
    String? hallId,
  }) async {
    final params = {
      "query_type": queryType,
      "hall_id": hallId,
      // "language_code": lan,
    };
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.tableList,
      queryParam: params,
    );
    if (result.isSuccess) {
      final List<TableListModel> list = (result.dataJson as List)
          .map((e) => TableListModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return result.convert(data: list);
    } else {
      return result.convert();
    }
  }

  //菜单列表
  Future<HttpResultN<List<TableMenuListModel>>> getTableMenuList() async {
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.tableMeneList,
    );
    if (result.isSuccess) {
      final List<TableMenuListModel> list = (result.dataJson as List)
          .map((e) => TableMenuListModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return result.convert(data: list);
    } else {
      return result.convert();
    }
  }

  /// 菜品列表
  Future<HttpResultN<List<DishListModel>>> getMenudDishList({String? tableID, String? menuId}) async {
    final params = {
      "table_id": tableID,
      "menu_id": menuId,
      // "language_code": lan,
    };
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.dishList,
      queryParam: params,
    );
     
    if (result.isSuccess) {
      final List<DishListModel> list = (result.dataJson as List)
          .map((e) => DishListModel.fromJson(e as Map<String, dynamic>))
          .toList();

      return result.convert(data: list);
    } else {
      return result.convert();
    }
  }

  /// 换桌
  Future<HttpResultN<void>> changeTable({
    required int tableId,
    required int newTableId,
  }) async {
    final params = {
      "table_id": tableId,
      "new_table_id": newTableId,
    };
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.changeTable,
      jsonParam: params,
    );
    
    if (result.isSuccess) {
      return result.convert();
    } else {
      return result.convert();
    }
  }

  /// 开桌
  Future<HttpResultN<void>> openTable({
    required int tableId,
    required int adultCount,
    required int childCount,
    required int menuId,
    // int reserveId = 0,
  }) async {
    final params = {
      "table_id": tableId,
      "adult_count": adultCount,
      "child_count": childCount,
      "menu_id": menuId,
      // "reserve_id": reserveId,
    };
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.openTable,
      jsonParam: params,
    );
    
    if (result.isSuccess) {
      return result.convert();
    } else {
      return result.convert();
    }
  }

  /// 更换桌台状态
  Future<HttpResultN<void>> changeTableStatus({
    required int tableId,
    required int status,
  }) async {
    final params = {
      "table_id": tableId,
      "status": status,
    };
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.changeTableStatus,
      jsonParam: params,
    );
    
    if (result.isSuccess) {
      return result.convert();
    } else {
      return result.convert();
    }
  }

  /// 更换菜单
  Future<HttpResultN<void>> changeMenu({
    required int tableId,
    required int menuId,
  }) async {
    final params = {
      "table_id": tableId,
      "menu_id": menuId,
    };
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.changeMenu,
      jsonParam: params,
    );
    
    if (result.isSuccess) {
      return result.convert();
    } else {
      return result.convert();
    }
  }

  /// 更换人数
  Future<HttpResultN<void>> changePeopleCount({
    required int tableId,
    required int adultCount,
    required int childCount,
  }) async {
    final params = {
      "table_id": tableId,
      "adult_count": adultCount,
      "child_count": childCount,
    };
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.changePeopleCount,
      jsonParam: params,
    );
    
    if (result.isSuccess) {
      return result.convert();
    } else {
      return result.convert();
    }
  }

  /// 获取桌台详情
  Future<HttpResultN<TableListModel>> getTableDetail({
    required int tableId,
  }) async {
    final params = {
      "table_id": tableId,
    };
    final result = await HttpManagerN.instance.executeGet(
      ApiRequest.tableDetail,
      queryParam: params,
    );
    
    if (result.isSuccess) {
      return result.convert(
        data: TableListModel.fromJson(result.getDataJson()),
      );
    } else {
      return result.convert();
    }
  }
}
