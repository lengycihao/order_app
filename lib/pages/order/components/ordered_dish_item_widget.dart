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
            color: Colors.black,
          ),
          maxLines: 5,
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
            dish.optionsStr!,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        SizedBox(height: 4),
        // 烹饪状态标签
        if (dish.cookingStatusName != null && dish.cookingStatusName!.isNotEmpty)
          Container(
            margin: EdgeInsets.only(top: 4),
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Color(0xFFFF9027).withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              dish.cookingStatusName!,
              style: TextStyle(
                fontSize: 12,
                color: Color(0xFFFF9027),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  /// 构建过敏原信息（只显示图片，不显示文字和背景）
  Widget _buildAllergens() {
    // 过滤掉空的敏感物数据
    final validAllergens = dish.allergens!.where((allergen) => 
      allergen.icon != null && allergen.icon!.isNotEmpty
    ).toList();
    
    if (validAllergens.isEmpty) {
      return SizedBox.shrink();
    }
    
    return Wrap(
      spacing: 4,
      runSpacing: 2,
      children: validAllergens.take(3).map((allergen) {
        return Container(
          margin: EdgeInsets.only(right: 4),
          child: CachedNetworkImage(
            imageUrl: allergen.icon!,
            width: 16,
            height: 16,
            fit: BoxFit.contain,
            placeholder: (context, url) => Icon(
              Icons.warning,
              size: 16,
              color: Colors.orange,
            ),
            errorWidget: (context, url, error) => Icon(
              Icons.warning,
              size: 16,
              color: Colors.orange,
            ),
          ),
        );
      }).toList(),
    );
  }


  /// 构建价格和数量
  Widget _buildPriceAndQuantity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 价格
        Text(
          '¥${_formatPrice(dish.unitPrice ?? 0)}',
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
    return price.toString();
  }
}
