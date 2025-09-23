# Toast提示组件使用指南

## 概述

`ToastComponent` 是一个统一的提示组件，提供错误和成功两种样式，在屏幕中间显示，具有统一的视觉风格。

## 特性

- ✅ **两种样式**：错误提示（红色背景）和成功提示（绿色背景）
- ✅ **屏幕居中**：提示框在屏幕中间显示
- ✅ **自适应尺寸**：高度36px，最大宽度270px，最小高度36px
- ✅ **图标支持**：错误显示 `order_error.webp`，成功显示 `order_success.webp`
- ✅ **动画效果**：淡入淡出和滑动动画
- ✅ **点击隐藏**：点击Toast或背景可手动隐藏
- ✅ **自动隐藏**：默认2秒后自动消失

## 样式规范

### 错误提示
- 背景色：`#FFF0F0`
- 图标：`assets/order_error.webp`
- 文字：12pt，颜色 `#333333`

### 成功提示
- 背景色：`#F0FFF0`
- 图标：`assets/order_success.webp`
- 文字：12pt，颜色 `#333333`

### 尺寸规范
- 高度：36px
- 最大宽度：270px
- 最小高度：36px
- 圆角：8px
- 阴影：轻微阴影效果

## 使用方法

### 1. 基本用法

```dart
import 'package:order_app/utils/toast_utils.dart';

// 显示错误提示
Toast.error(context, '操作失败，请重试');

// 显示成功提示
Toast.success(context, '操作成功！');
```

### 2. 自定义持续时间

```dart
// 显示3秒的错误提示
Toast.error(
  context, 
  '网络连接超时', 
  duration: Duration(seconds: 3),
);

// 显示1秒的成功提示
Toast.success(
  context, 
  '保存成功', 
  duration: Duration(seconds: 1),
);
```

### 3. 手动隐藏Toast

```dart
// 隐藏当前显示的Toast
Toast.hide();
```

### 4. 全局Toast（不依赖Context）

```dart
import 'package:order_app/utils/toast_utils.dart';

// 在应用启动时设置全局Context
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    GlobalToast.setContext(context);
    return MaterialApp(
      // ... 其他配置
    );
  }
}

// 在任何地方使用全局Toast
GlobalToast.error('网络错误');
GlobalToast.success('操作成功');
```

## API参考

### Toast类

| 方法 | 参数 | 说明 |
|------|------|------|
| `error(context, message, {duration})` | context, message, duration | 显示错误提示 |
| `success(context, message, {duration})` | context, message, duration | 显示成功提示 |
| `hide()` | 无 | 隐藏当前Toast |

### GlobalToast类

| 方法 | 参数 | 说明 |
|------|------|------|
| `setContext(context)` | context | 设置全局Context |
| `error(message, {duration})` | message, duration | 显示错误提示 |
| `success(message, {duration})` | message, duration | 显示成功提示 |
| `hide()` | 无 | 隐藏当前Toast |

## 最佳实践

### 1. 错误提示使用场景
- 网络请求失败
- 表单验证错误
- 操作权限不足
- 系统错误

### 2. 成功提示使用场景
- 数据保存成功
- 操作完成确认
- 状态更新成功
- 用户操作反馈

### 3. 文案建议
- **简洁明了**：提示信息要简短，一目了然
- **用户友好**：使用用户能理解的语言
- **避免重复**：相同操作不要重复显示相同提示

### 4. 使用示例

```dart
// 网络请求错误
Toast.error(context, '网络连接失败，请检查网络设置');

// 表单验证错误
Toast.error(context, '请输入正确的手机号码');

// 操作成功
Toast.success(context, '订单提交成功');

// 数据保存成功
Toast.success(context, '设置已保存');
```

## 注意事项

1. **Context依赖**：Toast需要有效的BuildContext，确保在Widget树中使用
2. **图片资源**：确保 `assets/order_error.webp` 和 `assets/order_success.webp` 存在
3. **同时显示**：同时只能显示一个Toast，新的Toast会替换旧的
4. **内存管理**：Toast会自动清理，无需手动管理内存

## 测试

运行测试页面查看效果：

```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => TestToastPage()),
);
```

测试页面包含：
- 错误提示测试
- 成功提示测试
- 长文本测试
- 隐藏功能测试
- 使用说明展示
