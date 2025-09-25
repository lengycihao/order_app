import 'package:dio/dio.dart';

class ApiInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // int timestamp = DateTime.now().millisecondsSinceEpoch;
    // options.headers.addAll({
    //   "OS": defaultTargetPlatform.name.toLowerCase(),
    //   "Timestamp": timestamp,
    //   "Sign": _getRequestSign(timestamp),
    //   "AppVersion": AppConfig.appVersion,
    //   "Device": MMAppGlobalManager.instance.deviceName,
    //   "DeviceId":
    //       MMAppGlobalManager.instance.deviceId.isNotEmpty
    //           ? MMAppGlobalManager.instance.deviceId
    //           : timestamp.toString(),
    //   "AppChannel": AppConfig.appChannel,
    //   //测试环境 & 测试渠道：关闭加密
    //   if (!AppConfig.apiEncrypt) "Ft": "5",
    // });

    // if (AppConfig.apiEncrypt && options.data != null) {
    //   String oraginalStr =
    //       (options.data is Map) ? json.encode(options.data) : options.data;
    //   String paramsStr = _encryptAES(oraginalStr);
    //   options.data = paramsStr;
    // }

    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    super.onResponse(response, handler);
  }

  // String _getRequestSign(int timestamp) {
  //   //测试环境关闭加密
  //   if (!AppConfig.apiEncrypt) {
  //     return '';
  //   }
  //   String tempStr = '${MMAppGlobalManager.instance.deviceId}$timestamp';
  //   String encryptStr = _encryptAES(tempStr);
  //   return encryptStr;
  // }

  // /// Request AES加密
  // String _encryptAES(String plaintext) {
  //   if (plaintext.isEmpty) return '';
  //   // AES加密要求密钥长度为16, 24, 或 32字节
  //   final Uint8List key = Uint8List.fromList(
  //     '${AppConfig.apiAesKey1}+${AppConfig.apiAesKey2}=='.codeUnits,
  //   );
  //   // 确保密钥长度符合AES要求，例如16字节对应AES-128, 24字节对应AES-192, 32字节对应AES-256
  //   if (key.length != 16 && key.length != 24 && key.length != 32) {}
  //   final aes = encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.ecb);
  //   encrypt.Encrypted encryptedBytes = aes.encrypt(utf8.encode(plaintext));
  //   // 将加密后的字节转换为Base64字符串
  //   final encryptedStr = base64.encode(encryptedBytes.bytes);
  //   String encryptedString = Uri.encodeQueryComponent(encryptedStr);
  //   return encryptedString;
  // }

  // /// Response AES解密
  // String _decryptAES(String encryptedString) {
  //   if (encryptedString.isEmpty) return '';
  //   // AES加密要求密钥长度为16, 24, 或 32字节
  //   final Uint8List key = Uint8List.fromList(
  //     '${AppConfig.apiAesKey1}+${AppConfig.apiAesKey2}=='.codeUnits,
  //   );
  //   // 确保密钥长度符合AES要求，例如16字节对应AES-128, 24字节对应AES-192, 32字节对应AES-256
  //   if (key.length != 16 && key.length != 24 && key.length != 32) {}
  //   final aes = encrypt.AES(encrypt.Key(key), mode: encrypt.AESMode.ecb);
  //   // 将Base64字符串转换为加密后的字节
  //   final encryptedBytes = encrypt.Encrypted.fromBase64(encryptedString);
  //   // 解密
  //   final decryptedBytes = aes.decrypt(encryptedBytes);
  //   // 将解密后的字节转换为UTF-8字符串
  //   final decryptedStr = utf8.decode(decryptedBytes);
  //   return decryptedStr;
  // }
}
