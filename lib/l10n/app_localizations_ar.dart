// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appName => 'درايف جو';

  @override
  String get tagline => 'سوق تأجير السيارات في مصر';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get continueAsGuest => 'متابعة كزائر';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get search => 'بحث';

  @override
  String get home => 'الرئيسية';

  @override
  String get favorites => 'المفضلة';

  @override
  String get myListings => 'إعلاناتي';

  @override
  String get profile => 'الملف الشخصي';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get logout => 'تسجيل الخروج';

  @override
  String get findYourRide => 'اعثر على رحلتك المثالية';

  @override
  String get homeTagline =>
      'سوق تأجير السيارات رقم ١ في مصر · أكثر من ٢٠٠ سيارة';

  @override
  String get searchHint => 'الماركة، الموديل، المدينة…';

  @override
  String get searchDreamCar => 'ابحث عن سيارة أحلامك…';

  @override
  String get topBrands => 'أفضل الماركات';

  @override
  String get exploreAllCars => 'استكشف كل السيارات';

  @override
  String get viewAll => 'عرض الكل';

  @override
  String get viewAllArrow => 'عرض الكل ←';

  @override
  String get recommendForYou => 'موصى به لك';

  @override
  String get savedCollection => 'المجموعة المحفوظة';

  @override
  String get bookNow => 'احجز الآن';

  @override
  String get perDay => '/يوم';

  @override
  String get filters => 'التصفية';

  @override
  String get applyFilters => 'تطبيق التصفية';

  @override
  String get clearAll => 'مسح الكل';

  @override
  String get availableOnly => 'المتاح فقط';

  @override
  String get priceRange => 'نطاق السعر';

  @override
  String get noResults => 'لم يتم العثور على سيارات';

  @override
  String get noSavedCars => 'لا توجد سيارات محفوظة بعد';

  @override
  String get browseCars => 'تصفح السيارات';

  @override
  String get signInToSave => 'سجّل الدخول لحفظ مفضلتك';

  @override
  String get color => 'اللون';

  @override
  String get model => 'الموديل';

  @override
  String get brand => 'الماركة';

  @override
  String get city => 'المدينة';

  @override
  String get carClass => 'الفئة';

  @override
  String get transmission => 'ناقل الحركة';

  @override
  String get fuel => 'الوقود';

  @override
  String get anyBrand => 'أي ماركة';

  @override
  String get anyCity => 'أي مدينة';

  @override
  String get anyClass => 'أي فئة';

  @override
  String get manual => 'يدوي';

  @override
  String get automatic => 'أوتوماتيك';

  @override
  String get petrol => 'بنزين';

  @override
  String get diesel => 'ديزل';

  @override
  String get hybrid => 'هجين';

  @override
  String get electric => 'كهربائي';

  @override
  String get available => 'متاح';

  @override
  String get all => 'الكل';

  @override
  String get carsTab => 'السيارات';

  @override
  String get saved => 'المحفوظة';

  @override
  String get models => 'الموديلات';

  @override
  String get cities => 'المدن';

  @override
  String get priceChip => 'السعر';

  @override
  String get addListing => 'إضافة';

  @override
  String get history => 'السجل';

  @override
  String get driveGo => 'درايف جو';

  @override
  String get egyptSuffix => '، مصر';

  @override
  String get colorWhite => 'أبيض';

  @override
  String get colorBlack => 'أسود';

  @override
  String get colorSilver => 'فضي';

  @override
  String get colorBlue => 'أزرق';

  @override
  String get colorRed => 'أحمر';

  @override
  String get colorGrey => 'رمادي';

  @override
  String get colorGold => 'ذهبي';

  @override
  String priceRangeLabel(int min, int max) {
    return 'جنيه $min–$max';
  }

  @override
  String priceRangeSheetLabel(int min, int max) {
    return 'جنيه $min — جنيه $max';
  }

  @override
  String carLocationLine(String city, String egypt) {
    return '٤٫٨ · $city$egypt';
  }
}
