import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('fr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In fr, this message translates to:
  /// **'Souma Parfumerie'**
  String get appTitle;

  /// No description provided for @appWindowTitle.
  ///
  /// In fr, this message translates to:
  /// **'Souma Perfumery Management System'**
  String get appWindowTitle;

  /// No description provided for @storeName.
  ///
  /// In fr, this message translates to:
  /// **'Souma Parfumerie'**
  String get storeName;

  /// No description provided for @projectFooter.
  ///
  /// In fr, this message translates to:
  /// **'Réalisé par Expérience Tech'**
  String get projectFooter;

  /// No description provided for @projectFooterPrefix.
  ///
  /// In fr, this message translates to:
  /// **'Réalisé par'**
  String get projectFooterPrefix;

  /// No description provided for @experienceTechLink.
  ///
  /// In fr, this message translates to:
  /// **'Expérience Tech'**
  String get experienceTechLink;

  /// No description provided for @login.
  ///
  /// In fr, this message translates to:
  /// **'Connexion'**
  String get login;

  /// No description provided for @username.
  ///
  /// In fr, this message translates to:
  /// **'Identifiant'**
  String get username;

  /// No description provided for @password.
  ///
  /// In fr, this message translates to:
  /// **'Mot de passe'**
  String get password;

  /// No description provided for @signIn.
  ///
  /// In fr, this message translates to:
  /// **'Se connecter'**
  String get signIn;

  /// No description provided for @signOut.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion'**
  String get signOut;

  /// No description provided for @pos.
  ///
  /// In fr, this message translates to:
  /// **'Caisse'**
  String get pos;

  /// No description provided for @catalog.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get catalog;

  /// No description provided for @stock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get stock;

  /// No description provided for @reports.
  ///
  /// In fr, this message translates to:
  /// **'Rapports'**
  String get reports;

  /// No description provided for @settings.
  ///
  /// In fr, this message translates to:
  /// **'Paramètres'**
  String get settings;

  /// No description provided for @users.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateurs'**
  String get users;

  /// No description provided for @dashboard.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord'**
  String get dashboard;

  /// No description provided for @scanBarcode.
  ///
  /// In fr, this message translates to:
  /// **'Scanner un code-barres'**
  String get scanBarcode;

  /// No description provided for @barcodeHint.
  ///
  /// In fr, this message translates to:
  /// **'Code-barres ou référence…'**
  String get barcodeHint;

  /// No description provided for @subtotal.
  ///
  /// In fr, this message translates to:
  /// **'Sous-total'**
  String get subtotal;

  /// No description provided for @discount.
  ///
  /// In fr, this message translates to:
  /// **'Remise'**
  String get discount;

  /// No description provided for @total.
  ///
  /// In fr, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @cash.
  ///
  /// In fr, this message translates to:
  /// **'Espèces'**
  String get cash;

  /// No description provided for @card.
  ///
  /// In fr, this message translates to:
  /// **'Carte'**
  String get card;

  /// No description provided for @mobile.
  ///
  /// In fr, this message translates to:
  /// **'Mobile'**
  String get mobile;

  /// No description provided for @amountPaid.
  ///
  /// In fr, this message translates to:
  /// **'Montant reçu'**
  String get amountPaid;

  /// No description provided for @change.
  ///
  /// In fr, this message translates to:
  /// **'Monnaie à rendre'**
  String get change;

  /// No description provided for @validateSale.
  ///
  /// In fr, this message translates to:
  /// **'Valider la vente'**
  String get validateSale;

  /// No description provided for @clearCart.
  ///
  /// In fr, this message translates to:
  /// **'Vider le panier'**
  String get clearCart;

  /// No description provided for @stockAlert.
  ///
  /// In fr, this message translates to:
  /// **'Stock insuffisant'**
  String get stockAlert;

  /// No description provided for @outOfStock.
  ///
  /// In fr, this message translates to:
  /// **'Rupture de stock'**
  String get outOfStock;

  /// No description provided for @lowStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock critique'**
  String get lowStock;

  /// No description provided for @sync.
  ///
  /// In fr, this message translates to:
  /// **'Synchronisation'**
  String get sync;

  /// No description provided for @syncNow.
  ///
  /// In fr, this message translates to:
  /// **'Synchroniser'**
  String get syncNow;

  /// No description provided for @lastSync.
  ///
  /// In fr, this message translates to:
  /// **'Dernière sync'**
  String get lastSync;

  /// No description provided for @online.
  ///
  /// In fr, this message translates to:
  /// **'En ligne'**
  String get online;

  /// No description provided for @offline.
  ///
  /// In fr, this message translates to:
  /// **'Hors ligne'**
  String get offline;

  /// No description provided for @language.
  ///
  /// In fr, this message translates to:
  /// **'Langue'**
  String get language;

  /// No description provided for @french.
  ///
  /// In fr, this message translates to:
  /// **'Français'**
  String get french;

  /// No description provided for @arabic.
  ///
  /// In fr, this message translates to:
  /// **'العربية'**
  String get arabic;

  /// No description provided for @dailySales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes du jour'**
  String get dailySales;

  /// No description provided for @myDailySales.
  ///
  /// In fr, this message translates to:
  /// **'Mes ventes du jour'**
  String get myDailySales;

  /// No description provided for @mySalesOnly.
  ///
  /// In fr, this message translates to:
  /// **'Affichage limité à vos ventes'**
  String get mySalesOnly;

  /// No description provided for @transactions.
  ///
  /// In fr, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @averageBasket.
  ///
  /// In fr, this message translates to:
  /// **'Panier moyen'**
  String get averageBasket;

  /// No description provided for @topProducts.
  ///
  /// In fr, this message translates to:
  /// **'Top ventes'**
  String get topProducts;

  /// No description provided for @topProductsShowMore.
  ///
  /// In fr, this message translates to:
  /// **'Plus de détails ({count})'**
  String topProductsShowMore(int count);

  /// No description provided for @exportPdf.
  ///
  /// In fr, this message translates to:
  /// **'Exporter PDF'**
  String get exportPdf;

  /// No description provided for @exportExcel.
  ///
  /// In fr, this message translates to:
  /// **'Exporter Excel'**
  String get exportExcel;

  /// No description provided for @products.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get products;

  /// No description provided for @categories.
  ///
  /// In fr, this message translates to:
  /// **'Catégories'**
  String get categories;

  /// No description provided for @price.
  ///
  /// In fr, this message translates to:
  /// **'Prix'**
  String get price;

  /// No description provided for @quantity.
  ///
  /// In fr, this message translates to:
  /// **'Quantité'**
  String get quantity;

  /// No description provided for @save.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrer'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In fr, this message translates to:
  /// **'Annuler'**
  String get cancel;

  /// No description provided for @search.
  ///
  /// In fr, this message translates to:
  /// **'Rechercher'**
  String get search;

  /// No description provided for @noData.
  ///
  /// In fr, this message translates to:
  /// **'Aucune donnée'**
  String get noData;

  /// No description provided for @errorGeneric.
  ///
  /// In fr, this message translates to:
  /// **'Une erreur est survenue'**
  String get errorGeneric;

  /// No description provided for @loginError.
  ///
  /// In fr, this message translates to:
  /// **'Identifiants incorrects'**
  String get loginError;

  /// No description provided for @connectionError.
  ///
  /// In fr, this message translates to:
  /// **'Connexion à PostgreSQL impossible. Vérifiez que le serveur est démarré.'**
  String get connectionError;

  /// No description provided for @showPassword.
  ///
  /// In fr, this message translates to:
  /// **'Afficher le mot de passe'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In fr, this message translates to:
  /// **'Masquer le mot de passe'**
  String get hidePassword;

  /// No description provided for @welcome.
  ///
  /// In fr, this message translates to:
  /// **'Bienvenue'**
  String get welcome;

  /// No description provided for @managerOnly.
  ///
  /// In fr, this message translates to:
  /// **'Réservé au Manager'**
  String get managerOnly;

  /// No description provided for @invoice.
  ///
  /// In fr, this message translates to:
  /// **'Facture'**
  String get invoice;

  /// No description provided for @clientPhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone client'**
  String get clientPhone;

  /// No description provided for @clientPhoneSearchHint.
  ///
  /// In fr, this message translates to:
  /// **'Saisir pour rechercher en base…'**
  String get clientPhoneSearchHint;

  /// No description provided for @backup.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde'**
  String get backup;

  /// No description provided for @runBackup.
  ///
  /// In fr, this message translates to:
  /// **'Lancer une sauvegarde'**
  String get runBackup;

  /// No description provided for @backupDone.
  ///
  /// In fr, this message translates to:
  /// **'Sauvegarde créée'**
  String get backupDone;

  /// No description provided for @backupFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec de la sauvegarde'**
  String get backupFailed;

  /// No description provided for @backupPgDumpMissing.
  ///
  /// In fr, this message translates to:
  /// **'pg_dump introuvable. Installez PostgreSQL (ex. brew install postgresql@14) ou ajoutez son dossier bin au PATH.'**
  String get backupPgDumpMissing;

  /// No description provided for @salesHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique ventes'**
  String get salesHistory;

  /// No description provided for @clients.
  ///
  /// In fr, this message translates to:
  /// **'Clients'**
  String get clients;

  /// No description provided for @recentSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes récentes'**
  String get recentSales;

  /// No description provided for @dashboardManager.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord administrateur'**
  String get dashboardManager;

  /// No description provided for @dashboardGestionnaire.
  ///
  /// In fr, this message translates to:
  /// **'Tableau de bord caisse'**
  String get dashboardGestionnaire;

  /// No description provided for @storeSettings.
  ///
  /// In fr, this message translates to:
  /// **'Informations boutique'**
  String get storeSettings;

  /// No description provided for @storeNameFieldLabel.
  ///
  /// In fr, this message translates to:
  /// **'Nom de la boutique (paramètres)'**
  String get storeNameFieldLabel;

  /// No description provided for @storeAddress.
  ///
  /// In fr, this message translates to:
  /// **'Adresse'**
  String get storeAddress;

  /// No description provided for @storePhone.
  ///
  /// In fr, this message translates to:
  /// **'Téléphone'**
  String get storePhone;

  /// No description provided for @storeEmail.
  ///
  /// In fr, this message translates to:
  /// **'Email'**
  String get storeEmail;

  /// No description provided for @rememberCredentials.
  ///
  /// In fr, this message translates to:
  /// **'Mémoriser l\'identifiant et le mot de passe'**
  String get rememberCredentials;

  /// No description provided for @menuBoutique.
  ///
  /// In fr, this message translates to:
  /// **'Produit'**
  String get menuBoutique;

  /// No description provided for @menuCommerce.
  ///
  /// In fr, this message translates to:
  /// **'Ventes & clients'**
  String get menuCommerce;

  /// No description provided for @menuAdministration.
  ///
  /// In fr, this message translates to:
  /// **'Administration'**
  String get menuAdministration;

  /// No description provided for @addProduct.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un produit'**
  String get addProduct;

  /// No description provided for @inStockProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits en stock'**
  String get inStockProducts;

  /// No description provided for @selectProductHint.
  ///
  /// In fr, this message translates to:
  /// **'Cliquez sur un produit pour l\'ajouter au panier'**
  String get selectProductHint;

  /// No description provided for @productNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit trouvé pour ce code-barres'**
  String get productNotFound;

  /// No description provided for @productExpired.
  ///
  /// In fr, this message translates to:
  /// **'Ce produit est périmé et ne peut pas être vendu'**
  String get productExpired;

  /// No description provided for @posCatalogEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Scannez ou recherchez un produit'**
  String get posCatalogEmpty;

  /// No description provided for @brand.
  ///
  /// In fr, this message translates to:
  /// **'Marque'**
  String get brand;

  /// No description provided for @nameFr.
  ///
  /// In fr, this message translates to:
  /// **'Nom (français)'**
  String get nameFr;

  /// No description provided for @nameAr.
  ///
  /// In fr, this message translates to:
  /// **'Nom (arabe)'**
  String get nameAr;

  /// No description provided for @purchasePrice.
  ///
  /// In fr, this message translates to:
  /// **'Prix d\'achat'**
  String get purchasePrice;

  /// No description provided for @initialStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock initial'**
  String get initialStock;

  /// No description provided for @category.
  ///
  /// In fr, this message translates to:
  /// **'Catégorie'**
  String get category;

  /// No description provided for @barcode.
  ///
  /// In fr, this message translates to:
  /// **'Code-barres / référence'**
  String get barcode;

  /// No description provided for @monthlyRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires mensuel'**
  String get monthlyRevenue;

  /// No description provided for @cart.
  ///
  /// In fr, this message translates to:
  /// **'Panier'**
  String get cart;

  /// No description provided for @emptyCart.
  ///
  /// In fr, this message translates to:
  /// **'Panier vide — sélectionnez un produit ci-dessus'**
  String get emptyCart;

  /// No description provided for @tapToAddProduct.
  ///
  /// In fr, this message translates to:
  /// **'Touchez un produit pour l\'ajouter au panier'**
  String get tapToAddProduct;

  /// No description provided for @minStockAlert.
  ///
  /// In fr, this message translates to:
  /// **'Seuil d\'alerte stock'**
  String get minStockAlert;

  /// No description provided for @minStockAlertHint.
  ///
  /// In fr, this message translates to:
  /// **'Alerte stock faible lorsque la quantité atteint ce niveau ou moins'**
  String get minStockAlertHint;

  /// No description provided for @paymentMethod.
  ///
  /// In fr, this message translates to:
  /// **'Mode de paiement'**
  String get paymentMethod;

  /// No description provided for @alerts.
  ///
  /// In fr, this message translates to:
  /// **'Alertes'**
  String get alerts;

  /// No description provided for @lowStockTab.
  ///
  /// In fr, this message translates to:
  /// **'Stock faible'**
  String get lowStockTab;

  /// No description provided for @expiryTab.
  ///
  /// In fr, this message translates to:
  /// **'Expiration proche'**
  String get expiryTab;

  /// No description provided for @noLowStock.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit en stock faible'**
  String get noLowStock;

  /// No description provided for @noExpiryAlert.
  ///
  /// In fr, this message translates to:
  /// **'Aucun produit proche de l\'expiration'**
  String get noExpiryAlert;

  /// No description provided for @expiresOn.
  ///
  /// In fr, this message translates to:
  /// **'Expire le'**
  String get expiresOn;

  /// No description provided for @expired.
  ///
  /// In fr, this message translates to:
  /// **'Expiré'**
  String get expired;

  /// No description provided for @expiryDate.
  ///
  /// In fr, this message translates to:
  /// **'Date d\'expiration'**
  String get expiryDate;

  /// No description provided for @edit.
  ///
  /// In fr, this message translates to:
  /// **'Modifier'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer'**
  String get delete;

  /// No description provided for @editProduct.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le produit'**
  String get editProduct;

  /// No description provided for @confirmDeleteProduct.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver ce produit du catalogue ?'**
  String get confirmDeleteProduct;

  /// No description provided for @addClient.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un client'**
  String get addClient;

  /// No description provided for @editClient.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le client'**
  String get editClient;

  /// No description provided for @clientName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du client'**
  String get clientName;

  /// No description provided for @loyaltyPoints.
  ///
  /// In fr, this message translates to:
  /// **'Validations fidélité'**
  String get loyaltyPoints;

  /// No description provided for @clientGiftsReceived.
  ///
  /// In fr, this message translates to:
  /// **'Cadeaux reçus'**
  String get clientGiftsReceived;

  /// No description provided for @loyaltyProgress.
  ///
  /// In fr, this message translates to:
  /// **'{current}/{threshold} validations'**
  String loyaltyProgress(int current, int threshold);

  /// No description provided for @clientDetail.
  ///
  /// In fr, this message translates to:
  /// **'Fiche client'**
  String get clientDetail;

  /// No description provided for @loyaltyCard.
  ///
  /// In fr, this message translates to:
  /// **'Carte de fidélité'**
  String get loyaltyCard;

  /// No description provided for @loyaltyCardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'10 achats = 1 cadeau'**
  String get loyaltyCardSubtitle;

  /// No description provided for @printLoyaltyCard.
  ///
  /// In fr, this message translates to:
  /// **'Imprimer la carte'**
  String get printLoyaltyCard;

  /// No description provided for @printLoyaltyCardDone.
  ///
  /// In fr, this message translates to:
  /// **'Carte de fidélité exportée'**
  String get printLoyaltyCardDone;

  /// No description provided for @userActive.
  ///
  /// In fr, this message translates to:
  /// **'Actif'**
  String get userActive;

  /// No description provided for @userInactive.
  ///
  /// In fr, this message translates to:
  /// **'Inactif'**
  String get userInactive;

  /// No description provided for @usersCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} utilisateur(s)'**
  String usersCount(int count);

  /// No description provided for @loyaltyProgramTitle.
  ///
  /// In fr, this message translates to:
  /// **'Programme fidélité'**
  String get loyaltyProgramTitle;

  /// No description provided for @loyaltyUntilGift.
  ///
  /// In fr, this message translates to:
  /// **'Encore {remaining} validation(s) avant le cadeau'**
  String loyaltyUntilGift(int remaining);

  /// No description provided for @giftEligible.
  ///
  /// In fr, this message translates to:
  /// **'Cadeau à offrir'**
  String get giftEligible;

  /// No description provided for @loyaltyGiftReached.
  ///
  /// In fr, this message translates to:
  /// **'Ce client a atteint 10 ventes — cadeau à offrir !'**
  String get loyaltyGiftReached;

  /// No description provided for @giftOffered.
  ///
  /// In fr, this message translates to:
  /// **'Cadeau offert'**
  String get giftOffered;

  /// No description provided for @giftOfferedConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer que le cadeau a été offert au client ? La carte repartira à 0 validation.'**
  String get giftOfferedConfirm;

  /// No description provided for @giftOfferedDone.
  ///
  /// In fr, this message translates to:
  /// **'Cadeau enregistré — carte remise à zéro'**
  String get giftOfferedDone;

  /// No description provided for @redeemGift.
  ///
  /// In fr, this message translates to:
  /// **'Cadeau remis'**
  String get redeemGift;

  /// No description provided for @redeemGiftConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer que le cadeau a été remis au client ? La carte de fidélité sera remise à zéro.'**
  String get redeemGiftConfirm;

  /// No description provided for @redeemGiftDone.
  ///
  /// In fr, this message translates to:
  /// **'Cadeau enregistré'**
  String get redeemGiftDone;

  /// No description provided for @redeemGiftFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible d\'enregistrer le cadeau'**
  String get redeemGiftFailed;

  /// No description provided for @barcodeOptionalHint.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel — généré automatiquement si vide'**
  String get barcodeOptionalHint;

  /// No description provided for @removeExpiredStock.
  ///
  /// In fr, this message translates to:
  /// **'Retirer du stock'**
  String get removeExpiredStock;

  /// No description provided for @removeExpiredStockConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Mettre le stock à zéro pour ce produit expiré ?'**
  String get removeExpiredStockConfirm;

  /// No description provided for @removeExpiredStockDone.
  ///
  /// In fr, this message translates to:
  /// **'Stock expiré retiré'**
  String get removeExpiredStockDone;

  /// No description provided for @confirm.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer'**
  String get confirm;

  /// No description provided for @editExpense.
  ///
  /// In fr, this message translates to:
  /// **'Modifier la dépense'**
  String get editExpense;

  /// No description provided for @confirmDeleteExpense.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer cette dépense ?'**
  String get confirmDeleteExpense;

  /// No description provided for @confirmDeleteClient.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement ce client ?'**
  String get confirmDeleteClient;

  /// No description provided for @addUser.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un utilisateur'**
  String get addUser;

  /// No description provided for @editUser.
  ///
  /// In fr, this message translates to:
  /// **'Modifier l\'utilisateur'**
  String get editUser;

  /// No description provided for @fullName.
  ///
  /// In fr, this message translates to:
  /// **'Nom complet'**
  String get fullName;

  /// No description provided for @role.
  ///
  /// In fr, this message translates to:
  /// **'Rôle'**
  String get role;

  /// No description provided for @roleGestionnaire.
  ///
  /// In fr, this message translates to:
  /// **'Gestionnaire (caisse)'**
  String get roleGestionnaire;

  /// No description provided for @roleManager.
  ///
  /// In fr, this message translates to:
  /// **'Manager (admin)'**
  String get roleManager;

  /// No description provided for @newPassword.
  ///
  /// In fr, this message translates to:
  /// **'Nouveau mot de passe'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le mot de passe'**
  String get confirmPassword;

  /// No description provided for @passwordMismatch.
  ///
  /// In fr, this message translates to:
  /// **'Les mots de passe ne correspondent pas'**
  String get passwordMismatch;

  /// No description provided for @passwordOptional.
  ///
  /// In fr, this message translates to:
  /// **'Laisser vide pour ne pas changer'**
  String get passwordOptional;

  /// No description provided for @reportsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Indicateurs du jour, meilleures ventes et évolution mensuelle'**
  String get reportsSubtitle;

  /// No description provided for @exportReportsHint.
  ///
  /// In fr, this message translates to:
  /// **'Exporter le rapport du jour'**
  String get exportReportsHint;

  /// No description provided for @dashboardSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Vue d\'ensemble et dernières ventes enregistrées'**
  String get dashboardSubtitle;

  /// No description provided for @posSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Recherche produits, panier et validation des ventes'**
  String get posSubtitle;

  /// No description provided for @productsHubSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Catalogue, prix, stock et dates d\'expiration'**
  String get productsHubSubtitle;

  /// No description provided for @alertsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Produits en stock faible ou proches de l\'expiration'**
  String get alertsSubtitle;

  /// No description provided for @commerceHubSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Historique des ventes et gestion des clients'**
  String get commerceHubSubtitle;

  /// No description provided for @reprintReceipt.
  ///
  /// In fr, this message translates to:
  /// **'Réimprimer le ticket'**
  String get reprintReceipt;

  /// No description provided for @exportInvoicePdf.
  ///
  /// In fr, this message translates to:
  /// **'Facture PDF'**
  String get exportInvoicePdf;

  /// No description provided for @invoiceDetail.
  ///
  /// In fr, this message translates to:
  /// **'Détail de la facture'**
  String get invoiceDetail;

  /// No description provided for @accountLocked.
  ///
  /// In fr, this message translates to:
  /// **'Compte temporairement verrouillé (trop de tentatives). Réessayez dans 15 minutes.'**
  String get accountLocked;

  /// No description provided for @totpCode.
  ///
  /// In fr, this message translates to:
  /// **'Code d\'authentification (6 chiffres)'**
  String get totpCode;

  /// No description provided for @totpInvalid.
  ///
  /// In fr, this message translates to:
  /// **'Code incorrect'**
  String get totpInvalid;

  /// No description provided for @totpEnterCode.
  ///
  /// In fr, this message translates to:
  /// **'Saisissez le code affiché dans votre application Authenticator'**
  String get totpEnterCode;

  /// No description provided for @twoFactorAuth.
  ///
  /// In fr, this message translates to:
  /// **'Authentification à deux facteurs (2FA)'**
  String get twoFactorAuth;

  /// No description provided for @enable2fa.
  ///
  /// In fr, this message translates to:
  /// **'Activer la 2FA'**
  String get enable2fa;

  /// No description provided for @disable2fa.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la 2FA'**
  String get disable2fa;

  /// No description provided for @disable2faConfirm.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver la double authentification pour votre compte ?'**
  String get disable2faConfirm;

  /// No description provided for @totpSetupHint.
  ///
  /// In fr, this message translates to:
  /// **'Ajoutez ce secret dans Google Authenticator (ou équivalent) :'**
  String get totpSetupHint;

  /// No description provided for @totpEnabledSuccess.
  ///
  /// In fr, this message translates to:
  /// **'2FA activée avec succès'**
  String get totpEnabledSuccess;

  /// No description provided for @totpEnabledLabel.
  ///
  /// In fr, this message translates to:
  /// **'Activée — code requis à la connexion'**
  String get totpEnabledLabel;

  /// No description provided for @totpDisabledLabel.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get totpDisabledLabel;

  /// No description provided for @totpFinishSetup.
  ///
  /// In fr, this message translates to:
  /// **'Terminer l\'activation 2FA'**
  String get totpFinishSetup;

  /// No description provided for @securitySettings.
  ///
  /// In fr, this message translates to:
  /// **'Sécurité'**
  String get securitySettings;

  /// No description provided for @sessionTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Déconnexion automatique (inactivité)'**
  String get sessionTimeout;

  /// No description provided for @sessionTimeoutNever.
  ///
  /// In fr, this message translates to:
  /// **'Désactivée'**
  String get sessionTimeoutNever;

  /// No description provided for @sessionTimeoutMinutes.
  ///
  /// In fr, this message translates to:
  /// **'{minutes} minutes'**
  String sessionTimeoutMinutes(int minutes);

  /// No description provided for @sessionExpired.
  ///
  /// In fr, this message translates to:
  /// **'Session expirée pour inactivité. Veuillez vous reconnecter.'**
  String get sessionExpired;

  /// No description provided for @suppliers.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseurs'**
  String get suppliers;

  /// No description provided for @addSupplier.
  ///
  /// In fr, this message translates to:
  /// **'Ajouter un fournisseur'**
  String get addSupplier;

  /// No description provided for @editSupplier.
  ///
  /// In fr, this message translates to:
  /// **'Modifier le fournisseur'**
  String get editSupplier;

  /// No description provided for @supplierName.
  ///
  /// In fr, this message translates to:
  /// **'Nom du fournisseur'**
  String get supplierName;

  /// No description provided for @confirmDeleteSupplier.
  ///
  /// In fr, this message translates to:
  /// **'Désactiver ce fournisseur ?'**
  String get confirmDeleteSupplier;

  /// No description provided for @adminHubSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Catégories, fournisseurs, utilisateurs et paramètres'**
  String get adminHubSubtitle;

  /// No description provided for @close.
  ///
  /// In fr, this message translates to:
  /// **'Fermer'**
  String get close;

  /// No description provided for @reprintSent.
  ///
  /// In fr, this message translates to:
  /// **'Ticket envoyé à l\'imprimante'**
  String get reprintSent;

  /// No description provided for @noPrinterFound.
  ///
  /// In fr, this message translates to:
  /// **'Aucune imprimante détectée sur ce poste'**
  String get noPrinterFound;

  /// No description provided for @dbMigrationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Base de données à mettre à jour. Exécutez : psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/004_security_2fa.sql'**
  String get dbMigrationRequired;

  /// No description provided for @printError.
  ///
  /// In fr, this message translates to:
  /// **'Erreur d\'impression'**
  String get printError;

  /// No description provided for @pdfExportReady.
  ///
  /// In fr, this message translates to:
  /// **'PDF enregistré'**
  String get pdfExportReady;

  /// No description provided for @pdfExportFailed.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de générer le PDF'**
  String get pdfExportFailed;

  /// No description provided for @reportDateRange.
  ///
  /// In fr, this message translates to:
  /// **'Période du rapport'**
  String get reportDateRange;

  /// No description provided for @reportPresetToday.
  ///
  /// In fr, this message translates to:
  /// **'Aujourd\'hui'**
  String get reportPresetToday;

  /// No description provided for @reportPresetWeek.
  ///
  /// In fr, this message translates to:
  /// **'7 jours'**
  String get reportPresetWeek;

  /// No description provided for @reportPresetMonth.
  ///
  /// In fr, this message translates to:
  /// **'30 jours'**
  String get reportPresetMonth;

  /// No description provided for @reportCustomRange.
  ///
  /// In fr, this message translates to:
  /// **'Choisir les dates'**
  String get reportCustomRange;

  /// No description provided for @periodRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Chiffre d\'affaires (période)'**
  String get periodRevenue;

  /// No description provided for @revenueEvolution.
  ///
  /// In fr, this message translates to:
  /// **'Évolution du CA'**
  String get revenueEvolution;

  /// No description provided for @validatingSale.
  ///
  /// In fr, this message translates to:
  /// **'Enregistrement…'**
  String get validatingSale;

  /// No description provided for @saleTimeout.
  ///
  /// In fr, this message translates to:
  /// **'Délai dépassé — vérifiez que PostgreSQL est démarré.'**
  String get saleTimeout;

  /// No description provided for @addedToCart.
  ///
  /// In fr, this message translates to:
  /// **'Ajouté au panier'**
  String get addedToCart;

  /// No description provided for @saleSuccess.
  ///
  /// In fr, this message translates to:
  /// **'Vente enregistrée'**
  String get saleSuccess;

  /// No description provided for @expenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses'**
  String get expenses;

  /// No description provided for @addExpense.
  ///
  /// In fr, this message translates to:
  /// **'Nouvelle dépense'**
  String get addExpense;

  /// No description provided for @expenseCategory.
  ///
  /// In fr, this message translates to:
  /// **'Type de dépense'**
  String get expenseCategory;

  /// No description provided for @expenseCategoryCashSend.
  ///
  /// In fr, this message translates to:
  /// **'Envoi d\'argent / personne'**
  String get expenseCategoryCashSend;

  /// No description provided for @expenseCategoryPurchase.
  ///
  /// In fr, this message translates to:
  /// **'Achat'**
  String get expenseCategoryPurchase;

  /// No description provided for @expenseCategoryExit.
  ///
  /// In fr, this message translates to:
  /// **'Sortie / frais'**
  String get expenseCategoryExit;

  /// No description provided for @expenseCategorySupply.
  ///
  /// In fr, this message translates to:
  /// **'Approvisionnement'**
  String get expenseCategorySupply;

  /// No description provided for @expenseCategoryOther.
  ///
  /// In fr, this message translates to:
  /// **'Autre'**
  String get expenseCategoryOther;

  /// No description provided for @expenseAmount.
  ///
  /// In fr, this message translates to:
  /// **'Montant'**
  String get expenseAmount;

  /// No description provided for @expenseBeneficiary.
  ///
  /// In fr, this message translates to:
  /// **'Bénéficiaire / destinataire'**
  String get expenseBeneficiary;

  /// No description provided for @expenseDescription.
  ///
  /// In fr, this message translates to:
  /// **'Description'**
  String get expenseDescription;

  /// No description provided for @expenseDate.
  ///
  /// In fr, this message translates to:
  /// **'Date'**
  String get expenseDate;

  /// No description provided for @expensesMigrationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Exécutez la migration : psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/005_expenses.sql'**
  String get expensesMigrationRequired;

  /// No description provided for @reportTabOverview.
  ///
  /// In fr, this message translates to:
  /// **'Synthèse'**
  String get reportTabOverview;

  /// No description provided for @reportTabSales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes'**
  String get reportTabSales;

  /// No description provided for @reportTabProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits'**
  String get reportTabProducts;

  /// No description provided for @reportTabStock.
  ///
  /// In fr, this message translates to:
  /// **'Stock'**
  String get reportTabStock;

  /// No description provided for @reportObjectivesTitle.
  ///
  /// In fr, this message translates to:
  /// **'Objectifs du module rapports'**
  String get reportObjectivesTitle;

  /// No description provided for @reportObjectivesSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'CDC — suivi, performance et décision'**
  String get reportObjectivesSubtitle;

  /// No description provided for @reportObjectives.
  ///
  /// In fr, this message translates to:
  /// **'Suivi précis des activités commerciales\nÉvaluation des performances de la boutique\nIdentification des produits rentables\nContrôle des mouvements de stock\nAmélioration des approvisionnements\nAide à la décision stratégique\nDocuments de suivi fiables et exploitables'**
  String get reportObjectives;

  /// No description provided for @reportDailyTitle.
  ///
  /// In fr, this message translates to:
  /// **'Rapport des ventes (période)'**
  String get reportDailyTitle;

  /// No description provided for @reportMonthlyHint.
  ///
  /// In fr, this message translates to:
  /// **'Analyse mensuelle — utilisez le filtre 30 jours ou dates personnalisées'**
  String get reportMonthlyHint;

  /// No description provided for @reportAnnualHint.
  ///
  /// In fr, this message translates to:
  /// **'Évolution sur 12 mois (graphique ci-dessous)'**
  String get reportAnnualHint;

  /// No description provided for @estimatedProfit.
  ///
  /// In fr, this message translates to:
  /// **'Bénéfice estimé'**
  String get estimatedProfit;

  /// No description provided for @totalDiscounts.
  ///
  /// In fr, this message translates to:
  /// **'Remises accordées'**
  String get totalDiscounts;

  /// No description provided for @totalExpenses.
  ///
  /// In fr, this message translates to:
  /// **'Dépenses (période)'**
  String get totalExpenses;

  /// No description provided for @netEstimate.
  ///
  /// In fr, this message translates to:
  /// **'Résultat estimé (CA − dépenses)'**
  String get netEstimate;

  /// No description provided for @paymentBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Modes de paiement'**
  String get paymentBreakdown;

  /// No description provided for @salesByCashier.
  ///
  /// In fr, this message translates to:
  /// **'Ventes par caissier'**
  String get salesByCashier;

  /// No description provided for @periodComparison.
  ///
  /// In fr, this message translates to:
  /// **'Comparaison période précédente'**
  String get periodComparison;

  /// No description provided for @revenueChange.
  ///
  /// In fr, this message translates to:
  /// **'Évolution du CA'**
  String get revenueChange;

  /// No description provided for @lowStockReport.
  ///
  /// In fr, this message translates to:
  /// **'Produits en rupture / stock critique'**
  String get lowStockReport;

  /// No description provided for @stockHistory.
  ///
  /// In fr, this message translates to:
  /// **'Historique des mouvements de stock'**
  String get stockHistory;

  /// No description provided for @salesByCategory.
  ///
  /// In fr, this message translates to:
  /// **'Répartition par catégorie'**
  String get salesByCategory;

  /// No description provided for @saleCount.
  ///
  /// In fr, this message translates to:
  /// **'Fréquence ventes'**
  String get saleCount;

  /// No description provided for @lastSale.
  ///
  /// In fr, this message translates to:
  /// **'Dernière vente'**
  String get lastSale;

  /// No description provided for @supplier.
  ///
  /// In fr, this message translates to:
  /// **'Fournisseur'**
  String get supplier;

  /// No description provided for @movementType.
  ///
  /// In fr, this message translates to:
  /// **'Type'**
  String get movementType;

  /// No description provided for @reportPresetYear.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get reportPresetYear;

  /// No description provided for @reportPresetCurrentMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois en cours'**
  String get reportPresetCurrentMonth;

  /// No description provided for @reportPresetLastMonth.
  ///
  /// In fr, this message translates to:
  /// **'Mois dernier'**
  String get reportPresetLastMonth;

  /// No description provided for @reportTabPeriods.
  ///
  /// In fr, this message translates to:
  /// **'Mensuel / Annuel'**
  String get reportTabPeriods;

  /// No description provided for @reportYearLabel.
  ///
  /// In fr, this message translates to:
  /// **'Année'**
  String get reportYearLabel;

  /// No description provided for @reportAnnualRevenue.
  ///
  /// In fr, this message translates to:
  /// **'Recettes annuelles'**
  String get reportAnnualRevenue;

  /// No description provided for @reportYoyChange.
  ///
  /// In fr, this message translates to:
  /// **'Évolution vs N-1'**
  String get reportYoyChange;

  /// No description provided for @reportMonthlyBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Évolution mensuelle'**
  String get reportMonthlyBreakdown;

  /// No description provided for @reportMonthlyTable.
  ///
  /// In fr, this message translates to:
  /// **'Tableau mensuel détaillé'**
  String get reportMonthlyTable;

  /// No description provided for @reportMonthColumn.
  ///
  /// In fr, this message translates to:
  /// **'Mois'**
  String get reportMonthColumn;

  /// No description provided for @reportPaymentBreakdown.
  ///
  /// In fr, this message translates to:
  /// **'Modes de paiement'**
  String get reportPaymentBreakdown;

  /// No description provided for @exportAnnualReport.
  ///
  /// In fr, this message translates to:
  /// **'Exporter rapport annuel (PDF)'**
  String get exportAnnualReport;

  /// No description provided for @permissionsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Droits du caissier'**
  String get permissionsTitle;

  /// No description provided for @permissionsSubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Cochez les actions autorisées pour ce gestionnaire.'**
  String get permissionsSubtitle;

  /// No description provided for @storeSettingsHint.
  ///
  /// In fr, this message translates to:
  /// **'Ces informations apparaissent sur les factures, tickets et rapports exportés.'**
  String get storeSettingsHint;

  /// No description provided for @storeSettingsSaved.
  ///
  /// In fr, this message translates to:
  /// **'Informations boutique enregistrées'**
  String get storeSettingsSaved;

  /// No description provided for @storeSettingsTechnical.
  ///
  /// In fr, this message translates to:
  /// **'Connexion & impression'**
  String get storeSettingsTechnical;

  /// No description provided for @storeCurrency.
  ///
  /// In fr, this message translates to:
  /// **'Devise (symbole)'**
  String get storeCurrency;

  /// No description provided for @storeCurrencyCode.
  ///
  /// In fr, this message translates to:
  /// **'Code devise (ex. XAF)'**
  String get storeCurrencyCode;

  /// No description provided for @storeSloganFr.
  ///
  /// In fr, this message translates to:
  /// **'Slogan (français)'**
  String get storeSloganFr;

  /// No description provided for @storeSloganAr.
  ///
  /// In fr, this message translates to:
  /// **'Slogan (arabe)'**
  String get storeSloganAr;

  /// No description provided for @storeLegalInfo.
  ///
  /// In fr, this message translates to:
  /// **'Informations légales'**
  String get storeLegalInfo;

  /// No description provided for @storeOpeningHours.
  ///
  /// In fr, this message translates to:
  /// **'Horaires d\'ouverture'**
  String get storeOpeningHours;

  /// No description provided for @reportPeriodCurrent.
  ///
  /// In fr, this message translates to:
  /// **'Période sélectionnée'**
  String get reportPeriodCurrent;

  /// No description provided for @reportPeriodPrevious.
  ///
  /// In fr, this message translates to:
  /// **'Période précédente'**
  String get reportPeriodPrevious;

  /// No description provided for @deleteUser.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer l\'utilisateur'**
  String get deleteUser;

  /// No description provided for @confirmDeleteUser.
  ///
  /// In fr, this message translates to:
  /// **'Supprimer définitivement {name} ? Cette action est irréversible.'**
  String confirmDeleteUser(String name);

  /// No description provided for @userDeleted.
  ///
  /// In fr, this message translates to:
  /// **'Utilisateur supprimé'**
  String get userDeleted;

  /// No description provided for @userDeleteHasSales.
  ///
  /// In fr, this message translates to:
  /// **'Impossible de supprimer : cet utilisateur a des ventes enregistrées. Désactivez-le plutôt.'**
  String get userDeleteHasSales;

  /// No description provided for @cannotDeleteSelf.
  ///
  /// In fr, this message translates to:
  /// **'Vous ne pouvez pas supprimer votre propre compte.'**
  String get cannotDeleteSelf;

  /// No description provided for @cannotDeleteManager.
  ///
  /// In fr, this message translates to:
  /// **'Un compte manager ne peut pas être supprimé.'**
  String get cannotDeleteManager;

  /// No description provided for @requestSaleReturn.
  ///
  /// In fr, this message translates to:
  /// **'Demander un retour'**
  String get requestSaleReturn;

  /// No description provided for @saleReturnReason.
  ///
  /// In fr, this message translates to:
  /// **'Motif du retour'**
  String get saleReturnReason;

  /// No description provided for @saleReturnReasonHint.
  ///
  /// In fr, this message translates to:
  /// **'Optionnel'**
  String get saleReturnReasonHint;

  /// No description provided for @saleReturnRequested.
  ///
  /// In fr, this message translates to:
  /// **'Demande de retour envoyée — en attente du manager'**
  String get saleReturnRequested;

  /// No description provided for @saleReturnPending.
  ///
  /// In fr, this message translates to:
  /// **'Retour en attente'**
  String get saleReturnPending;

  /// No description provided for @saleReturnPendingManager.
  ///
  /// In fr, this message translates to:
  /// **'Retour en attente de validation par le manager'**
  String get saleReturnPendingManager;

  /// No description provided for @saleReturnApproved.
  ///
  /// In fr, this message translates to:
  /// **'Retour validé — stock rétabli'**
  String get saleReturnApproved;

  /// No description provided for @saleReturnRejected.
  ///
  /// In fr, this message translates to:
  /// **'Demande de retour refusée'**
  String get saleReturnRejected;

  /// No description provided for @saleReturnFailed.
  ///
  /// In fr, this message translates to:
  /// **'Échec du retour'**
  String get saleReturnFailed;

  /// No description provided for @saleReturnNotReturnable.
  ///
  /// In fr, this message translates to:
  /// **'Cette vente ne peut pas faire l\'objet d\'un retour'**
  String get saleReturnNotReturnable;

  /// No description provided for @saleReturnAlreadyPending.
  ///
  /// In fr, this message translates to:
  /// **'Un retour est déjà en attente pour cette vente'**
  String get saleReturnAlreadyPending;

  /// No description provided for @saleReturnNotFound.
  ///
  /// In fr, this message translates to:
  /// **'Vente introuvable'**
  String get saleReturnNotFound;

  /// No description provided for @saleReturnNotPending.
  ///
  /// In fr, this message translates to:
  /// **'Cette demande n\'est plus en attente'**
  String get saleReturnNotPending;

  /// No description provided for @saleReturnNoReason.
  ///
  /// In fr, this message translates to:
  /// **'Aucun motif indiqué'**
  String get saleReturnNoReason;

  /// No description provided for @saleReturnMigrationRequired.
  ///
  /// In fr, this message translates to:
  /// **'Exécutez la migration : psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/008_sale_returns.sql'**
  String get saleReturnMigrationRequired;

  /// No description provided for @pendingReturnsTitle.
  ///
  /// In fr, this message translates to:
  /// **'{count} retour(s) à valider'**
  String pendingReturnsTitle(int count);

  /// No description provided for @viewReturnDetail.
  ///
  /// In fr, this message translates to:
  /// **'Voir le détail'**
  String get viewReturnDetail;

  /// No description provided for @pendingReturnDetailTitle.
  ///
  /// In fr, this message translates to:
  /// **'Détail de la demande de retour'**
  String get pendingReturnDetailTitle;

  /// No description provided for @returnDetailProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits de la vente'**
  String get returnDetailProducts;

  /// No description provided for @returnDetailNotReturned.
  ///
  /// In fr, this message translates to:
  /// **'Non concerné par le retour'**
  String get returnDetailNotReturned;

  /// No description provided for @saleReturnQtyLabel.
  ///
  /// In fr, this message translates to:
  /// **'Retour : {qty}'**
  String saleReturnQtyLabel(int qty);

  /// No description provided for @loyaltyStampDeductedOnReturn.
  ///
  /// In fr, this message translates to:
  /// **'1 validation fidélité sera retirée sur la carte client à la validation.'**
  String get loyaltyStampDeductedOnReturn;

  /// No description provided for @approveReturn.
  ///
  /// In fr, this message translates to:
  /// **'Valider le retour'**
  String get approveReturn;

  /// No description provided for @rejectReturn.
  ///
  /// In fr, this message translates to:
  /// **'Refuser'**
  String get rejectReturn;

  /// No description provided for @confirmApproveReturn.
  ///
  /// In fr, this message translates to:
  /// **'Confirmer le retour'**
  String get confirmApproveReturn;

  /// No description provided for @confirmApproveReturnBody.
  ///
  /// In fr, this message translates to:
  /// **'Le stock sera réintégré selon les quantités demandées. Confirmer ?'**
  String get confirmApproveReturnBody;

  /// No description provided for @saleReturnSelectProducts.
  ///
  /// In fr, this message translates to:
  /// **'Produits à retourner'**
  String get saleReturnSelectProducts;

  /// No description provided for @saleReturnSelectProductsHint.
  ///
  /// In fr, this message translates to:
  /// **'Cochez les produits et indiquez la quantité à retourner pour chaque ligne (obligatoire si quantité vendue > 1).'**
  String get saleReturnSelectProductsHint;

  /// No description provided for @saleReturnSoldQty.
  ///
  /// In fr, this message translates to:
  /// **'Vendu : {qty}'**
  String saleReturnSoldQty(int qty);

  /// No description provided for @saleReturnQtyToReturn.
  ///
  /// In fr, this message translates to:
  /// **'Quantité à retourner'**
  String get saleReturnQtyToReturn;

  /// No description provided for @saleReturnSelectAtLeastOne.
  ///
  /// In fr, this message translates to:
  /// **'Sélectionnez au moins un produit à retourner'**
  String get saleReturnSelectAtLeastOne;

  /// No description provided for @saleReturnInvalidQty.
  ///
  /// In fr, this message translates to:
  /// **'Quantité de retour invalide'**
  String get saleReturnInvalidQty;

  /// No description provided for @confirmRejectReturn.
  ///
  /// In fr, this message translates to:
  /// **'Refuser le retour'**
  String get confirmRejectReturn;

  /// No description provided for @confirmRejectReturnBody.
  ///
  /// In fr, this message translates to:
  /// **'La vente restera active. Le caissier pourra soumettre une nouvelle demande.'**
  String get confirmRejectReturnBody;

  /// No description provided for @saleReturnsHistory.
  ///
  /// In fr, this message translates to:
  /// **'Retours'**
  String get saleReturnsHistory;

  /// No description provided for @saleReturnsEmpty.
  ///
  /// In fr, this message translates to:
  /// **'Aucune demande de retour pour le moment'**
  String get saleReturnsEmpty;

  /// No description provided for @saleReturnFilterAll.
  ///
  /// In fr, this message translates to:
  /// **'Tous'**
  String get saleReturnFilterAll;

  /// No description provided for @saleReturnFilterPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get saleReturnFilterPending;

  /// No description provided for @saleReturnFilterApproved.
  ///
  /// In fr, this message translates to:
  /// **'Validés'**
  String get saleReturnFilterApproved;

  /// No description provided for @saleReturnFilterRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusés'**
  String get saleReturnFilterRejected;

  /// No description provided for @saleReturnRequestedBy.
  ///
  /// In fr, this message translates to:
  /// **'Demandé par'**
  String get saleReturnRequestedBy;

  /// No description provided for @saleReturnProcessedAt.
  ///
  /// In fr, this message translates to:
  /// **'Traité le'**
  String get saleReturnProcessedAt;

  /// No description provided for @dashboardReturnsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retours'**
  String get dashboardReturnsTitle;

  /// No description provided for @dashboardReturnsPending.
  ///
  /// In fr, this message translates to:
  /// **'En attente'**
  String get dashboardReturnsPending;

  /// No description provided for @dashboardReturnsApprovedMonth.
  ///
  /// In fr, this message translates to:
  /// **'Validés (mois)'**
  String get dashboardReturnsApprovedMonth;

  /// No description provided for @dashboardReturnsRejectedMonth.
  ///
  /// In fr, this message translates to:
  /// **'Refusés (mois)'**
  String get dashboardReturnsRejectedMonth;

  /// No description provided for @dashboardReturnsToday.
  ///
  /// In fr, this message translates to:
  /// **'Retours du jour'**
  String get dashboardReturnsToday;

  /// No description provided for @dashboardReturnsApprovedToday.
  ///
  /// In fr, this message translates to:
  /// **'Validés aujourd\'hui'**
  String get dashboardReturnsApprovedToday;

  /// No description provided for @dashboardReturnsRejectedToday.
  ///
  /// In fr, this message translates to:
  /// **'Refusés aujourd\'hui'**
  String get dashboardReturnsRejectedToday;

  /// No description provided for @dashboardDailySubtitle.
  ///
  /// In fr, this message translates to:
  /// **'Activité du jour — données réinitialisées chaque jour'**
  String get dashboardDailySubtitle;

  /// No description provided for @dashboardTodaySales.
  ///
  /// In fr, this message translates to:
  /// **'Ventes du jour'**
  String get dashboardTodaySales;

  /// No description provided for @reportReturnsTitle.
  ///
  /// In fr, this message translates to:
  /// **'Retours (période)'**
  String get reportReturnsTitle;

  /// No description provided for @reportReturnsRequested.
  ///
  /// In fr, this message translates to:
  /// **'Demandes'**
  String get reportReturnsRequested;

  /// No description provided for @reportReturnsApproved.
  ///
  /// In fr, this message translates to:
  /// **'Validés'**
  String get reportReturnsApproved;

  /// No description provided for @reportReturnsRejected.
  ///
  /// In fr, this message translates to:
  /// **'Refusés'**
  String get reportReturnsRejected;

  /// No description provided for @saleReturnForbidden.
  ///
  /// In fr, this message translates to:
  /// **'Seul l\'administrateur (compte manager) peut valider ou refuser un retour'**
  String get saleReturnForbidden;

  /// No description provided for @columnNumber.
  ///
  /// In fr, this message translates to:
  /// **'N°'**
  String get columnNumber;

  /// No description provided for @columnActions.
  ///
  /// In fr, this message translates to:
  /// **'Actions'**
  String get columnActions;

  /// No description provided for @tableProductsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} produit(s)'**
  String tableProductsCount(int count);

  /// No description provided for @tableClientsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} client(s)'**
  String tableClientsCount(int count);

  /// No description provided for @tableItemsCount.
  ///
  /// In fr, this message translates to:
  /// **'{count} élément(s)'**
  String tableItemsCount(int count);

  /// No description provided for @columnMinStock.
  ///
  /// In fr, this message translates to:
  /// **'Seuil min.'**
  String get columnMinStock;

  /// No description provided for @columnDaysLeft.
  ///
  /// In fr, this message translates to:
  /// **'Jours restants'**
  String get columnDaysLeft;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
