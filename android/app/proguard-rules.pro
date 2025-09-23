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

# Google Play Core相关规则
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Flutter Play Store Split相关规则
-keep class io.flutter.embedding.android.FlutterPlayStoreSplitApplication { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager { *; }
-keep class io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager$FeatureInstallStateUpdatedListener { *; }

# 保持所有Google Play Core相关的接口和类
-keep interface com.google.android.play.core.splitinstall.SplitInstallStateUpdatedListener { *; }
-keep interface com.google.android.play.core.tasks.OnFailureListener { *; }
-keep interface com.google.android.play.core.tasks.OnSuccessListener { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallRequest { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallRequest$Builder { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallSessionState { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallException { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallManager { *; }
-keep class com.google.android.play.core.splitinstall.SplitInstallManagerFactory { *; }
-keep class com.google.android.play.core.tasks.Task { *; }

# 保持所有注解相关类
-keep class javax.lang.model.element.Modifier { *; }
-keep class com.google.errorprone.annotations.** { *; }

# 保持所有javax相关类
-keep class javax.** { *; }
-keep class javax.lang.model.** { *; }
-keep class javax.lang.model.element.** { *; }
