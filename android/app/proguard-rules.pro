# ✅ قواعد ضرورية لمكتبة flutter_local_notifications حتى تعمل zonedSchedule
# بوضع release بدون خطأ "Missing type parameter". بدون هذي القواعد، R8
# يشفّر الكلاسات الداخلية اللي تستخدمها المكتبة (عبر Gson) لحفظ/قراءة
# الإشعارات المجدولة، فتفشل عملية الحفظ والقراءة وقت التشغيل الفعلي.

-keep class com.dexterous.** { *; }
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.gson.**
-dontwarn com.dexterous.**

# قواعد Gson العامة (مطلوبة لأن flutter_local_notifications يستخدمها
# داخلياً لتحويل بيانات الإشعار المجدول من/إلى JSON)
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
