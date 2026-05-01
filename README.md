# LeastPrice - أرخص سعر

تطبيق Flutter للبحث عن أقل الأسعار ومقارنة المنتجات في السعودية.

## الميزات

- 🔍 بحث ذكي عن المنتجات
- 📊 مقارنة الأسعار بين المتاجر
- 🎯 عروض حصرية
- 🌐 دعم الويب والأندرويد
- 🔒 مصادقة آمنة مع Firebase
- 📱 واجهة مستخدم عربية

## التقنيات المستخدمة

- **Flutter** - إطار العمل الرئيسي
- **Firebase** - قاعدة البيانات والمصادقة
- **Riverpod** - إدارة الحالة
- **Firestore** - تخزين البيانات

## التثبيت

1. استنسخ المشروع:
```bash
git clone https://github.com/yourusername/leastprice.git
cd leastprice
```

2. تثبيت الـ dependencies:
```bash
flutter pub get
```

3. إعداد Firebase:
   - أنشئ مشروع Firebase
   - أضف ملفات التكوين
   - فعل Firestore و Authentication

4. تشغيل التطبيق:
```bash
flutter run
```

## البناء

### Android APK
```bash
flutter build apk --release
```

### Web
```bash
flutter build web --release
```

## النشر

يتم النشر تلقائياً عبر GitHub Actions:
- APK إلى GitHub Releases
- Web إلى Firebase Hosting و GitHub Pages

## المساهمة

نرحب بالمساهمات! يرجى قراءة دليل المساهمة قبل البدء.

## الترخيص

هذا المشروع مرخص تحت رخصة MIT.
