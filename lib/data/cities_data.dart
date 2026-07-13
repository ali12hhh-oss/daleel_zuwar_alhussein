import '../models/models.dart';

/// إحداثيات كربلاء المقدسة (منطقة الحرمين الشريفين تقريباً)
const double karbalaLat = 32.6160;
const double karbalaLng = 44.0249;

/// مسافات تقريبية (بالطريق البري) بين أبرز المدن العراقية وكربلاء.
/// هذه أرقام تقريبية للاسترشاد العام فقط وليست مسارات مشي دقيقة؛
/// يُنصح بربط هذا القسم بخدمة خرائط حقيقية (Google Directions API) للحصول
/// على أدق مسار سير فعلي وتحديثه بحسب حالة الطرق والمواكب الحسينية.
const List<IraqiCity> iraqiCities = [
  IraqiCity(name: 'كربلاء', lat: 32.6160, lng: 44.0249, approxDistanceKm: 0),
  IraqiCity(name: 'النجف', lat: 31.9958, lng: 44.3107, approxDistanceKm: 80),
  IraqiCity(name: 'الحلة (بابل)', lat: 32.4637, lng: 44.4194, approxDistanceKm: 50),
  IraqiCity(name: 'بغداد', lat: 33.3152, lng: 44.3661, approxDistanceKm: 105),
  IraqiCity(name: 'الديوانية', lat: 31.9890, lng: 44.9268, approxDistanceKm: 130),
  IraqiCity(name: 'الرمادي (الأنبار)', lat: 33.4258, lng: 43.3057, approxDistanceKm: 150),
  IraqiCity(name: 'بعقوبة (ديالى)', lat: 33.7500, lng: 44.6383, approxDistanceKm: 140),
  IraqiCity(name: 'السماوة', lat: 31.3234, lng: 45.2830, approxDistanceKm: 250),
  IraqiCity(name: 'الكوت', lat: 32.5122, lng: 45.8189, approxDistanceKm: 230),
  IraqiCity(name: 'الناصرية', lat: 31.0559, lng: 46.2572, approxDistanceKm: 365),
  IraqiCity(name: 'العمارة (ميسان)', lat: 31.8350, lng: 47.1460, approxDistanceKm: 300),
  IraqiCity(name: 'البصرة', lat: 30.5085, lng: 47.7804, approxDistanceKm: 570),
  IraqiCity(name: 'كركوك', lat: 35.4681, lng: 44.3922, approxDistanceKm: 400),
  IraqiCity(name: 'الموصل', lat: 36.3489, lng: 43.1189, approxDistanceKm: 487),
  IraqiCity(name: 'أربيل', lat: 36.1911, lng: 44.0093, approxDistanceKm: 500),
  IraqiCity(name: 'دهوك', lat: 36.8617, lng: 42.9952, approxDistanceKm: 566),
];
