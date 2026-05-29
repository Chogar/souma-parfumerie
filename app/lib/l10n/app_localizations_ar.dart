// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'سوما للعطور';

  @override
  String get appWindowTitle => 'Souma Perfumery Management System';

  @override
  String get storeName => 'سوما للعطور';

  @override
  String get projectFooter => 'Réalisé par Expérience Tech';

  @override
  String get projectFooterPrefix => 'من تنفيذ';

  @override
  String get experienceTechLink => 'Expérience Tech';

  @override
  String get login => 'تسجيل الدخول';

  @override
  String get username => 'اسم المستخدم';

  @override
  String get password => 'كلمة المرور';

  @override
  String get signIn => 'دخول';

  @override
  String get signOut => 'خروج';

  @override
  String get pos => 'الصندوق';

  @override
  String get catalog => 'منتج';

  @override
  String get stock => 'المخزون';

  @override
  String get reports => 'التقارير';

  @override
  String get settings => 'الإعدادات';

  @override
  String get users => 'المستخدمون';

  @override
  String get dashboard => 'لوحة التحكم';

  @override
  String get scanBarcode => 'مسح الرمز الشريطي';

  @override
  String get barcodeHint => 'الرمز الشريطي…';

  @override
  String get subtotal => 'المجموع الفرعي';

  @override
  String get discount => 'خصم';

  @override
  String get total => 'الإجمالي';

  @override
  String get cash => 'نقداً';

  @override
  String get card => 'بطاقة';

  @override
  String get mobile => 'محفظة';

  @override
  String get amountPaid => 'المبلغ المدفوع';

  @override
  String get change => 'الباقي';

  @override
  String get validateSale => 'تأكيد البيع';

  @override
  String get clearCart => 'إفراغ السلة';

  @override
  String get stockAlert => 'مخزون غير كافٍ';

  @override
  String get outOfStock => 'نفاد المخزون';

  @override
  String get lowStock => 'مخزون منخفض';

  @override
  String get sync => 'المزامنة';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get lastSync => 'آخر مزامنة';

  @override
  String get online => 'متصل';

  @override
  String get offline => 'غير متصل';

  @override
  String get language => 'اللغة';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get dailySales => 'مبيعات اليوم';

  @override
  String get myDailySales => 'مبيعاتي اليوم';

  @override
  String get mySalesOnly => 'عرض مبيعاتك فقط';

  @override
  String get transactions => 'المعاملات';

  @override
  String get averageBasket => 'متوسط السلة';

  @override
  String get topProducts => 'الأكثر مبيعاً';

  @override
  String topProductsShowMore(int count) {
    return 'المزيد من التفاصيل ($count)';
  }

  @override
  String get exportPdf => 'تصدير PDF';

  @override
  String get exportExcel => 'تصدير Excel';

  @override
  String get products => 'المنتجات';

  @override
  String get categories => 'الفئات';

  @override
  String get price => 'السعر';

  @override
  String get quantity => 'الكمية';

  @override
  String get save => 'حفظ';

  @override
  String get cancel => 'إلغاء';

  @override
  String get search => 'بحث';

  @override
  String get noData => 'لا توجد بيانات';

  @override
  String get errorGeneric => 'حدث خطأ';

  @override
  String get loginError => 'بيانات الدخول غير صحيحة';

  @override
  String get connectionError =>
      'تعذر الاتصال بقاعدة PostgreSQL. تحقق من تشغيل الخادم.';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get welcome => 'مرحباً';

  @override
  String get managerOnly => 'للمدير فقط';

  @override
  String get invoice => 'فاتورة';

  @override
  String get clientPhone => 'هاتف العميل';

  @override
  String get clientPhoneSearchHint => 'اكتب للبحث في القاعدة…';

  @override
  String get backup => 'نسخ احتياطي';

  @override
  String get runBackup => 'تشغيل النسخ الاحتياطي';

  @override
  String get backupDone => 'تم إنشاء النسخة الاحتياطية';

  @override
  String get backupFailed => 'فشل النسخ الاحتياطي';

  @override
  String get backupPgDumpMissing =>
      'pg_dump غير موجود. ثبّت PostgreSQL (مثلاً brew install postgresql@14).';

  @override
  String get salesHistory => 'سجل المبيعات';

  @override
  String get clients => 'العملاء';

  @override
  String get recentSales => 'مبيعات حديثة';

  @override
  String get dashboardManager => 'لوحة المدير';

  @override
  String get dashboardGestionnaire => 'لوحة الصندوق';

  @override
  String get storeSettings => 'معلومات المتجر';

  @override
  String get storeNameFieldLabel => 'اسم المتجر (إعدادات)';

  @override
  String get storeAddress => 'العنوان';

  @override
  String get storePhone => 'الهاتف';

  @override
  String get storeEmail => 'البريد الإلكتروني';

  @override
  String get rememberCredentials => 'حفظ اسم المستخدم وكلمة المرور';

  @override
  String get menuBoutique => 'منتج';

  @override
  String get menuCommerce => 'المبيعات والعملاء';

  @override
  String get menuAdministration => 'الإدارة';

  @override
  String get addProduct => 'إضافة منتج';

  @override
  String get inStockProducts => 'منتجات متوفرة';

  @override
  String get selectProductHint => 'انقر على منتج لإضافته إلى السلة';

  @override
  String get productNotFound => 'لا يوجد منتج لهذا الرمز الشريطي';

  @override
  String get productExpired => 'هذا المنتج منتهي الصلاحية ولا يمكن بيعه';

  @override
  String get posCatalogEmpty => 'امسح الرمز الشريطي أو ابحث عن منتج';

  @override
  String get brand => 'العلامة';

  @override
  String get nameFr => 'الاسم (فرنسي)';

  @override
  String get nameAr => 'الاسم (عربي)';

  @override
  String get purchasePrice => 'سعر الشراء';

  @override
  String get initialStock => 'المخزون الابتدائي';

  @override
  String get category => 'الفئة';

  @override
  String get barcode => 'الباركود / المرجع';

  @override
  String get monthlyRevenue => 'الإيرادات الشهرية';

  @override
  String get cart => 'السلة';

  @override
  String get emptyCart => 'السلة فارغة — اختر منتجاً من القائمة أعلاه';

  @override
  String get tapToAddProduct => 'انقر على منتج لإضافته إلى السلة';

  @override
  String get minStockAlert => 'حد تنبيه المخزون';

  @override
  String get minStockAlertHint =>
      'تنبيه مخزون منخفض عندما تصل الكمية إلى هذا المستوى أو أقل';

  @override
  String get paymentMethod => 'طريقة الدفع';

  @override
  String get alerts => 'التنبيهات';

  @override
  String get lowStockTab => 'مخزون منخفض';

  @override
  String get expiryTab => 'قرب انتهاء الصلاحية';

  @override
  String get noLowStock => 'لا توجد منتجات بمخزون منخفض';

  @override
  String get noExpiryAlert => 'لا توجد منتجات قريبة من الانتهاء';

  @override
  String get expiresOn => 'ينتهي في';

  @override
  String get expired => 'منتهي';

  @override
  String get expiryDate => 'تاريخ الانتهاء';

  @override
  String get edit => 'تعديل';

  @override
  String get delete => 'حذف';

  @override
  String get editProduct => 'تعديل المنتج';

  @override
  String get confirmDeleteProduct => 'إلغاء تفعيل هذا المنتج من الكتالوج؟';

  @override
  String get addClient => 'إضافة عميل';

  @override
  String get editClient => 'تعديل العميل';

  @override
  String get clientName => 'اسم العميل';

  @override
  String get loyaltyPoints => 'عمليات الولاء';

  @override
  String get clientGiftsReceived => 'الهدايا المستلمة';

  @override
  String loyaltyProgress(int current, int threshold) {
    return '$current/$threshold عمليات';
  }

  @override
  String get clientDetail => 'بطاقة العميل';

  @override
  String get loyaltyCard => 'بطاقة الولاء';

  @override
  String get loyaltyCardSubtitle => '10 مشتريات = هدية';

  @override
  String get printLoyaltyCard => 'طباعة البطاقة';

  @override
  String get printLoyaltyCardDone => 'تم تصدير بطاقة الولاء';

  @override
  String get userActive => 'نشط';

  @override
  String get userInactive => 'معطّل';

  @override
  String usersCount(int count) {
    return '$count مستخدم(ين)';
  }

  @override
  String get loyaltyProgramTitle => 'برنامج الولاء';

  @override
  String loyaltyUntilGift(int remaining) {
    return 'باقي $remaining عملية(ات) قبل الهدية';
  }

  @override
  String get giftEligible => 'هدية مستحقة';

  @override
  String get loyaltyGiftReached => 'وصل العميل إلى 10 مبيعات — هدية مستحقة!';

  @override
  String get giftOffered => 'الهدية مُقدَّمة';

  @override
  String get giftOfferedConfirm =>
      'تأكيد تقديم الهدية للعميل؟ ستُعاد البطاقة إلى 0.';

  @override
  String get giftOfferedDone => 'تم تسجيل الهدية — البطاقة من جديد';

  @override
  String get redeemGift => 'تسليم الهدية';

  @override
  String get redeemGiftConfirm =>
      'تأكيد تسليم الهدية للعميل؟ ستُعاد بطاقة الولاء إلى الصفر.';

  @override
  String get redeemGiftDone => 'تم تسجيل الهدية';

  @override
  String get redeemGiftFailed => 'تعذر تسجيل الهدية';

  @override
  String get barcodeOptionalHint => 'اختياري — يُولَّد تلقائياً إن تُرك فارغاً';

  @override
  String get removeExpiredStock => 'إخراج من المخزون';

  @override
  String get removeExpiredStockConfirm =>
      'تصفير المخزون لهذا المنتج المنتهي الصلاحية؟';

  @override
  String get removeExpiredStockDone => 'تم إخراج المخزون المنتهي';

  @override
  String get confirm => 'تأكيد';

  @override
  String get editExpense => 'تعديل المصروف';

  @override
  String get confirmDeleteExpense => 'حذف هذا المصروف؟';

  @override
  String get confirmDeleteClient => 'حذف هذا العميل نهائياً؟';

  @override
  String get addUser => 'إضافة مستخدم';

  @override
  String get editUser => 'تعديل المستخدم';

  @override
  String get fullName => 'الاسم الكامل';

  @override
  String get role => 'الدور';

  @override
  String get roleGestionnaire => 'أمين الصندوق';

  @override
  String get roleManager => 'المدير';

  @override
  String get newPassword => 'كلمة مرور جديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordMismatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordOptional => 'اتركه فارغاً للإبقاء على كلمة المرور الحالية';

  @override
  String get reportsSubtitle => 'مؤشرات اليوم وأفضل المبيعات والتطور الشهري';

  @override
  String get exportReportsHint => 'تصدير تقرير اليوم';

  @override
  String get dashboardSubtitle => 'نظرة عامة وآخر المبيعات المسجلة';

  @override
  String get posSubtitle => 'بحث المنتجات والسلة وتأكيد المبيعات';

  @override
  String get productsHubSubtitle =>
      'الكتالوج والأسعار والمخزون وتواريخ الانتهاء';

  @override
  String get alertsSubtitle => 'منتجات بمخزون منخفض أو قريبة من الانتهاء';

  @override
  String get commerceHubSubtitle => 'سجل المبيعات وإدارة العملاء';

  @override
  String get reprintReceipt => 'إعادة طباعة التذكرة';

  @override
  String get exportInvoicePdf => 'فاتورة PDF';

  @override
  String get invoiceDetail => 'تفاصيل الفاتورة';

  @override
  String get accountLocked =>
      'الحساب مقفل مؤقتاً (محاولات كثيرة). أعد المحاولة بعد 15 دقيقة.';

  @override
  String get totpCode => 'رمز المصادقة (6 أرقام)';

  @override
  String get totpInvalid => 'رمز غير صحيح';

  @override
  String get totpEnterCode => 'أدخل الرمز من تطبيق Authenticator';

  @override
  String get twoFactorAuth => 'المصادقة الثنائية (2FA)';

  @override
  String get enable2fa => 'تفعيل 2FA';

  @override
  String get disable2fa => 'إلغاء 2FA';

  @override
  String get disable2faConfirm => 'إلغاء المصادقة الثنائية لهذا الحساب؟';

  @override
  String get totpSetupHint => 'أضف هذا المفتاح في Google Authenticator:';

  @override
  String get totpEnabledSuccess => 'تم تفعيل 2FA بنجاح';

  @override
  String get totpEnabledLabel => 'مفعّلة — رمز مطلوب عند الدخول';

  @override
  String get totpDisabledLabel => 'غير مفعّلة';

  @override
  String get totpFinishSetup => 'إنهاء تفعيل 2FA';

  @override
  String get securitySettings => 'الأمان';

  @override
  String get sessionTimeout => 'تسجيل الخروج التلقائي (عدم النشاط)';

  @override
  String get sessionTimeoutNever => 'معطّل';

  @override
  String sessionTimeoutMinutes(int minutes) {
    return '$minutes دقيقة';
  }

  @override
  String get sessionExpired =>
      'انتهت الجلسة بسبب عدم النشاط. يرجى تسجيل الدخول مجدداً.';

  @override
  String get suppliers => 'الموردون';

  @override
  String get addSupplier => 'إضافة مورد';

  @override
  String get editSupplier => 'تعديل المورد';

  @override
  String get supplierName => 'اسم المورد';

  @override
  String get confirmDeleteSupplier => 'إلغاء تفعيل هذا المورد؟';

  @override
  String get adminHubSubtitle => 'الفئات والموردون والمستخدمون والإعدادات';

  @override
  String get close => 'إغلاق';

  @override
  String get reprintSent => 'تم إرسال التذكرة إلى الطابعة';

  @override
  String get noPrinterFound => 'لم يتم العثور على طابعة على هذا الجهاز';

  @override
  String get dbMigrationRequired =>
      'يجب تحديث قاعدة البيانات. نفّذ migration 004_security_2fa.sql';

  @override
  String get printError => 'خطأ في الطباعة';

  @override
  String get pdfExportReady => 'تم حفظ PDF';

  @override
  String get pdfExportFailed => 'تعذر إنشاء PDF';

  @override
  String get reportDateRange => 'فترة التقرير';

  @override
  String get reportPresetToday => 'اليوم';

  @override
  String get reportPresetWeek => '7 أيام';

  @override
  String get reportPresetMonth => '30 يوماً';

  @override
  String get reportCustomRange => 'اختيار التواريخ';

  @override
  String get periodRevenue => 'الإيرادات (الفترة)';

  @override
  String get revenueEvolution => 'تطور الإيرادات';

  @override
  String get validatingSale => 'جاري التسجيل…';

  @override
  String get saleTimeout => 'انتهت المهلة — تحقق من تشغيل PostgreSQL.';

  @override
  String get addedToCart => 'أضيف إلى السلة';

  @override
  String get saleSuccess => 'تم تسجيل البيع';

  @override
  String get expenses => 'المصروفات';

  @override
  String get addExpense => 'مصروف جديد';

  @override
  String get expenseCategory => 'نوع المصروف';

  @override
  String get expenseCategoryCashSend => 'إرسال أموال / شخص';

  @override
  String get expenseCategoryPurchase => 'شراء';

  @override
  String get expenseCategoryExit => 'مصروف / خروج';

  @override
  String get expenseCategorySupply => 'توريد';

  @override
  String get expenseCategoryOther => 'أخرى';

  @override
  String get expenseAmount => 'المبلغ';

  @override
  String get expenseBeneficiary => 'المستفيد';

  @override
  String get expenseDescription => 'الوصف';

  @override
  String get expenseDate => 'التاريخ';

  @override
  String get expensesMigrationRequired =>
      'نفّذ migration: database/migrations/005_expenses.sql';

  @override
  String get reportTabOverview => 'ملخص';

  @override
  String get reportTabSales => 'المبيعات';

  @override
  String get reportTabProducts => 'المنتجات';

  @override
  String get reportTabStock => 'المخزون';

  @override
  String get reportObjectivesTitle => 'أهداف وحدة التقارير';

  @override
  String get reportObjectivesSubtitle => 'متابعة وأداء وقرار';

  @override
  String get reportObjectives =>
      'متابعة دقيقة للنشاط التجاري\nتقييم أداء المتجر\nتحديد المنتجات المربحة\nمراقبة حركات المخزون\nتحسين التوريد\nدعم القرار الاستراتيجي\nوثائق متابعة موثوقة';

  @override
  String get reportDailyTitle => 'تقرير المبيعات (الفترة)';

  @override
  String get reportMonthlyHint =>
      'تحليل شهري — استخدم 30 يوماً أو تواريخ مخصصة';

  @override
  String get reportAnnualHint => 'تطور على 12 شهراً';

  @override
  String get estimatedProfit => 'الربح التقديري';

  @override
  String get totalDiscounts => 'إجمالي الخصومات';

  @override
  String get totalExpenses => 'المصروفات (الفترة)';

  @override
  String get netEstimate => 'النتيجة التقديرية';

  @override
  String get paymentBreakdown => 'طرق الدفع';

  @override
  String get salesByCashier => 'المبيعات حسب أمين الصندوق';

  @override
  String get periodComparison => 'مقارنة الفترة السابقة';

  @override
  String get revenueChange => 'تطور الإيرادات';

  @override
  String get lowStockReport => 'نفاد / مخزون حرج';

  @override
  String get stockHistory => 'سجل حركات المخزون';

  @override
  String get salesByCategory => 'حسب الفئة';

  @override
  String get saleCount => 'تكرار المبيعات';

  @override
  String get lastSale => 'آخر بيع';

  @override
  String get supplier => 'المورد';

  @override
  String get movementType => 'النوع';

  @override
  String get reportPresetYear => 'سنة';

  @override
  String get reportPresetCurrentMonth => 'الشهر الجاري';

  @override
  String get reportPresetLastMonth => 'الشهر الماضي';

  @override
  String get reportTabPeriods => 'شهري / سنوي';

  @override
  String get reportYearLabel => 'السنة';

  @override
  String get reportAnnualRevenue => 'إيرادات سنوية';

  @override
  String get reportYoyChange => 'التطور مقارنة بالسنة السابقة';

  @override
  String get reportMonthlyBreakdown => 'التطور الشهري';

  @override
  String get reportMonthlyTable => 'جدول شهري مفصل';

  @override
  String get reportMonthColumn => 'الشهر';

  @override
  String get reportPaymentBreakdown => 'طرق الدفع';

  @override
  String get exportAnnualReport => 'تصدير التقرير السنوي (PDF)';

  @override
  String get permissionsTitle => 'صلاحيات الكاشير';

  @override
  String get permissionsSubtitle => 'حدد الإجراءات المسموحة لهذا المستخدم.';

  @override
  String get storeSettingsHint =>
      'تظهر هذه المعلومات على الفواتير والتذاكر والتقارير المصدّرة.';

  @override
  String get storeSettingsSaved => 'تم حفظ معلومات المتجر';

  @override
  String get storeSettingsTechnical => 'الاتصال والطباعة';

  @override
  String get storeCurrency => 'العملة (الرمز)';

  @override
  String get storeCurrencyCode => 'رمز العملة (مثال XAF)';

  @override
  String get storeSloganFr => 'الشعار (فرنسي)';

  @override
  String get storeSloganAr => 'الشعار (عربي)';

  @override
  String get storeLegalInfo => 'المعلومات القانونية';

  @override
  String get storeOpeningHours => 'ساعات العمل';

  @override
  String get reportPeriodCurrent => 'الفترة المحددة';

  @override
  String get reportPeriodPrevious => 'الفترة السابقة';

  @override
  String get deleteUser => 'حذف المستخدم';

  @override
  String confirmDeleteUser(String name) {
    return 'حذف $name نهائياً؟ لا يمكن التراجع.';
  }

  @override
  String get userDeleted => 'تم حذف المستخدم';

  @override
  String get userDeleteHasSales =>
      'تعذّر الحذف: للمستخدم مبيعات مسجّلة. عطّله بدلاً من ذلك.';

  @override
  String get cannotDeleteSelf => 'لا يمكنك حذف حسابك.';

  @override
  String get cannotDeleteManager => 'لا يمكن حذف حساب المدير.';

  @override
  String get requestSaleReturn => 'طلب إرجاع';

  @override
  String get saleReturnReason => 'سبب الإرجاع';

  @override
  String get saleReturnReasonHint => 'اختياري';

  @override
  String get saleReturnRequested => 'تم إرسال طلب الإرجاع — بانتظار المدير';

  @override
  String get saleReturnPending => 'إرجاع قيد الانتظار';

  @override
  String get saleReturnPendingManager => 'إرجاع بانتظار موافقة المدير';

  @override
  String get saleReturnApproved => 'تم التحقق من الإرجاع — استُعيد المخزون';

  @override
  String get saleReturnRejected => 'تم رفض طلب الإرجاع';

  @override
  String get saleReturnFailed => 'فشل الإرجاع';

  @override
  String get saleReturnNotReturnable => 'لا يمكن إرجاع هذه العملية';

  @override
  String get saleReturnAlreadyPending => 'يوجد طلب إرجاع قيد الانتظار';

  @override
  String get saleReturnNotFound => 'العملية غير موجودة';

  @override
  String get saleReturnNotPending => 'الطلب لم يعد قيد الانتظار';

  @override
  String get saleReturnNoReason => 'بدون سبب';

  @override
  String get saleReturnMigrationRequired =>
      'نفّذ migration: database/migrations/008_sale_returns.sql';

  @override
  String pendingReturnsTitle(int count) {
    return '$count إرجاع(ات) للتحقق';
  }

  @override
  String get viewReturnDetail => 'عرض التفاصيل';

  @override
  String get pendingReturnDetailTitle => 'تفاصيل طلب الإرجاع';

  @override
  String get returnDetailProducts => 'منتجات البيع';

  @override
  String get returnDetailNotReturned => 'غير مشمول في الإرجاع';

  @override
  String saleReturnQtyLabel(int qty) {
    return 'إرجاع: $qty';
  }

  @override
  String get loyaltyStampDeductedOnReturn =>
      'سيُخصم ختم ولاء واحد من بطاقة العميل عند التحقق.';

  @override
  String get approveReturn => 'التحقق من الإرجاع';

  @override
  String get rejectReturn => 'رفض';

  @override
  String get confirmApproveReturn => 'تأكيد الإرجاع';

  @override
  String get confirmApproveReturnBody =>
      'سيُعاد المخزون حسب الكميات المطلوبة. تأكيد؟';

  @override
  String get saleReturnSelectProducts => 'المنتجات المراد إرجاعها';

  @override
  String get saleReturnSelectProductsHint =>
      'حدّد المنتجات وكمية الإرجاع لكل سطر (إلزامي إذا كانت الكمية المباعة > 1).';

  @override
  String saleReturnSoldQty(int qty) {
    return 'مباع: $qty';
  }

  @override
  String get saleReturnQtyToReturn => 'كمية الإرجاع';

  @override
  String get saleReturnSelectAtLeastOne =>
      'اختر منتجاً واحداً على الأقل للإرجاع';

  @override
  String get saleReturnInvalidQty => 'كمية إرجاع غير صالحة';

  @override
  String get confirmRejectReturn => 'رفض الإرجاع';

  @override
  String get confirmRejectReturnBody =>
      'تبقى العملية نشطة. يمكن للكاشير تقديم طلب جديد.';

  @override
  String get saleReturnsHistory => 'المرتجعات';

  @override
  String get saleReturnsEmpty => 'لا توجد طلبات إرجاع';

  @override
  String get saleReturnFilterAll => 'الكل';

  @override
  String get saleReturnFilterPending => 'قيد الانتظار';

  @override
  String get saleReturnFilterApproved => 'مقبولة';

  @override
  String get saleReturnFilterRejected => 'مرفوضة';

  @override
  String get saleReturnRequestedBy => 'طُلب بواسطة';

  @override
  String get saleReturnProcessedAt => 'تاريخ المعالجة';

  @override
  String get dashboardReturnsTitle => 'المرتجعات';

  @override
  String get dashboardReturnsPending => 'قيد الانتظار';

  @override
  String get dashboardReturnsApprovedMonth => 'مقبولة (الشهر)';

  @override
  String get dashboardReturnsRejectedMonth => 'مرفوضة (الشهر)';

  @override
  String get dashboardReturnsToday => 'مرتجعات اليوم';

  @override
  String get dashboardReturnsApprovedToday => 'مقبولة اليوم';

  @override
  String get dashboardReturnsRejectedToday => 'مرفوضة اليوم';

  @override
  String get dashboardDailySubtitle => 'نشاط اليوم — تُحدَّث البيانات يومياً';

  @override
  String get dashboardTodaySales => 'مبيعات اليوم';

  @override
  String get reportReturnsTitle => 'المرتجعات (الفترة)';

  @override
  String get reportReturnsRequested => 'طلبات';

  @override
  String get reportReturnsApproved => 'مقبولة';

  @override
  String get reportReturnsRejected => 'مرفوضة';

  @override
  String get saleReturnForbidden => 'المدير فقط يمكنه قبول أو رفض الإرجاع';

  @override
  String get columnNumber => 'م';

  @override
  String get columnActions => 'إجراءات';

  @override
  String tableProductsCount(int count) {
    return '$count منتج';
  }

  @override
  String tableClientsCount(int count) {
    return '$count عميل';
  }

  @override
  String tableItemsCount(int count) {
    return '$count عنصر';
  }

  @override
  String get columnMinStock => 'الحد الأدنى';

  @override
  String get columnDaysLeft => 'أيام متبقية';
}
