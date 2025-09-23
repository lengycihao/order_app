void main() {
  // 测试 _isNumeric 方法
  bool _isNumeric(String str) {
    if (str.isEmpty) return false;
    return RegExp(r'^\d+$').hasMatch(str);
  }
  
  // 测试用例
  print('=== 测试 _isNumeric 方法 ===');
  print('_isNumeric("1"): ${_isNumeric("1")}'); // 应该是 true
  print('_isNumeric("123"): ${_isNumeric("123")}'); // 应该是 true  
  print('_isNumeric("a1"): ${_isNumeric("a1")}'); // 应该是 false
  print('_isNumeric(""): ${_isNumeric("")}'); // 应该是 false
  
  // 测试去前导零逻辑
  print('\n=== 测试去前导零逻辑 ===');
  String testPickupCode = "0002";
  String testKeyword = "1";
  
  final normalizedPickupCode = testPickupCode.replaceFirst(RegExp(r'^0+'), '');
  final normalizedKeyword = testKeyword.replaceFirst(RegExp(r'^0+'), '');
  
  print('原始取餐码: $testPickupCode');
  print('标准化取餐码: $normalizedPickupCode');
  print('原始关键词: $testKeyword');  
  print('标准化关键词: $normalizedKeyword');
  
  bool exactMatch = normalizedPickupCode == normalizedKeyword;
  bool prefixMatch = normalizedPickupCode.startsWith(normalizedKeyword);
  
  print('精确匹配: $exactMatch');
  print('前缀匹配: $prefixMatch');
  print('最终匹配结果: ${exactMatch || prefixMatch}');
  
  // 测试多个取餐码
  print('\n=== 测试多个取餐码匹配 ===');
  List<String> pickupCodes = ["0001", "0002", "0004", "0005", "0010", "1000"];
  String searchKeyword = "1";
  
  for (String pickupCode in pickupCodes) {
    final normalized = pickupCode.replaceFirst(RegExp(r'^0+'), '');
    final keywordNormalized = searchKeyword.replaceFirst(RegExp(r'^0+'), '');
    
    bool shouldMatch = normalized == keywordNormalized || normalized.startsWith(keywordNormalized);
    print('取餐码 $pickupCode -> 标准化: $normalized -> 匹配: $shouldMatch');
  }
}
