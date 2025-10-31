import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:order_app/pages/login/server_config/server_config_controller.dart';
import 'package:order_app/utils/l10n_utils.dart';
import 'package:order_app/utils/screen_adaptation.dart';
import 'package:order_app/utils/keyboard_utils.dart';

class ServerConfigPage extends StatefulWidget {
  const ServerConfigPage({Key? key}) : super(key: key);

  @override
  _ServerConfigPageState createState() => _ServerConfigPageState();
}

class _ServerConfigPageState extends State<ServerConfigPage> {
  final ServerConfigController controller = Get.put(ServerConfigController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        title: Text(
          context.l10n.serverAddress,
          style: TextStyle(
            fontSize: context.adaptFontSize(18),
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: KeyboardUtils.buildDismissiblePage(
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.adaptSpacing(16),
                    vertical: context.adaptSpacing(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // IP地址标题
                      Padding(
                        padding: EdgeInsets.only(
                           bottom: context.adaptSpacing(12),
                        ),
                        child: Text(
                          context.l10n.ipAddress,
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: context.adaptFontSize(16),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      // IP地址输入框
                      SizedBox(
                        width: double.infinity,
                        height: context.adaptHeight(40),
                        child: TextField(
                          controller: controller.ipAddressController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.]'),
                            ),
                          ],
                          cursorHeight: 16,
                          cursorColor: Colors.black54,
                          showCursor: true,
                          enableInteractiveSelection: true,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: context.adaptSpacing(10),
                            ),
                            hintText: context.l10n.pleaseEnterIpAddress,
                            hintStyle: TextStyle(
                              color: Color(0xff999999),
                              fontSize: context.adaptFontSize(11),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            border: InputBorder.none,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: context.adaptSpacing(16)),
                      // 端口标题
                      Padding(
                        padding: EdgeInsets.only(
                           bottom: context.adaptSpacing(12),
                        ),
                        child: Text(
                          context.l10n.port,
                          style: TextStyle(
                            color: Color(0xFF333333),
                            fontSize: context.adaptFontSize(16),
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      // 端口输入框
                      SizedBox(
                        width: double.infinity,
                        height: context.adaptHeight(40),
                        child: TextField(
                          controller: controller.portController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(5),
                          ],
                          cursorHeight: 16,
                          cursorColor: Colors.black54,
                          showCursor: true,
                          enableInteractiveSelection: true,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.symmetric(
                              vertical: 0,
                              horizontal: context.adaptSpacing(10),
                            ),
                            hintText: context.l10n.pleaseEnterPort,
                            hintStyle: TextStyle(
                              color: Color(0xff999999),
                              fontSize: context.adaptFontSize(11),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF7F7F7),
                            border: InputBorder.none,
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(4),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // 底部提交按钮
              SafeArea(
                child: Padding(
                  padding: EdgeInsets.only(
                    left: context.adaptSpacing(60),
                    right: context.adaptSpacing(60),
                    bottom: context.adaptSpacing(180),
                    top: context.adaptSpacing(20),
                  ),
                  child: Obx(
                    () => GestureDetector(
                      onTap: controller.isSaving.value
                          ? null
                          : controller.saveServerConfig,
                      child: Container(
                        width: double.infinity,
                        height: context.adaptHeight(40),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFF9C90FB),
                              Color(0xFF7FA1F6),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        alignment: Alignment.center,
                        child: controller.isSaving.value
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: context.adaptWidth(16),
                                    height: context.adaptWidth(16),
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: context.adaptSpacing(8)),
                                  Text(
                                    context.l10n.loadingData,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: context.adaptFontSize(16),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                context.l10n.submit,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: context.adaptFontSize(20),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

