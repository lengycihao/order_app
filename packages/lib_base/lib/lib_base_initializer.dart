// import 'package:flutter/foundation.dart';
// import 'config/app_config.dart';
// import 'network/http_manager.dart';
// import 'logging/log_manager.dart';
// import 'logging/log_config.dart';
// import 'logging/log_level.dart';
// import 'utils/device_util.dart';

// class LibBaseInitializer {
//   static bool _isInitialized = false;
//   static bool get isInitialized => _isInitialized;

//   static Future<void> initialize({
//     required String appId,
//     required String httpUrl,
//     required String wsUrl,
//     required ResponseConfig responseConfig,
//     required String ossBucketName,
//     LogConfig? logConfig,
//     String? appVersion,
//     String? appChannel,
//     bool? apiEncrypt,
//     String? apiAesKey1,
//     String? apiAesKey2,
//   }) async {
//     if (_isInitialized) {
//       if (kDebugMode) {
//         print('LibBase already initialized, skipping...');
//       }
//       return;
//     }

//     try {
//       // 初始化AppConfig
//       AppConfig.initialize(
//         appId: appId,
//         httpUrl: httpUrl,
//         wsUrl: wsUrl,
//         responseConfig: responseConfig,
//         ossBucketName: ossBucketName,
//         appVersion: appVersion,
//         appChannel: appChannel,
//         apiEncrypt: apiEncrypt,
//         apiAesKey1: apiAesKey1,
//         apiAesKey2: apiAesKey2,
//       );

//       // 初始化日志工具
//       await _initializeLogUtil(logConfig);

//       // 初始化设备工具
//       await _initializeDeviceUtil();

//       // 初始化其他组件
//       await _initializeNetworkComponents();
//       await _initializeStorageComponents();

//       _isInitialized = true;

//       if (kDebugMode) {
//         print('LibBase initialization completed successfully');
//         print('AppConfig: ${AppConfig.instance}');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('LibBase initialization failed: $e');
//       }
//       rethrow;
//     }
//   }

//   static Future<void> _initializeLogUtil(LogConfig? config) async {
//     try {
//       final logConfig =
//           config ??
//           LogConfig(
//             enableConsoleLog: kDebugMode,
//             enableFileLog: true,
//             enableUpload: false,
//             minLevel: kDebugMode ? LogLevel.debug : LogLevel.info,
//             minFileLevel: LogLevel.info,
//             minUploadLevel: LogLevel.error,
//             logDir: 'logs',
//             logFileName: 'app.log',
//             maxFileSize: 10 * 1024 * 1024, // 10MB
//             maxFileCount: 5,
//             compressLogs: true,
//           );

//       await LogManager.instance.initialize(logConfig);

//       logger.info('Log system initialized successfully', tag: 'LibBase');
//       logger.debug(
//         'Log configuration: Console=${logConfig.enableConsoleLog}, File=${logConfig.enableFileLog}, Upload=${logConfig.enableUpload}',
//         tag: 'LibBase',
//       );
//     } catch (e) {
//       if (kDebugMode) {
//         print('Log utility initialization failed: $e');
//       }
//       rethrow;
//     }
//   }

//   static Future<void> _initializeDeviceUtil() async {
//     try {
//       await DeviceUtil.instance.initialize();
//       logger.info('Device utility initialized', tag: 'LibBase');
//     } catch (e) {
//       logger.error(
//         'Device utility initialization failed',
//         tag: 'LibBase',
//         error: e,
//       );
//       // Continue execution as device util has fallback values
//     }
//   }

//   static Future<void> _initializeNetworkComponents() async {
//     try {
//       final config = AppConfig.instance;

//       // 初始化HttpManager
//       HttpManager.instance.init(
//         config.httpUrl,
//         enableCache: true,
//         enableEncryption: false,
//         enableDebounce: true,
//         enableApiInterceptor: true,
//         connectTimeout: const Duration(seconds: 30),
//         receiveTimeout: const Duration(seconds: 30),
//         sendTimeout: const Duration(seconds: 30),
//       );

//       logger.info(
//         'Network components initialized',
//         tag: 'LibBase',
//         extra: {'httpUrl': config.httpUrl, 'wsUrl': config.wsUrl},
//       );
//     } catch (e) {
//       logger.error(
//         'Network components initialization failed',
//         tag: 'LibBase',
//         error: e,
//       );
//       rethrow;
//     }
//   }

//   static Future<void> _initializeStorageComponents() async {
//     try {
//       // TODO: 初始化存储组件
//       // SharedPreferences、文件缓存等的初始化
//       if (kDebugMode) {
//         print('Storage components initialized');
//       }
//     } catch (e) {
//       if (kDebugMode) {
//         print('Storage components initialization failed: $e');
//       }
//     }
//   }

//   /// 获取HttpManager实例（确保已初始化）
//   static HttpManager get httpManager {
//     if (!_isInitialized) {
//       throw StateError(
//         'LibBase not initialized. Call LibBaseInitializer.initialize() first.',
//       );
//     }
//     return HttpManager.instance;
//   }

//   /// 获取LogManager实例（确保已初始化）
//   static LogManager get logManager {
//     if (!_isInitialized) {
//       throw StateError(
//         'LibBase not initialized. Call LibBaseInitializer.initialize() first.',
//       );
//     }
//     return LogManager.instance;
//   }

//   /// 更新网络配置
//   static void updateNetworkConfig({
//     String? newHttpUrl,
//     bool? enableCache,
//     bool? enableEncryption,
//   }) {
//     if (!_isInitialized) {
//       throw StateError(
//         'LibBase not initialized. Call LibBaseInitializer.initialize() first.',
//       );
//     }

//     if (newHttpUrl != null) {
//       HttpManager.instance.updateBaseUrl(newHttpUrl);
//     }

//     logger.info('Network configuration updated', tag: 'LibBase');
//   }

//   /// 清理网络缓存
//   static void clearNetworkCache() {
//     if (!_isInitialized) return;

//     HttpManager.instance.clearCache();
//     HttpManager.instance.clearDebounceCache();

//     if (kDebugMode) {
//       print('Network cache cleared');
//     }
//   }
// }
