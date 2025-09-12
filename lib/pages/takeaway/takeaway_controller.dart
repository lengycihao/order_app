import 'package:get/get.dart';
import 'package:order_app/pages/takeaway/model/tabelaway_item_model.dart';

class TakeawayController extends GetxController {
  var takeawayItems = <TabelawayItemModel>[].obs;
  var allItems = <TabelawayItemModel>[].obs;
  // 每个 tab 是否在刷新
  var isRefreshingAll = false.obs;
  var isRefreshingTakeaway = false.obs;

  @override
  void onInit() {
    super.onInit();

    // 模拟订单数据列表

    loadInitialData();
  }

  void loadInitialData() {
    allItems.assignAll(
      List.generate(
        20,
        (index) => TabelawayItemModel(
          orderNumber: '3126',
          status: 1,
          time: '16:12',
          price: '€ 1324',
          remark: '不要葱花香菜、清蒸鲈鱼不要鱼、柠檬茶不要柠檬、三分糖、少冰',
        ),
      ),
    );
    takeawayItems.assignAll(
      List.generate(
        20,
        (index) => TabelawayItemModel(
          orderNumber: '3126',
          status: 2,
          time: '16:12',
          price: '€ 1324',
          remark: '不要葱花香菜、清蒸鲈鱼不要鱼、柠檬茶不要柠檬、三分糖、少冰',
        ),
      ),
    );
  }

  Future<void> refreshData(int tabIndex) async {
    if (tabIndex == 0) {
      isRefreshingAll.value = true;
      await Future.delayed(Duration(seconds: 2));
      allItems.assignAll(
        List.generate(
          20,
          (index) => TabelawayItemModel(
            orderNumber: '3126',
            status: 1,
            time: '16:12',
            price: '€ 1324',
            remark: '不要葱花香菜、清蒸鲈鱼不要鱼、柠檬茶不要柠檬、三分糖、少冰',
          ),
        ),
      );
      isRefreshingAll.value = false;
    } else {
      isRefreshingTakeaway.value = true;
      await Future.delayed(Duration(seconds: 2));
      takeawayItems.assignAll(
        List.generate(
          20,
          (index) => TabelawayItemModel(
            orderNumber: '3126',
            status: 2,
            time: '16:12',
            price: '€ 1324',
            remark: '不要葱花香菜、清蒸鲈鱼不要鱼、柠檬茶不要柠檬、三分糖、少冰',
          ),
        ),
      );
      isRefreshingTakeaway.value = false;
    }
  }
}
