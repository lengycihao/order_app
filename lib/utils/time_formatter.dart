/// 时间格式化工具类
class TimeFormatter {
  /// 将秒数转换为 HH:mm:ss 格式
  static String formatDuration(int seconds) {
    if (seconds < 0) return "00:00:00";
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
  }
  
  /// 将秒数转换为简化的时间格式
  /// 如果小于1小时，显示 mm:ss
  /// 如果大于等于1小时，显示 HH:mm:ss
  static String formatDurationShort(int seconds) {
    if (seconds < 0) return "00:00";
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    
    if (hours > 0) {
      return "${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
    } else {
      return "${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}";
    }
  }
  
  /// 将秒数转换为桌台时间格式 (23h43m)
  static String formatTableTime(int seconds) {
    if (seconds < 0) return "0h0m";
    
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    return "${hours}h${minutes}m";
  }
  
  /// 将数字类型的时间戳转换为桌台时间格式
  static String formatTableTimeFromNum(num duration) {
    return formatTableTime(duration.toInt());
  }
  
  /// 将数字类型的时间戳转换为格式化字符串
  static String formatDurationFromNum(num duration) {
    return formatDuration(duration.toInt());
  }
  
  /// 将数字类型的时间戳转换为简化格式
  static String formatDurationShortFromNum(num duration) {
    return formatDurationShort(duration.toInt());
  }
}
