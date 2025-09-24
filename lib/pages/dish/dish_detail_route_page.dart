import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/order/model/dish.dart';
import 'dish_detail_page.dart';

/// 菜品详情路由页面
/// 用于处理从路由参数接收菜品数据的情况
class DishDetailRoutePage extends StatelessWidget {
  const DishDetailRoutePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 从路由参数获取菜品数据
    final arguments = Get.arguments as Map<String, dynamic>?;
    final dish = arguments?['dish'] as Dish?;
    
    if (dish == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('菜品详情'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('菜品数据错误', style: TextStyle(fontSize: 16, color: Colors.grey)),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Get.back(),
                child: Text('返回'),
              ),
            ],
          ),
        ),
      );
    }
    
    // 使用菜品详情页面
    return DishDetailPage(
      dishData: dish,
    );
  }
}
