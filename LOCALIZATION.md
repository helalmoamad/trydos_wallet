# Localization System Documentation

## نظام الترجمات الشامل

تم إضافة نظام ترجمات متطور يدعم **4 لغات:**
- 🇬🇧 **English** (en) - LTR
- 🇸🇦 **العربية** (ar) - RTL
- 🇰🇷 **کوردی** (ku) - RTL
- 🇹🇷 **Türkçe** (tr) - LTR

---

## المميزات الرئيسية

### 1️⃣ **نظام الترجمات الديناميكي**
   - جميع النصوص مخزنة في `lib/src/localization/app_strings.dart`
   - دعم كامل لـ 4 لغات
   - سهل الإضافة والتعديل

### 2️⃣ **إدارة الاتجاه (RTL/LTR)**
   - تلقائي بناءً على اللغة المختارة
   - العربية والكردية RTL
   - الإنجليزية والتركية LTR

### 3️⃣ **مسافات وأبعاد ديناميكية**
   - `ResponsivePadding` helper class
   - يقلب البادينج تلقائياً عند تغيير الاتجاه
   - سهل الاستخدام والتطبيق

### 4️⃣ **BLoC لإدارة اللغة**
   - `LocalizationBloc` - إدارة حالة اللغة
   - تغيير اللغة فوري بدون إعادة تحميل
   - حفظ الحالة على المستوى العام

---

## طريقة الاستخدام

### تغيير النص في التطبيق:
```dart
import 'package:trydos_wallet/src/localization/app_strings.dart';

// في أي مكان في الكود:
Text(AppStrings.get(languageCode, 'my_wallet'))
```

### إضافة نص جديد:
1. أضفه في `app_strings.dart` تحت كل منرجمة لغة:
```dart
'translation_key': {
  'en': 'English text',
  'ar': 'النص العربي',
  'ku': 'متن کوردی',
  'tr': 'Türkçe metin',
}
```

2. استخدمه في الكود:
```dart
AppStrings.get(locState.languageCode, 'translation_key')
```

### استخدام المسافات الديناميكية:
```dart
import 'package:trydos_wallet/src/localization/responsive_padding.dart';

// بدلاً من:
Padding(padding: const EdgeInsets.only(left: 24))

// استخدم:
Padding(
  padding: ResponsivePadding.only(
    start: 24,  // سيصبح left في LTR و right في RTL
    isRtl: locState.isRtl,
  ),
)
```

---

## التعديلات الرئيسية

### 1. `welcome_screen.dart`
- ❌ إزالة `Directionality` الثابتة

### 2. `home_page.dart`
- ✅ إضافة `BlocBuilder` للترجمات
- ✅ تطبيق `Directionality` الديناميكي
- ✅ تحديث رسائل الخطأ بالترجمات

### 3. `settings_tab.dart`
- ✅ إضافة واجهة اختيار اللغات
- ✅ تطبيق المسافات الديناميكية
- ✅ عرض اللغات الـ 4 مع اختيار بصري

### 4. `wallet_tab.dart`
- ✅ تطبيق `BlocBuilder` للترجمات
- ✅ استخدام `ResponsivePadding`
- ✅ ترجمة جميع النصوص والتسميات

### 5. `example/lib/main.dart`
- ✅ إضافة `LocalizationBloc` كـ Provider
- ✅ بناء `MaterialApp` مع `BlocBuilder`

---

## في SettingsTab

يوجد الآن تبويب إعدادات كامل يحتوي على:
- ✅ **اختيار اللغة** - 4 خيارات واضحة
- ✅ **معلومات التطبيق** - رقم الإصدار والتفاصيل
- ✅ **تصميم ليل/نهار** - بطاقات مع تصميم عصري

### مثال على اختيار اللغة:
```dart
// عند الضغط على لغة:
context.read<LocalizationBloc>().add(
  LocalizationLanguageChanged('ar'),
);
```

---

## ملاحظات مهمة

⚠️ **كل مكان استخدم `Directionality` بقيمة ثابتة (مثل TextDirection.ltr) يجب حذفه**

✅ الآن استخدم `BlocBuilder<LocalizationBloc>` بدلاً منه

📝 إذا أضفت صفحة أو widget جديد:
1. أضف النصوص في `app_strings.dart`
2. استخدم `BlocBuilder<LocalizationBloc>` لالتقاط `locState`
3. طبق `AppStrings.get(locState.languageCode, 'key')`
4. استخدم `ResponsivePadding` للمسافات

---

## الملفات الجديدة المضافة

```
lib/src/
├── bloc/
│   └── localization/
│       └── localization_bloc.dart
├── localization/
│   ├── app_strings.dart
│   ├── responsive_padding.dart
│   └── localization.dart
```

---

## الدعم المتجاهز

- ✅ اللغات الـ 4 (English, Arabic, Kurdish, Turkish)
- ✅ الاتجاه الديناميكي (RTL/LTR)
- ✅ المسافات الديناميكية
- ✅ إدارة الحالة العامة للغة
- ✅ واجهة تبديل اللغات في الإعدادات

---

## التالي (اختياري)

إذا أردت تحسينات إضافية:
1. **التخزين الدائم** - حفظ اختيار اللغة في SharedPreferences
2. **ملفات JSON** - بدلاً من `Map` في الكود
3. **التوطين الديناميكي** - استدعاء من API
4. **دعم لغات أكثر** - إضافة بسيطة جداً

---

**تم إنشاء النظام بواسطة: AI Assistant**  
**التاريخ: March 3, 2026**
