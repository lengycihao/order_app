import 'package:json_annotation/json_annotation.dart';

import 'item.dart';

part 'dish_list_model.g.dart';

@JsonSerializable()
class DishListModel {
  int? id;
  String? name;
  List<Item>? items;

  DishListModel({this.id, this.name, this.items});

  factory DishListModel.fromJson(Map<String, dynamic> json) {
    return _$DishListModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$DishListModelToJson(this);
}
