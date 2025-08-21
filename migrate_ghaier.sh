#!/bin/bash

# =========================
# إعداد متغيرات المشروع
# =========================

OLD_PROJECT_PATH="/Users/mac/NEW-USER-APP-TAXISTA-main"
NEW_PROJECT_PATH="/Users/mac/NEW-USER-APP-TAXISTA-main_clean"

# =========================
# إنشاء مشروع Flutter جديد نظيف
# =========================

echo "🚀 إنشاء مشروع Flutter جديد ..."
flutter create "$NEW_PROJECT_PATH"

# =========================
# حذف lib الافتراضي ونقل كودك
# =========================

echo "✅ نقل ملفات الكود..."
rm -rf "$NEW_PROJECT_PATH/lib"
cp -r "$OLD_PROJECT_PATH/lib" "$NEW_PROJECT_PATH/lib"

# =========================
# نقل الأصول assets
# =========================

echo "✅ نقل الأصول assets..."
if [ -d "$OLD_PROJECT_PATH/assets" ]; then
  cp -r "$OLD_PROJECT_PATH/assets" "$NEW_PROJECT_PATH/assets"
else
  echo "⚠️ لا يوجد مجلد assets."
fi

# =========================
# نقل الباكدجات المحلية packages إن وجدت
# =========================

if [ -d "$OLD_PROJECT_PATH/packages" ]; then
  echo "✅ نقل مجلد packages..."
  mkdir -p "$NEW_PROJECT_PATH/packages"
  cp -r "$OLD_PROJECT_PATH/packages/" "$NEW_PROJECT_PATH/packages/"
else
  echo "⚠️ لا يوجد مجلد packages."
fi

# =========================
# نسخ ملفات إعدادات المشروع
# =========================



echo "✅ نقل ملفات android المهمة..."
rm -rf "$NEW_PROJECT_PATH/android"
cp -r "$OLD_PROJECT_PATH/android" "$NEW_PROJECT_PATH/android"

echo "✅ نسخ google-services.json و key.properties لو موجودين..."
cp "$OLD_PROJECT_PATH/android/app/google-services.json" "$NEW_PROJECT_PATH/android/app/" 2>/dev/null || echo "⚠️ لا يوجد google-services.json"
cp "$OLD_PROJECT_PATH/android/key.properties" "$NEW_PROJECT_PATH/android/" 2>/dev/null || echo "⚠️ لا يوجد key.properties"

# =========================
# سحب الباكدجات وتنظيف المشروع
# =========================

cd "$NEW_PROJECT_PATH"
flutter pub get
flutter clean

echo "🎯 تمت عملية النقل بنجاح يا معلم ✅"
echo "🔥 الآن يمكنك تشغيل: cd $NEW_PROJECT_PATH && flutter run"
