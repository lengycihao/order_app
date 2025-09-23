class TakeoutTimeOptionModel {
  final int currentTime;
  final List<TakeoutTimeOptionItem> options;

  TakeoutTimeOptionModel({
    required this.currentTime,
    required this.options,
  });

  factory TakeoutTimeOptionModel.fromJson(Map<String, dynamic> json) {
    return TakeoutTimeOptionModel(
      currentTime: json['current_time'] as int,
      options: (json['options'] as List)
          .map((item) => TakeoutTimeOptionItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'current_time': currentTime,
      'options': options.map((item) => item.toJson()).toList(),
    };
  }
}

class TakeoutTimeOptionItem {
  final int value;
  final String label;

  TakeoutTimeOptionItem({
    required this.value,
    required this.label,
  });

  factory TakeoutTimeOptionItem.fromJson(Map<String, dynamic> json) {
    return TakeoutTimeOptionItem(
      value: json['value'] as int,
      label: json['label'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'label': label,
    };
  }
}
