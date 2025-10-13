import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../pages/order/components/restaurant_loading_widget.dart';
import '../components/skeleton_widget.dart';

/// 基础列表页面抽象类
/// 统一处理空状态和网络异常展示
abstract class BaseListPageWidget extends StatefulWidget {
  const BaseListPageWidget({super.key});
}

/// 基础列表页面状态抽象类
abstract class BaseListPageState<T extends BaseListPageWidget> extends State<T> {
  
  /// 是否正在加载
  bool get isLoading;
  
  /// 是否有网络错误
  bool get hasNetworkError;
  
  /// 是否有数据（非空且非空列表）
  bool get hasData;
  
  /// 是否应该显示骨架图（首次加载且没有数据时）
  bool get shouldShowSkeleton;
  
  /// 刷新数据的方法
  Future<void> onRefresh();
  
  /// 构建加载状态Widget
  Widget buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const RestaurantLoadingWidget(
            size: 40,
            color: Color(0xFFFF9027),
          ),
        ],
      ),
    );
  }
  
  /// 构建骨架图Widget（子类可重写）
  Widget buildSkeletonWidget() {
    return const OrderPageSkeleton();
  }
  
  /// 构建空状态Widget
  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/order_empty.webp',
            width: 180,
            height: 100,
          ),
          const SizedBox(height: 8),
          Text(
            getEmptyStateText(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
          if (getEmptyStateAction() != null) ...[
            const SizedBox(height: 24),
            getEmptyStateAction()!,
          ],
        ],
      ),
    );
  }
  
  /// 构建网络错误状态Widget
  Widget buildNetworkErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/order_nonet.webp',
            width: 180,
            height: 100,
          ),
          const SizedBox(height: 8),
          Text(
            getNetworkErrorText(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
          if (getNetworkErrorAction() != null) ...[
            const SizedBox(height: 24),
            getNetworkErrorAction()!,
          ],
        ],
      ),
    );
  }
  
  /// 构建主体内容
  Widget buildMainContent() {
    return Expanded(
      child: Obx(() {
        // 如果应该显示骨架图且正在加载且没有数据，显示骨架图
        if (shouldShowSkeleton && isLoading && !hasData) {
          return buildSkeletonWidget();
        }

        // 如果正在加载，显示加载动画
        if (isLoading) {
          return buildLoadingWidget();
        }

        // 如果有网络错误，显示网络错误状态
        if (hasNetworkError) {
          return buildNetworkErrorState();
        }

        // 如果没有数据，显示空状态
        if (!hasData) {
          return buildEmptyState();
        }

        return buildDataContent();
      }),
    );
  }
  
  /// 构建数据内容（子类实现）
  Widget buildDataContent();
  
  /// 获取空状态文字（子类可重写）
  String getEmptyStateText() => '暂无数据';
  
  /// 获取网络错误文字（子类可重写）
  String getNetworkErrorText() => '暂无网络';
  
  /// 获取空状态操作按钮（子类可重写）
  Widget? getEmptyStateAction() => null;
  
  /// 获取网络错误状态操作按钮（子类可重写）
  Widget? getNetworkErrorAction() => null;
}

/// 基础详情页面抽象类
/// 统一处理空状态和网络异常展示
abstract class BaseDetailPageWidget extends StatelessWidget {
  const BaseDetailPageWidget({super.key});
}

/// 基础详情页面状态抽象类
abstract class BaseDetailPageState<T extends BaseDetailPageWidget> {
  
  /// 是否正在加载
  bool get isLoading;
  
  /// 是否有网络错误
  bool get hasNetworkError;
  
  /// 是否有数据
  bool get hasData;
  
  /// 刷新数据的方法
  Future<void> onRefresh();
  
  /// 构建加载状态Widget
  Widget buildLoadingWidget() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
  
  /// 构建空状态Widget
  Widget buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/order_empty.webp',
            width: 180,
            height: 100,
          ),
          const SizedBox(height: 8),
          Text(
            getEmptyStateText(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
          if (getEmptyStateAction() != null) ...[
            const SizedBox(height: 24),
            getEmptyStateAction()!,
          ],
        ],
      ),
    );
  }
  
  /// 构建网络错误状态Widget
  Widget buildNetworkErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/order_nonet.webp',
            width: 180,
            height: 100,
          ),
          const SizedBox(height: 8),
          Text(
            getNetworkErrorText(),
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFFF9027),
            ),
          ),
          if (getNetworkErrorAction() != null) ...[
            const SizedBox(height: 24),
            getNetworkErrorAction()!,
          ],
        ],
      ),
    );
  }
  
  /// 构建主体内容
  Widget buildMainContent() {
    return Obx(() {
      if (isLoading && !hasData) {
        return buildLoadingWidget();
      }

      if (hasNetworkError) {
        return buildNetworkErrorState();
      }

      if (!hasData) {
        return buildEmptyState();
      }

      return buildDataContent();
    });
  }
  
  /// 构建数据内容（子类实现）
  Widget buildDataContent();
  
  /// 获取空状态文字（子类可重写）
  String getEmptyStateText() => '暂无数据';
  
  /// 获取网络错误文字（子类可重写）
  String getNetworkErrorText() => '暂无网络';
  
  /// 获取空状态操作按钮（子类可重写）
  Widget? getEmptyStateAction() => null;
  
  /// 获取网络错误状态操作按钮（子类可重写）
  Widget? getNetworkErrorAction() => null;
}
