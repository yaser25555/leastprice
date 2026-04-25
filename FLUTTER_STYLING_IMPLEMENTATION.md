# تطبيق الهوية الحالية داخل Flutter

## الوضع الحالي
التطبيق لا يعتمد على ملفات `constants/` منفصلة حتى الآن، بل يملك لوحة الألوان داخل [main.dart](/D:/leastprice/lib/main.dart) عبر:
- `AppPalette`
- `AppBrandMark`

وهذا هو المرجع الصحيح الحالي للتطوير، وليس النسخة القديمة المعتمدة على الأخضر.

---

## ما يجب استخدامه في التطوير الجديد

### لوحة الألوان
اعتمد القيم من `AppPalette`:
- `AppPalette.navy`
- `AppPalette.deepNavy`
- `AppPalette.softNavy`
- `AppPalette.orange`
- `AppPalette.paleOrange`
- `AppPalette.softOrange`
- `AppPalette.shellBackground`
- `AppPalette.cardBackground`
- `AppPalette.cardBorder`
- `AppPalette.panelText`

### الشعار
اعتمد:
- `AppBrandMark`

ولا تستبدله بـ `Icons.storefront_rounded` أو أي أيقونة عامة إلا إذا كان ذلك مقصوداً في سياق فرعي جداً.

---

## أمثلة معتمدة

### زر أساسي
```dart
ElevatedButton(
  onPressed: () {},
  style: ElevatedButton.styleFrom(
    backgroundColor: AppPalette.orange,
    foregroundColor: Colors.white,
  ),
  child: const Text('حفظ'),
)
```

### زر ثانوي
```dart
OutlinedButton(
  onPressed: () {},
  style: OutlinedButton.styleFrom(
    foregroundColor: AppPalette.orange,
    side: const BorderSide(color: AppPalette.paleOrange),
  ),
  child: const Text('إلغاء'),
)
```

### بطاقة
```dart
Container(
  decoration: BoxDecoration(
    color: AppPalette.cardBackground,
    border: Border.all(color: AppPalette.cardBorder),
    borderRadius: BorderRadius.circular(18),
  ),
)
```

### عنوان رئيسي
```dart
const Text(
  'أرخص سعر',
  style: TextStyle(
    color: AppPalette.navy,
    fontWeight: FontWeight.w900,
    fontSize: 24,
  ),
)
```

---

## قواعد التطوير القادمة

عند إضافة شاشة جديدة:
1. ابدأ من `AppPalette`
2. استخدم `AppBrandMark` إذا كانت الشاشة واجهة رئيسية أو دخول أو لوحة
3. لا تضف أخضر كهوية أساسية
4. لا تخلق Palette جديدة داخل كل Widget

---

## اقتراح تنظيمي لاحق

إذا كبر المشروع أكثر، فالخطوة الطبيعية التالية هي استخراج:
- `lib/theme/app_palette.dart`
- `lib/widgets/app_brand_mark.dart`
- `lib/theme/app_theme.dart`

لكن حالياً المرجع التشغيلي الصحيح ما زال في [main.dart](/D:/leastprice/lib/main.dart).
