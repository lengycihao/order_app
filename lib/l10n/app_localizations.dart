import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
    Locale('zh'),
  ];

  /// 应用程序标题
  ///
  /// In zh, this message translates to:
  /// **'欧华餐饮系统(服务员)'**
  String get appTitle;

  /// 请输入登录名
  ///
  /// In zh, this message translates to:
  /// **'请输入登录名'**
  String get pleaseEnterLoginName;

  /// 请输入密码
  ///
  /// In zh, this message translates to:
  /// **'请输入密码'**
  String get pleaseEnterPassword;

  /// 登录
  ///
  /// In zh, this message translates to:
  /// **'登录'**
  String get login;

  /// 版权信息
  ///
  /// In zh, this message translates to:
  /// **'©2025 欧华智创（杭州）科技有限公司'**
  String get copyright;

  /// 登录名不能为空
  ///
  /// In zh, this message translates to:
  /// **'登录名不能为空'**
  String get loginNameCannotBeEmpty;

  /// 密码不能为空
  ///
  /// In zh, this message translates to:
  /// **'密码不能为空'**
  String get passwordCannotBeEmpty;

  /// 用户名或密码错误
  ///
  /// In zh, this message translates to:
  /// **'用户名或密码错误'**
  String get incorrectPassword;

  /// 登录成功
  ///
  /// In zh, this message translates to:
  /// **'登录成功'**
  String get loginSuccessful;

  /// 登录失败，请重试
  ///
  /// In zh, this message translates to:
  /// **'登录失败，请重试'**
  String get loginFailedPleaseRetry;

  /// 账号已在其他设备登录
  ///
  /// In zh, this message translates to:
  /// **'账号已在其他设备登录'**
  String get accountLoggedInOnAnotherDevice;

  /// 桌台
  ///
  /// In zh, this message translates to:
  /// **'桌台'**
  String get table;

  /// 更多
  ///
  /// In zh, this message translates to:
  /// **'更多'**
  String get more;

  /// 并桌
  ///
  /// In zh, this message translates to:
  /// **'并桌'**
  String get mergeTables;

  /// 撤桌
  ///
  /// In zh, this message translates to:
  /// **'撤桌'**
  String get clearTable;

  /// 关桌
  ///
  /// In zh, this message translates to:
  /// **'关桌'**
  String get closeTable;

  /// 确认
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get confirm;

  /// 包含桌台
  ///
  /// In zh, this message translates to:
  /// **'包含桌台'**
  String get includingTables;

  /// 选择桌台
  ///
  /// In zh, this message translates to:
  /// **'选择桌台'**
  String get selectTable;

  /// 原因
  ///
  /// In zh, this message translates to:
  /// **'原因'**
  String get reason;

  /// 取消
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get cancel;

  /// 本桌人数
  ///
  /// In zh, this message translates to:
  /// **'本桌人数'**
  String get tablePeople;

  /// 大人
  ///
  /// In zh, this message translates to:
  /// **'大人'**
  String get adults;

  /// 小孩
  ///
  /// In zh, this message translates to:
  /// **'小孩'**
  String get children;

  /// 选择菜单
  ///
  /// In zh, this message translates to:
  /// **'选择菜单'**
  String get selectMenu;

  /// 开始点餐
  ///
  /// In zh, this message translates to:
  /// **'开始点餐'**
  String get startOrdering;

  /// 当前桌台不可用
  ///
  /// In zh, this message translates to:
  /// **'当前桌台不可用'**
  String get currentTableUnavailable;

  /// 仅可选择一张以下非空闲状态桌台
  ///
  /// In zh, this message translates to:
  /// **'仅可选择一张以下非空闲状态桌台'**
  String get onlyOneNonFreeTableCanBeSelected;

  /// 请选择就餐人数
  ///
  /// In zh, this message translates to:
  /// **'请选择就餐人数'**
  String get pleaseSelectNumberOfDiners;

  /// 本桌标准大人人数
  ///
  /// In zh, this message translates to:
  /// **'本桌标准大人人数:'**
  String get standardAdultsForThisTable;

  /// 本桌标准小孩人数
  ///
  /// In zh, this message translates to:
  /// **'本桌标准小孩人数:'**
  String get standardChildrenForThisTable;

  /// 请选择菜单
  ///
  /// In zh, this message translates to:
  /// **'请选择菜单'**
  String get pleaseSelectMenu;

  /// 合并成功
  ///
  /// In zh, this message translates to:
  /// **'合并成功'**
  String get mergeSuccessful;

  /// 合并失败，请重试
  ///
  /// In zh, this message translates to:
  /// **'合并失败，请重试'**
  String get mergeFailedPleaseRetry;

  /// 撤桌必须留下一张桌台
  ///
  /// In zh, this message translates to:
  /// **'撤桌必须留下一张桌台'**
  String get oneTableMustRemainWhenRemoving;

  /// 撤桌成功
  ///
  /// In zh, this message translates to:
  /// **'撤桌成功'**
  String get tableRemovalSuccessful;

  /// 撤桌失败，请重试
  ///
  /// In zh, this message translates to:
  /// **'撤桌失败，请重试'**
  String get tableRemovalFailedPleaseRetry;

  /// 关桌成功
  ///
  /// In zh, this message translates to:
  /// **'关桌成功'**
  String get tableClosingSuccessful;

  /// 关桌失败，请重试
  ///
  /// In zh, this message translates to:
  /// **'关桌失败，请重试'**
  String get tableClosingFailedPleaseRetry;

  /// 开桌成功
  ///
  /// In zh, this message translates to:
  /// **'开桌成功'**
  String get tableOpeningSuccessful;

  /// 开桌失败，请重试
  ///
  /// In zh, this message translates to:
  /// **'开桌失败，请重试'**
  String get tableOpeningFailedPleaseRetry;

  /// 请输入预留手机号码后 4 位
  ///
  /// In zh, this message translates to:
  /// **'请输入预留手机号码后 4 位？'**
  String get pleaseEnterLast4DigitsOfReservedPhone;

  /// 号码不正确，请重新输入
  ///
  /// In zh, this message translates to:
  /// **'号码不正确，请重新输入'**
  String get numberIncorrectPleaseReenter;

  /// 号码正确，祝你用餐愉快
  ///
  /// In zh, this message translates to:
  /// **'号码正确，祝你用餐愉快'**
  String get numberCorrectEnjoyYourMeal;

  /// 菜单
  ///
  /// In zh, this message translates to:
  /// **'菜单'**
  String get menu;

  /// 已点
  ///
  /// In zh, this message translates to:
  /// **'已点'**
  String get ordered;

  /// 输入菜品编码或名称
  ///
  /// In zh, this message translates to:
  /// **'输入菜品编码或名称'**
  String get enterDishCodeOrName;

  /// 选规格
  ///
  /// In zh, this message translates to:
  /// **'选规格'**
  String get selectSpecification;

  /// 下单
  ///
  /// In zh, this message translates to:
  /// **'下单'**
  String get placeOrder;

  /// 清空
  ///
  /// In zh, this message translates to:
  /// **'清空'**
  String get clear;

  /// 敏感物
  ///
  /// In zh, this message translates to:
  /// **'敏感物'**
  String get allergens;

  /// 去除含有指定敏感物的菜品
  ///
  /// In zh, this message translates to:
  /// **'去除含有指定敏感物的菜品'**
  String get excludeDishesWithAllergens;

  /// 已选
  ///
  /// In zh, this message translates to:
  /// **'已选：'**
  String get selected;

  /// 购物车
  ///
  /// In zh, this message translates to:
  /// **'购物车'**
  String get cart;

  /// 更换桌台
  ///
  /// In zh, this message translates to:
  /// **'更换桌台'**
  String get changeTable;

  /// 更换菜单
  ///
  /// In zh, this message translates to:
  /// **'更换菜单'**
  String get changeMenu;

  /// 增加人数
  ///
  /// In zh, this message translates to:
  /// **'增加人数'**
  String get increaseNumberOfPeople;

  /// 未找到相关菜品
  ///
  /// In zh, this message translates to:
  /// **'未找到相关菜品'**
  String get noRelevantDishesFound;

  /// 已售罄，请选择其他菜品
  ///
  /// In zh, this message translates to:
  /// **'已售罄，请选择其他菜品'**
  String get dishSoldOutPleaseChooseAnother;

  /// 下一轮次时间未到
  ///
  /// In zh, this message translates to:
  /// **'下一轮次时间未到'**
  String get nextRoundTimeNotReached;

  /// 购物车有新的变动
  ///
  /// In zh, this message translates to:
  /// **'购物车有新的变动'**
  String get cartHasNewChanges;

  /// 下单成功
  ///
  /// In zh, this message translates to:
  /// **'下单成功'**
  String get orderPlacedSuccessfully;

  /// 下单失败，请联系服务员
  ///
  /// In zh, this message translates to:
  /// **'下单失败，请联系服务员'**
  String get orderPlacementFailedContactWaiter;

  /// 是否清空购物车
  ///
  /// In zh, this message translates to:
  /// **'是否清空购物车？'**
  String get clearShoppingCart;

  /// 数量超出限制，是否以原价下单
  ///
  /// In zh, this message translates to:
  /// **'数量超出限制，是否以原价下单？'**
  String get quantityExceedsLimitPlaceAtOriginalPrice;

  /// 外卖
  ///
  /// In zh, this message translates to:
  /// **'外卖'**
  String get takeaway;

  /// 未结帐
  ///
  /// In zh, this message translates to:
  /// **'未结帐'**
  String get unsettled;

  /// 已结帐
  ///
  /// In zh, this message translates to:
  /// **'已结帐'**
  String get settled;

  /// 请输入取餐码
  ///
  /// In zh, this message translates to:
  /// **'请输入取餐码'**
  String get pleaseEnterPickupCode;

  /// 订单信息
  ///
  /// In zh, this message translates to:
  /// **'订单信息'**
  String get orderInformation;

  /// 取餐码
  ///
  /// In zh, this message translates to:
  /// **'取餐码'**
  String get pickupCode;

  /// 取餐时间
  ///
  /// In zh, this message translates to:
  /// **'取餐时间'**
  String get pickupTime;

  /// 备注
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get remarks;

  /// 订单来源
  ///
  /// In zh, this message translates to:
  /// **'订单来源'**
  String get orderSource;

  /// 下单时间
  ///
  /// In zh, this message translates to:
  /// **'下单时间'**
  String get orderPlacementTime;

  /// 结账时间
  ///
  /// In zh, this message translates to:
  /// **'结账时间'**
  String get checkoutTime;

  /// 商品信息
  ///
  /// In zh, this message translates to:
  /// **'商品信息'**
  String get productInformation;

  /// 其他信息
  ///
  /// In zh, this message translates to:
  /// **'其他信息'**
  String get additionalInformation;

  /// 其他时间
  ///
  /// In zh, this message translates to:
  /// **'其他时间'**
  String get otherTime;

  /// 请选择取餐时间
  ///
  /// In zh, this message translates to:
  /// **'请选择取餐时间'**
  String get pleaseSelectPickupTime;

  /// 取餐时间至少30分钟后
  ///
  /// In zh, this message translates to:
  /// **'取餐时间至少30分钟后'**
  String get pickupTimeMustBeAtLeast30MinutesLater;

  /// 我的
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get profile;

  /// 账号
  ///
  /// In zh, this message translates to:
  /// **'账号'**
  String get account;

  /// 到期日期
  ///
  /// In zh, this message translates to:
  /// **'到期日期'**
  String get expirationDate;

  /// 剩余天数
  ///
  /// In zh, this message translates to:
  /// **'剩余天数'**
  String get remainingDays;

  /// 修改密码
  ///
  /// In zh, this message translates to:
  /// **'修改密码'**
  String get changePassword;

  /// 语言
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get language;

  /// 系统版本
  ///
  /// In zh, this message translates to:
  /// **'系统版本'**
  String get systemVersion;

  /// 更新
  ///
  /// In zh, this message translates to:
  /// **'更新'**
  String get update;

  /// 退出登录
  ///
  /// In zh, this message translates to:
  /// **'退出登录'**
  String get logout;

  /// 新密码
  ///
  /// In zh, this message translates to:
  /// **'新密码'**
  String get newPassword;

  /// 任意8位以上字符
  ///
  /// In zh, this message translates to:
  /// **'任意8位以上字符'**
  String get anyCharactersOf8OrMore;

  /// 请输入新密码
  ///
  /// In zh, this message translates to:
  /// **'请输入新密码'**
  String get pleaseEnterNewPassword;

  /// 确认密码
  ///
  /// In zh, this message translates to:
  /// **'确认密码'**
  String get confirmPassword;

  /// 请再次输入新密码
  ///
  /// In zh, this message translates to:
  /// **'请再次输入新密码'**
  String get pleaseReenterNewPassword;

  /// 提交
  ///
  /// In zh, this message translates to:
  /// **'提交'**
  String get submit;

  /// 密码修改成功
  ///
  /// In zh, this message translates to:
  /// **'密码修改成功'**
  String get passwordUpdatedSuccessfully;

  /// 密码修改失败，请重试
  ///
  /// In zh, this message translates to:
  /// **'密码修改失败，请重试'**
  String get passwordChangeFailedPleaseRetry;

  /// 切换语言成功
  ///
  /// In zh, this message translates to:
  /// **'切换语言成功'**
  String get languageSwitchedSuccessfully;

  /// 切换语言失败，请重试
  ///
  /// In zh, this message translates to:
  /// **'切换语言失败，请重试'**
  String get languageSwitchFailedPleaseRetry;

  /// 网络错误，请重试
  ///
  /// In zh, this message translates to:
  /// **'网络错误，请重试'**
  String get networkErrorPleaseTryAgain;

  /// 操作频繁 请稍后再试
  ///
  /// In zh, this message translates to:
  /// **'操作频繁 请稍后再试'**
  String get operationTooFrequentPleaseTryAgainLater;

  /// 暂无数据
  ///
  /// In zh, this message translates to:
  /// **'暂无数据'**
  String get noData;

  /// 重新加载
  ///
  /// In zh, this message translates to:
  /// **'重新加载'**
  String get loadAgain;

  /// 全部
  ///
  /// In zh, this message translates to:
  /// **'全部'**
  String get allData;

  /// 加载中...
  ///
  /// In zh, this message translates to:
  /// **'加载中...'**
  String get loadingData;

  /// 成功
  ///
  /// In zh, this message translates to:
  /// **'成功'**
  String get success;

  /// 失败
  ///
  /// In zh, this message translates to:
  /// **'失败'**
  String get failed;

  /// 选择人数
  ///
  /// In zh, this message translates to:
  /// **'选择人数'**
  String get selectPeople;

  /// 获取菜单失败
  ///
  /// In zh, this message translates to:
  /// **'获取菜单失败'**
  String get loadMenuFailed;

  /// 两次输入的密码不一致
  ///
  /// In zh, this message translates to:
  /// **'两次输入的密码不一致'**
  String get twoPasswordsDoNotMatch;

  /// 密码最少8位字符
  ///
  /// In zh, this message translates to:
  /// **'密码最少8位字符'**
  String get passwordLengthCannotBeLessThan8;

  /// /份
  ///
  /// In zh, this message translates to:
  /// **'/份'**
  String get perPortion;

  /// 更换
  ///
  /// In zh, this message translates to:
  /// **'更换'**
  String get replace;

  /// 更换人数
  ///
  /// In zh, this message translates to:
  /// **'更换人数'**
  String get changePerson;

  /// 获取桌台失败
  ///
  /// In zh, this message translates to:
  /// **'获取桌台失败'**
  String get getTableFailed;

  /// 请选择桌台
  ///
  /// In zh, this message translates to:
  /// **'请选择桌台'**
  String get pleaseSelectTable;

  /// 请退出点餐页面重新进入!
  ///
  /// In zh, this message translates to:
  /// **'请退出点餐页面重新进入!'**
  String get pleaseExitAndInAdain;

  /// 暂无可用桌台
  ///
  /// In zh, this message translates to:
  /// **'暂无可用桌台'**
  String get noCanUseTable;

  /// 暂无可用菜单
  ///
  /// In zh, this message translates to:
  /// **'暂无可用菜单'**
  String get noCanUseMenu;

  /// 请至少选择1人
  ///
  /// In zh, this message translates to:
  /// **'请至少选择1人'**
  String get pleaseSelectAtLeastOnePerson;

  /// 合并中...
  ///
  /// In zh, this message translates to:
  /// **'合并中...'**
  String get merging;

  /// 未知
  ///
  /// In zh, this message translates to:
  /// **'未知'**
  String get unknown;

  /// 购物车是空的
  ///
  /// In zh, this message translates to:
  /// **'购物车是空的'**
  String get cartIsEmpty;

  /// 是否删除菜品？
  ///
  /// In zh, this message translates to:
  /// **'是否删除菜品？'**
  String get areYouSureToDeleteTheDish;

  /// 删除
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get delete;

  /// 数量
  ///
  /// In zh, this message translates to:
  /// **'数量'**
  String get quantity;

  /// 请选择
  ///
  /// In zh, this message translates to:
  /// **'请选择'**
  String get pleaseSelect;

  /// 请选择
  ///
  /// In zh, this message translates to:
  /// **'请选择'**
  String get filterDishesWithAllergens;

  /// 暂无订单
  ///
  /// In zh, this message translates to:
  /// **'暂无订单'**
  String get noOrder;

  /// 去点餐
  ///
  /// In zh, this message translates to:
  /// **'去点餐'**
  String get goToOrder;

  /// 未结账
  ///
  /// In zh, this message translates to:
  /// **'未结账'**
  String get unpaid;

  /// 已结账
  ///
  /// In zh, this message translates to:
  /// **'已结账'**
  String get paid;

  /// 订单编号
  ///
  /// In zh, this message translates to:
  /// **'订单编号'**
  String get orderNo;

  /// 单据来源
  ///
  /// In zh, this message translates to:
  /// **'单据来源'**
  String get orderSourceNew;

  /// 操作确认
  ///
  /// In zh, this message translates to:
  /// **'商品详情'**
  String get productDetails;

  /// No description provided for @operationConfirmed.
  ///
  /// In zh, this message translates to:
  /// **'操作确认'**
  String get operationConfirmed;

  /// 是否退出当前登录？
  ///
  /// In zh, this message translates to:
  /// **'是否退出当前登录？'**
  String get areYouSureToLogout;

  /// 确认退出
  ///
  /// In zh, this message translates to:
  /// **'确认退出'**
  String get sureLogout;

  /// 欢迎使用
  ///
  /// In zh, this message translates to:
  /// **'欢迎使用'**
  String get welcome;

  /// 服务端
  ///
  /// In zh, this message translates to:
  /// **'服务端'**
  String get serviceApp;

  /// 密码
  ///
  /// In zh, this message translates to:
  /// **'密码'**
  String get password;

  /// 备注
  ///
  /// In zh, this message translates to:
  /// **'备注'**
  String get remark;

  /// 添加备注
  ///
  /// In zh, this message translates to:
  /// **'添加备注'**
  String get addRemark;

  /// 修改备注
  ///
  /// In zh, this message translates to:
  /// **'修改备注'**
  String get editRemark;

  /// 确认下单？
  ///
  /// In zh, this message translates to:
  /// **'确认下单？'**
  String get confirmOrder;

  /// 请输入
  ///
  /// In zh, this message translates to:
  /// **'请输入'**
  String get pleaseEnter;

  /// 登录中...
  ///
  /// In zh, this message translates to:
  /// **'登录中...'**
  String get logining;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
