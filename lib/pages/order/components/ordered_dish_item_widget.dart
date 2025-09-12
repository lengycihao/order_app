import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lib_domain/entrity/order/ordered_dish_model.dart';

class OrderedDishItemWidget extends StatelessWidget {
  final OrderedDishModel dish;
  final bool isLast;

  const OrderedDishItemWidget({
    Key? key,
    required this.dish,
    this.isLast = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 菜品图片
          _buildDishImage(),
          SizedBox(width: 12),
          // 菜品信息
          Expanded(
            child: _buildDishInfo(),
          ),
          // 价格和数量
          _buildPriceAndQuantity(),
        ],
      ),
    );
  }

  /// 构建菜品图片
  Widget _buildDishImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey[100],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: dish.image != null && dish.image!.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: dish.image!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[200],
                  child: Icon(
                    Icons.restaurant,
                    color: Colors.grey[400],
                    size: 24,
                  ),
                ),
              )
            : Container(
                color: Colors.grey[200],
                child: Icon(
                  Icons.restaurant,
                  color: Colors.grey[400],
                  size: 24,
                ),
              ),
      ),
    );
  }

  /// 构建菜品信息
  Widget _buildDishInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 菜品名称
        Text(
          dish.name ?? '未知菜品',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: 4),
       // 过敏原信息
        if (dish.allergens != null && dish.allergens!.isNotEmpty)
          _buildAllergens(),
        SizedBox(height: 4),
        
           // 选项信息
        if (dish.optionsStr != null && dish.optionsStr!.isNotEmpty)
          Text(
            '规格：${dish.optionsStr!}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        SizedBox(height: 4),
        // 烹饪状态
        _buildCookingStatus(),
      ],
    );
  }

  /// 构建过敏原信息
  Widget _buildAllergens() {
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: dish.allergens!.take(3).map((allergen) {
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.orange[200]!,
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 过敏原图标
              if (allergen.icon != null && allergen.icon!.isNotEmpty)
                Container(
                  width: 12,
                  height: 12,
                  margin: EdgeInsets.only(right: 4),
                  child: CachedNetworkImage(
                    imageUrl: allergen.icon!,
                    fit: BoxFit.contain,
                    placeholder: (context, url) => Icon(
                      Icons.warning,
                      size: 10,
                      color: Colors.orange[700],
                    ),
                    errorWidget: (context, url, error) => Icon(
                      Icons.warning,
                      size: 10,
                      color: Colors.orange[700],
                    ),
                  ),
                )
              else
                Icon(
                  Icons.warning,
                  size: 10,
                  color: Colors.orange[700],
                ),
              // 过敏原文字
              Text(
                allergen.label ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// 构建烹饪状态
  Widget _buildCookingStatus() {
    String statusText = '配菜中';
    Color statusColor = Colors.orange;
    
    if (dish.cookingStatusName != null && dish.cookingStatusName!.isNotEmpty) {
      statusText = dish.cookingStatusName!;
    }
    
    // 根据状态设置颜色
    switch (dish.cookingStatus) {
      case 0:
        statusText = '待处理';
        statusColor = Colors.grey;
        break;
      case 1:
        statusText = '配菜中';
        statusColor = Colors.orange;
        break;
      case 2:
        statusText = '制作中';
        statusColor = Colors.blue;
        break;
      case 3:
        statusText = '已完成';
        statusColor = Colors.green;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(
        //   color: statusColor.withOpacity(0.3),
        //   width: 0.5,
        // ),
      ),
      child: Text(
        statusText,
        style: TextStyle(
          fontSize: 11,
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// 构建价格和数量
  Widget _buildPriceAndQuantity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 价格
        Text(
          '¥${_formatPrice(dish.price ?? dish.unitPrice ?? 0)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 4),
        // 数量
        Text(
          'x${dish.quantity ?? 1}',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
        ),
      ],
    );
  }

  /// 格式化价格
  String _formatPrice(double price) {
    if (price == price.toInt()) {
      return price.toInt().toString();
    } else {
      return price.toStringAsFixed(2);
    }
  }
}
