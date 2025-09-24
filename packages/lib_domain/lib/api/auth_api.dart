import 'package:lib_domain/entrity/waiter/waiter_login_model/waiter_login_model.dart';
import 'package:lib_base/network/http_managerN.dart';
import 'package:lib_base/lib_base.dart' hide HttpManagerN;
import '../cons/api_request.dart';

class AuthApi {
  Future<HttpResultN<WaiterLoginModel>> _login({
    String? phoneNumber,
    String? password,
    String? lan = "cn",
  }) async {
    final params = {
      if (phoneNumber != null) "account": phoneNumber,
      if (password != null) "password": password,
      // "language_code": lan,
    };
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.authLoginByCode,
      jsonParam: params,
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      return result.convert(
        data: WaiterLoginModel.fromJson(result.getDataJson()),
      );
    } else {
      return result.convert();
    }

    // return HttpResultN(
    //   isSuccess: result.isSuccess,
    //   code: result.code,
    //   msg: result.msg,
    // );
  }

  // /// 一键登录
  // Future<HttpResultN<AuthAccountModel>> loginWithOneClick(
  //     {required String idToken, bool isReactiveAccount = false}) async {
  //   return await _login(loginType: 20, idToken: idToken, isReactiveAccount: isReactiveAccount);
  // }

  // /// apple登录
  // Future<HttpResultN<AuthAccountModel>> loginWithApple(
  //     {required String idToken, bool isReactiveAccount = false}) async {
  //   return await _login(loginType: 2, idToken: idToken, isReactiveAccount: isReactiveAccount);
  // }

  /// password登录
  Future<HttpResultN<WaiterLoginModel>> loginWithPassword({
    required String phoneNumber,
    required String password,
    String? lan,
  }) async {
    return await _login(password: password, phoneNumber: phoneNumber, lan: lan);
  }

  // /// 第三方登录
  // Future<HttpResultN<AuthAccountModel>> requestThird(
  //     {required String idToken,
  //     required int thirdAccountType,
  //     bool reactiveAccount = false}) async {
  //   return await _login(
  //       loginType: thirdAccountType, idToken: idToken, isReactiveAccount: reactiveAccount);
  // }

  // /// 刷新登录信息
  // Future<HttpResultN<AuthAccountModel>> refreshLogin() async {
  //   final result = await HttpManager.instance.executePost(
  //     ApiRequest.authRefreshByToken,
  //     paramEncrypt: false,
  //   );

  //   // 转换为AuthAccountModel
  //   return result.asModel<AuthAccountModel>(AuthAccountModel.fromJson);
  // }

  /// 修改密码
  Future<HttpResultN<void>> changePassword({
    required String newPassword,
  }) async {
    final params = {
      "new_password": newPassword,
    };
    
    final result = await HttpManagerN.instance.executePost(
      ApiRequest.changePassword,
      jsonParam: params,
      paramEncrypt: false,
    );

    if (result.isSuccess) {
      return result.convert();
    } else {
      return result.convert();
    }
  }
}
