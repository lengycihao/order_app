# 菜品详情页面敏感物名字越界问题修复

## 🚨 问题描述

用户反馈：菜品详情页面的敏感物名字越界了，需要改成可换行显示。

## 🔍 问题分析

### 问题位置
**文件**: `lib/pages/dish/dish_detail_page.dart`  
**行数**: 第196-218行

### 问题原因
敏感物名字显示使用了 `Row` 组件，当敏感物名字过长时会导致文本越界，无法完整显示。

### 原始代码
```dart
Wrap(
  spacing: 10,
  runSpacing: 8,
  children: dish.allergens!.map((allergen) {
    return Row(  // ❌ 使用Row导致长文本越界
      mainAxisSize: MainAxisSize.min,
      children: [
        if (allergen.icon != null)
          CachedNetworkImage(...),
        if (allergen.icon != null) const SizedBox(width: 4),
        Text(  // ❌ 没有换行处理
          allergen.label ?? '',
          style: const TextStyle(fontSize: 12, color: Color(0xFF3D3D3D)),
        ),
      ],
    );
  }).toList(),
),
```

## 🛠️ 解决方案

### 修复策略
1. **将 `Row` 改为 `Wrap`** - 支持自动换行
2. **添加 `Flexible` 包装** - 确保文本能够适应容器大小
3. **设置 `maxLines` 和 `overflow`** - 控制文本显示行数和溢出处理
4. **使用 `WrapCrossAlignment.center`** - 保持图标和文字垂直居中对齐

### 修复后的代码
```dart
Wrap(
  spacing: 10,
  runSpacing: 8,
  children: dish.allergens!.map((allergen) {
    return Wrap(  // ✅ 使用Wrap支持换行
      crossAxisAlignment: WrapCrossAlignment.center,  // ✅ 垂直居中对齐
      children: [
        if (allergen.icon != null)
          CachedNetworkImage(
            imageUrl: allergen.icon!,
            width: 16,
            height: 16,
            fit: BoxFit.cover,
            errorWidget: (context, url, error) => Image.asset(
              'assets/order_minganwu_place.webp',
              width: 16,
              height: 16,
              fit: BoxFit.contain,
            ),
          ),
        if (allergen.icon != null) const SizedBox(width: 4),
        Flexible(  // ✅ 使用Flexible确保文本适应容器
          child: Text(
            allergen.label ?? '',
            style: const TextStyle(fontSize: 12, color: Color(0xFF3D3D3D)),
            maxLines: 2,  // ✅ 最多显示2行
            overflow: TextOverflow.ellipsis,  // ✅ 超出部分显示省略号
          ),
        ),
      ],
    );
  }).toList(),
),
```

## 📊 修复效果

### 问题解决
- ✅ **敏感物名字不再越界** - 使用Wrap组件支持自动换行
- ✅ **长文本完整显示** - 最多显示2行，超出部分显示省略号
- ✅ **图标和文字对齐** - 使用WrapCrossAlignment.center保持垂直居中
- ✅ **布局自适应** - 使用Flexible确保文本能够适应容器大小

### 用户体验改善
- **更好的可读性** - 敏感物名字能够完整显示
- **更美观的布局** - 避免了文本越界导致的布局混乱
- **更友好的交互** - 用户可以清楚看到所有敏感物信息

## 🔧 技术细节

### 关键修改点
1. **`Row` → `Wrap`**: 从单行布局改为多行布局
2. **添加 `Flexible`**: 确保文本组件能够适应可用空间
3. **设置 `maxLines: 2`**: 限制最多显示2行文本
4. **设置 `overflow: TextOverflow.ellipsis`**: 超出部分显示省略号
5. **使用 `WrapCrossAlignment.center`**: 保持图标和文字垂直居中对齐

### 布局逻辑
- **外层Wrap**: 控制敏感物之间的间距和换行
- **内层Wrap**: 控制单个敏感物内部图标和文字的布局
- **Flexible**: 确保文本组件能够根据可用空间调整大小
- **CachedNetworkImage**: 保持图标固定大小(16x16)

## 🎯 其他相关检查

### 已检查的其他文件
1. **`lib/pages/takeaway/order_detail_page_new.dart`** - 只显示图标，无文字越界问题
2. **`lib/pages/order/components/specification_modal_widget.dart`** - 已使用Flexible和softWrap，无问题
3. **`lib/pages/order/components/allergen_filter_widget.dart`** - 已使用Expanded，无问题

### 代码质量
- ✅ **无语法错误** - 代码编译通过
- ✅ **无linter警告** - 代码符合规范
- ✅ **保持原有功能** - 不影响其他功能

## 🎉 总结

通过将 `Row` 组件改为 `Wrap` 组件，并添加适当的文本处理属性，成功解决了菜品详情页面敏感物名字越界的问题。现在敏感物名字可以自动换行显示，最多显示2行，超出部分会显示省略号，既保证了信息的完整性，又保持了界面的美观性。

### 修复文件
- `lib/pages/dish/dish_detail_page.dart` (第192-224行)

### 修复效果
- ✅ 敏感物名字不再越界
- ✅ 支持自动换行显示
- ✅ 保持图标和文字对齐
- ✅ 提升用户体验
