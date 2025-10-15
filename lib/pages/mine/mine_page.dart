import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/mine/mine_controller.dart';
import 'package:order_app/pages/mine/sub_page/change_lan_page.dart';
import 'package:order_app/pages/mine/sub_page/change_psw_page.dart';
import 'package:order_app/utils/l10n_utils.dart';
 
 class MinePage extends StatelessWidget {
  final MineController c = Get.put(MineController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 背景图片
          Positioned.fill(
            child: Image.asset('assets/order_mine_bg.webp', fit: BoxFit.fill),
          ),
          SafeArea(
            child: Container(
              padding: EdgeInsets.only(left: 16, right: 16, bottom: 68),
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  // 头像+昵称+登录ID
                  Container(
                    padding: EdgeInsets.only(left: 25, top: 30, bottom: 28),

                    child: Row(
                      children: [
                        // 头像
                        ClipOval(
                          child: Image.asset(
                            'assets/order_mine_placeholder.webp',
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                          ),
                        ),
                        SizedBox(width: 16),
                        // 昵称和登录ID
                        Obx(
                          () => Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.nickname.value,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                "${context.l10n.account}: ${c.account.value.isNotEmpty ? c.account.value : c.loginId.value}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // 公司信息+到账日期+剩余时间
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: AssetImage('assets/order_company_bg.webp'),
                            fit: BoxFit.cover,
                          ),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10),
                            topRight: Radius.circular(10),
                          ),
                        ),
                        padding: EdgeInsets.only(left: 14),
                        width: double.infinity,
                        height: 48,
                        alignment: Alignment.centerLeft,
                        child: Obx(
                          () => Text(
                            c.storeName.value.isNotEmpty ? c.storeName.value : context.l10n.appTitle,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // SizedBox(height: 12),
                      Obx(
                        () => Container(
                          decoration: BoxDecoration(
                            color: Color(0xffffffff),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(10),
                              bottomRight: Radius.circular(10),
                            ),
                          ),
                          padding: EdgeInsets.only(left: 14, right: 14),
                          width: double.infinity,
                          height: 48,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 160,
                                height: 30,
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Color(0xffF6F7FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.l10n.expirationDate,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      c.authExpireDate.value.isNotEmpty 
                                        ? c.authExpireDate.value
                                        : '${c.accountDate.value.year}-${c.accountDate.value.month.toString().padLeft(2, '0')}-${c.accountDate.value.day.toString().padLeft(2, '0')}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.black,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                width: 134,
                                height: 30,
                                padding: EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: Color(0xffF6F7FF),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      context.l10n.remainingDays,
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                    Text(
                                      c.surplusDays.value > 0
                                        ? '${c.surplusDays.value.toString().padLeft(2, '0')}天'
                                        : '${c.remainDay.value.toString().padLeft(2, '0')}天',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xffFF9027),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  // 设置项
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _SettingItem(
                          icon: 'assets/order_mine_psw.webp',
                          title: context.l10n.changePassword,
                          trailing: Image.asset(
                            'assets/order_mine_arrowR.webp',
                            width: 16,
                            height: 16,
                          ),
                          onTap: () {
                            // 跳转修改密码
                            Get.to(ChangePasswordPage());
                          },
                        ),
                        _SettingItem(
                          icon: 'assets/order_mine_lan.webp',
                          title: context.l10n.language,
                          trailing: Image.asset(
                            'assets/order_mine_arrowR.webp',
                            width: 16,
                            height: 16,
                            
                          ),
                          onTap: () {
                            // 跳转切换语言
                            Get.to(ChangeLanPage());
                          },
                        ),
                        Obx(
                          () => _SettingItem(
                            icon: 'assets/order_mine_sys.webp',
                            title: context.l10n.systemVersion,
                            trailing: Text(
                              c.version.value,
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xff666666),fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // 退出登录按钮
                  Center(
                    child: GestureDetector(
                      onTap: c.onTapLoginOut,
                      child: Container(
                        width: 253,
                        height: 40,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Color(0xff666666), // 边框颜色
                            width: 1, // 边框宽度
                            style: BorderStyle.solid, // 边框样式（实线）
                          ),
                          borderRadius: BorderRadius.circular(20), // 可选：圆角
                        ),
                        alignment: Alignment.center,
                        child: Text(
                            context.l10n.logout,
                          style: TextStyle(
                            fontSize: 20,
                            color: Color(0xff666666),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  final String icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Image.asset(icon, width: 16, height: 16),
      title: Text(title, style: TextStyle(fontSize: 14)),
      trailing: trailing,
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 10),
    );
  }
}
