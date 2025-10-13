package com.example.order_app

import io.flutter.embedding.android.FlutterActivity
import android.os.Bundle

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // 确保可以使用系统输入法
        // 不设置 FLAG_SECURE，允许使用普通键盘
    }
}
