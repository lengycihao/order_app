import 'package:json_annotation/json_annotation.dart';
import 'menu_fixed_cost.dart';

part 'table_menu_list_model.g.dart';

@JsonSerializable()
class TableMenuListModel {
  @JsonKey(name: 'menu_id')
  String? menuId;
  @JsonKey(name: 'menu_name')
  String? menuName;
  @JsonKey(name: 'menu_type')
  int? menuType;
  @JsonKey(name: 'menu_image')
  String? menuImage;
  @JsonKey(name: 'adult_package_price')
  String? adultPackagePrice;
  @JsonKey(name: 'child_package_price')
  String? childPackagePrice;
  @JsonKey(name: 'week_range')
  String? weekRange;
  @JsonKey(name: 'menu_fixed_costs')
  List<MenuFixedCost>? menuFixedCosts;

  TableMenuListModel({
    this.menuId,
    this.menuName,
    this.menuType,
    this.menuImage,
    this.adultPackagePrice,
    this.childPackagePrice,
    this.weekRange,
    this.menuFixedCosts,
  });

  factory TableMenuListModel.fromJson(Map<String, dynamic> json) {
    return _$TableMenuListModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$TableMenuListModelToJson(this);
}
