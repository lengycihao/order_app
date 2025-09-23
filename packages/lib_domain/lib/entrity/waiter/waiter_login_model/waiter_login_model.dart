import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
part 'waiter_login_model.g.dart';

@JsonSerializable()
class WaiterLoginModel {
  String? token;
  @JsonKey(name: 'waiter_id')
  int? waiterId;
  @JsonKey(name: 'waiter_name')
  String? waiterName;
  @JsonKey(name: 'language_code')
  String? languageCode;
  @JsonKey(name: 'avatar')
  String? avatar;

  WaiterLoginModel({
    this.token,
    this.waiterId,
    this.waiterName,
    this.languageCode,
    this.avatar,
  });

  factory WaiterLoginModel.fromRawJson(String str) =>
      WaiterLoginModel.fromJson(json.decode(str));

  String toRawJson() => json.encode(toJson());
  factory WaiterLoginModel.fromJson(Map<String, dynamic> json) {
    return _$WaiterLoginModelFromJson(json);
  }

  Map<String, dynamic> toJson() => _$WaiterLoginModelToJson(this);
}
