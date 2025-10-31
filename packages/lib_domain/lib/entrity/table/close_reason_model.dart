/// 关桌原因模型
class CloseReasonModel {
  final String label;
  final String value;

  CloseReasonModel({
    required this.label,
    required this.value,
  });

  factory CloseReasonModel.fromJson(Map<String, dynamic> json) {
    return CloseReasonModel(
      label: json['label'] ?? '',
      value: json['value'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
    };
  }
}

