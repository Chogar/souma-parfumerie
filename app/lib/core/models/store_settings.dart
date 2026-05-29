import 'package:souma_parfumerie/core/config/app_config.dart';

/// Informations générales de la boutique (factures, rapports, tickets).
class StoreSettings {
  const StoreSettings({
    required this.nameFr,
    required this.nameAr,
    this.address = '',
    this.phone = '',
    this.email = '',
    this.currencySymbol = AppConfig.currencySymbol,
    this.currencyCode = 'XAF',
    this.sloganFr = '',
    this.sloganAr = '',
    this.legalInfo = '',
    this.openingHours = '',
  });

  final String nameFr;
  final String nameAr;
  final String address;
  final String phone;
  final String email;
  final String currencySymbol;
  final String currencyCode;
  final String sloganFr;
  final String sloganAr;
  final String legalInfo;
  final String openingHours;

  static const defaults = StoreSettings(
    nameFr: 'Souma Parfumerie',
    nameAr: 'سوما للعطور',
  );

  String displayName(String locale) =>
      locale.startsWith('ar') ? nameAr : nameFr;

  String? displaySlogan(String locale) {
    final s = locale.startsWith('ar') ? sloganAr : sloganFr;
    return s.isEmpty ? null : s;
  }

  factory StoreSettings.fromJson(Map<String, dynamic> json) {
    return StoreSettings(
      nameFr: json['name_fr']?.toString() ?? defaults.nameFr,
      nameAr: json['name_ar']?.toString() ?? defaults.nameAr,
      address: json['address']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      currencySymbol:
          json['currency_symbol']?.toString() ?? AppConfig.currencySymbol,
      currencyCode: json['currency_code']?.toString() ?? 'XAF',
      sloganFr: json['slogan_fr']?.toString() ?? '',
      sloganAr: json['slogan_ar']?.toString() ?? '',
      legalInfo: json['legal_info']?.toString() ?? '',
      openingHours: json['opening_hours']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name_fr': nameFr,
        'name_ar': nameAr,
        'address': address,
        'phone': phone,
        'email': email,
        'currency_symbol': currencySymbol,
        'currency_code': currencyCode,
        'slogan_fr': sloganFr,
        'slogan_ar': sloganAr,
        'legal_info': legalInfo,
        'opening_hours': openingHours,
      };

  StoreSettings copyWith({
    String? nameFr,
    String? nameAr,
    String? address,
    String? phone,
    String? email,
    String? currencySymbol,
    String? currencyCode,
    String? sloganFr,
    String? sloganAr,
    String? legalInfo,
    String? openingHours,
  }) {
    return StoreSettings(
      nameFr: nameFr ?? this.nameFr,
      nameAr: nameAr ?? this.nameAr,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      currencyCode: currencyCode ?? this.currencyCode,
      sloganFr: sloganFr ?? this.sloganFr,
      sloganAr: sloganAr ?? this.sloganAr,
      legalInfo: legalInfo ?? this.legalInfo,
      openingHours: openingHours ?? this.openingHours,
    );
  }
}
