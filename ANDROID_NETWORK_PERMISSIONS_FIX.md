# Android Release版本网络权限修复

## 🚨 问题描述
Android release版本连不上网络，需要添加网络权限配置。

## 🔧 解决方案

### 1. 添加网络权限
**文件**: `android/app/src/main/AndroidManifest.xml`

#### 1.1 基础网络权限
```xml
<!-- 网络权限 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
```

#### 1.2 存储权限（用于缓存和日志）
```xml
<!-- 存储权限（用于缓存和日志） -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
```

#### 1.3 应用配置
```xml
<application
    android:label="order_app"
    android:name="${applicationName}"
    android:icon="@mipmap/ic_launcher"
    android:usesCleartextTraffic="true"
    android:networkSecurityConfig="@xml/network_security_config">
```

### 2. 网络安全配置
**文件**: `android/app/src/main/res/xml/network_security_config.xml`

#### 2.1 允许HTTP请求的域名配置
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <!-- 允许HTTP请求的域名 -->
        <domain includeSubdomains="true">localhost</domain>
        <domain includeSubdomains="true">10.0.2.2</domain>
        <domain includeSubdomains="true">127.0.0.1</domain>
        <!-- 您的API服务器IP地址 -->
        <domain includeSubdomains="true">129.204.154.113</domain>
    </domain-config>
    
    <!-- 允许所有HTTP请求（仅用于开发环境，生产环境建议使用HTTPS） -->
    <base-config cleartextTrafficPermitted="true">
        <trust-anchors>
            <certificates src="system"/>
        </trust-anchors>
    </base-config>
</network-security-config>
```

### 3. ProGuard规则配置
**文件**: `android/app/proguard-rules.pro`

#### 3.1 网络相关类保护规则
```proguard
# Flutter相关规则
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# 网络相关规则
-keep class okhttp3.** { *; }
-keep class retrofit2.** { *; }
-keep class com.google.gson.** { *; }
-keep class com.squareup.okhttp3.** { *; }

# Dio网络库规则
-keep class dio.** { *; }
-keep class com.dio.** { *; }

# 保持所有网络相关的注解
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes Exceptions

# 保持所有枚举
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# 保持所有序列化相关的类
-keep class * implements java.io.Serializable { *; }
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# 保持所有JSON相关的类
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# 保持所有反射相关的类
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# 保持所有网络请求相关的类
-keep class * extends java.lang.Exception
-keep class * extends java.lang.RuntimeException

# 保持所有数据模型类
-keep class com.example.order_app.** { *; }
-keep class * extends java.lang.Object {
    <fields>;
    <methods>;
}
```

### 4. 构建配置更新
**文件**: `android/app/build.gradle.kts`

#### 4.1 启用ProGuard规则
```kotlin
buildTypes {
    release {
        // TODO: Add your own signing config for the release build.
        // Signing with the debug keys for now, so `flutter run --release` works.
        signingConfig = signingConfigs.getByName("debug")
        isMinifyEnabled = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

## 🎯 权限说明

### 1. 网络权限
- **INTERNET**: 允许应用访问互联网
- **ACCESS_NETWORK_STATE**: 允许应用检查网络连接状态
- **ACCESS_WIFI_STATE**: 允许应用检查WiFi连接状态

### 2. 存储权限
- **WRITE_EXTERNAL_STORAGE**: 允许应用写入外部存储（用于缓存和日志）
- **READ_EXTERNAL_STORAGE**: 允许应用读取外部存储

### 3. 网络安全配置
- **usesCleartextTraffic="true"**: 允许应用使用HTTP请求（非HTTPS）
- **networkSecurityConfig**: 指定网络安全配置文件

## 🔍 问题排查

### 1. 检查网络权限
确保AndroidManifest.xml中包含所有必要的网络权限。

### 2. 检查网络安全配置
确保网络安全配置文件正确配置了API服务器地址。

### 3. 检查ProGuard规则
确保网络相关的类没有被混淆。

### 4. 检查API地址
确保API地址 `http://129.204.154.113:8050` 在网络安全配置中被允许。

## 🚀 测试步骤

### 1. 清理构建
```bash
flutter clean
flutter pub get
```

### 2. 构建Release版本
```bash
flutter build apk --release
```

### 3. 安装测试
```bash
flutter install --release
```

### 4. 网络连接测试
- 检查应用是否能正常连接API
- 检查网络请求是否成功
- 检查错误日志

## ⚠️ 注意事项

### 1. 安全性
- 当前配置允许HTTP请求，生产环境建议使用HTTPS
- 网络安全配置中包含了具体的IP地址，确保这是正确的

### 2. 性能
- ProGuard规则可能会影响构建时间
- 建议在开发阶段禁用ProGuard，仅在发布时启用

### 3. 兼容性
- 确保所有网络相关的依赖都正确配置
- 检查是否有其他插件需要特殊权限

## 📋 修改文件列表

1. `android/app/src/main/AndroidManifest.xml` - 添加网络权限
2. `android/app/src/main/res/xml/network_security_config.xml` - 网络安全配置
3. `android/app/proguard-rules.pro` - ProGuard规则
4. `android/app/build.gradle.kts` - 构建配置

## ✅ 预期结果

修复后，Android release版本应该能够：
- ✅ 正常连接网络
- ✅ 成功调用API接口
- ✅ 正常进行网络请求
- ✅ 正确处理网络错误

现在您的应用应该能够在release版本中正常连接网络了！🚀
