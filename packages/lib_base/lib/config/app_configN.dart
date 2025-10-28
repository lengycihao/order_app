
/// 环境类型枚举
enum Environment {
  /// 本地环境
  local,
  /// 测试环境
  test,
  /// 正式环境
  production,
}

/// 环境配置扩展
extension EnvironmentExtension on Environment {
  /// 获取环境名称
  String get name {
    switch (this) {
      case Environment.local:
        return 'local';
      case Environment.test:
        return 'test';
      case Environment.production:
        return 'production';
    }
  }

  /// 获取基础API URL
  String get baseUrl {
    switch (this) {
      case Environment.local:
        return 'http://192.168.110.140:8080';
      case Environment.test:
        return 'http://test.api.oh06.com';
      case Environment.production:
        return 'http://129.204.154.113:8050';
    }
  }

  /// 获取WebSocket URL
  String get baseWsUrl {
    switch (this) {
      case Environment.local:
        return 'ws://192.168.110.140:8080/api/waiter/ws';
      case Environment.test:
        return 'ws://test.api.oh06.com/api/waiter/ws';
      case Environment.production:
        return 'ws://129.204.154.113:8050/api/waiter/ws';
    }
  }

  /// 是否为测试环境（用于加密等配置）
  bool get isTest {
    return this == Environment.test || this == Environment.local;
  }
}

class AppConfigN {
  /// 当前环境
  static Environment _currentEnvironment = Environment.test;

  /// 获取当前环境
  static Environment get currentEnvironment => _currentEnvironment;

  /// 设置当前环境
  static void setEnvironment(Environment environment) {
    _currentEnvironment = environment;
  }

  /// 服务环境（兼容旧代码）
  /// 测试环境:true
  /// 生产环境:false
  static bool get serverEnvironmentTest => _currentEnvironment.isTest;

  /// api 加密开关
  /// 测试环境和本地环境不加密，生产环境加密
  static bool get apiEncrypt => !_currentEnvironment.isTest;

  /// 渠道
  /// 0 内部测试
  /// 1 苹果
  /// 2 小米
  /// 3 华为
  /// 4 VIVO
  /// 5 OPPO
  /// 6 荣耀
  /// 7 应用宝
  /// 8 官网
  // static late final int appChannel;

  // /// CPU架构
  // static late final String abiFilters;

  // /// 版本号
  // static late final String appVersion;

  /// 获取当前环境的API基础URL
  static String get baseApiUrl => _currentEnvironment.baseUrl;
  
  /// 获取当前环境的WebSocket基础URL
  static String get baseWsUrl => _currentEnvironment.baseWsUrl;
  // static late final String baseWebUrl;
  // static late final String baseH5Url;

  // // zego参数
  // static late final int zegoAppId;
  // static late final String zegoAppSign;

  // // oss
  // static late final String ossBucketName;

  // // api encrypt key pair
  // static const apiAesKey1 = 'M9rA0ehv1A';
  // static const apiAesKey2 = 'JgczDtgkvoA';

  // // app build time
  // static const appBuildTime = '';
  // static const appleStoreId = '6742088748';

  /// 配置应用环境
  /// [environment] 环境类型，默认为测试环境
  /// [urlType] 兼容旧版本参数，已废弃
  static Future configuration({
    Environment? environment,
    @Deprecated('使用 environment 参数代替') String urlType = 'test'
  }) async {
    // 如果没有指定环境，根据urlType参数设置（兼容旧代码）
    if (environment != null) {
      setEnvironment(environment);
    } else {
      // 兼容旧版本的urlType参数
      switch (urlType) {
        case 'local':
          setEnvironment(Environment.local);
          break;
        case 'test':
          setEnvironment(Environment.test);
          break;
        case 'production':
        case 'prod':
          setEnvironment(Environment.production);
          break;
        default:
          setEnvironment(Environment.test);
      }
    }

    // ossBucketName = "yvoice-app";
    // baseWebUrl = 'https://protocol.syyimeng.com';
    // appChannel = const int.fromEnvironment('app_channel', defaultValue: 0);
    // abiFilters = const String.fromEnvironment('abiFilters', defaultValue: '');
    // PackageInfo packageInfo = await PackageInfo.fromPlatform();
    // appVersion = packageInfo.version;

    print('当前环境: ${_currentEnvironment.name}');
    print('API地址: ${baseApiUrl}');
    print('WebSocket地址: ${baseWsUrl}');
  }

  /// 便捷方法：设置为本地环境
  static Future configureLocal() async {
    await configuration(environment: Environment.local);
  }

  /// 便捷方法：设置为测试环境
  static Future configureTest() async {
    await configuration(environment: Environment.test);
  }

  /// 便捷方法：设置为生产环境
  static Future configureProduction() async {
    await configuration(environment: Environment.production);
  }
// http://test.api.oh06.com
  ///
  /// h5 url

  // // 用户服务协议
  // static String userServiceDescription =
  //     "$baseWebUrl/userServiceDescription.html";

  // // 隐私政策
  // static String privacyPolicy = "$baseWebUrl/privacyPolicy.html";

  // // 云顶币充值协议
  // static String coinRechargeAgreement =
  //     "$baseWebUrl/coinRechargeAgreement.html";

  // // 个人信息收集类型
  // static String personalInformationCollection =
  //     "$baseWebUrl/personalInformationCollection.html";

  // // 应用权限说明
  // static String applicationPermissionsDescription =
  //     "$baseWebUrl/applicationPermissionsDescription.html";

  // // 信息发布规范
  // static String informationReleaseStandards =
  //     "$baseWebUrl/informationReleaseStandards.html";

  // // 隐私保护指引
  // static String privacyProtectionGuidelines =
  //     "$baseWebUrl/privacyProtectionGuidelines.html";

  // // 未成年人隐私保护协议
  // static String teenagersPrivacyAgreement =
  //     "$baseWebUrl/teenagersPrivacyAgreement.html";

  // //用户注销协议
  // static String accountCancellation = '$baseWebUrl/accountCancellation.html';

  // //人脸验证服务协议
  // static String faceRecognition = '$baseWebUrl/faceRecognition.html';
}
