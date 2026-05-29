// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Souma Parfumerie';

  @override
  String get appWindowTitle => 'Souma Perfumery Management System';

  @override
  String get storeName => 'Souma Parfumerie';

  @override
  String get projectFooter => 'Réalisé par Expérience Tech';

  @override
  String get projectFooterPrefix => 'Réalisé par';

  @override
  String get experienceTechLink => 'Expérience Tech';

  @override
  String get login => 'Connexion';

  @override
  String get username => 'Identifiant';

  @override
  String get password => 'Mot de passe';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signOut => 'Déconnexion';

  @override
  String get pos => 'Caisse';

  @override
  String get catalog => 'Produit';

  @override
  String get stock => 'Stock';

  @override
  String get reports => 'Rapports';

  @override
  String get settings => 'Paramètres';

  @override
  String get users => 'Utilisateurs';

  @override
  String get dashboard => 'Tableau de bord';

  @override
  String get scanBarcode => 'Scanner un code-barres';

  @override
  String get barcodeHint => 'Code-barres ou référence…';

  @override
  String get subtotal => 'Sous-total';

  @override
  String get discount => 'Remise';

  @override
  String get total => 'Total';

  @override
  String get cash => 'Espèces';

  @override
  String get card => 'Carte';

  @override
  String get mobile => 'Mobile';

  @override
  String get amountPaid => 'Montant reçu';

  @override
  String get change => 'Monnaie à rendre';

  @override
  String get validateSale => 'Valider la vente';

  @override
  String get clearCart => 'Vider le panier';

  @override
  String get stockAlert => 'Stock insuffisant';

  @override
  String get outOfStock => 'Rupture de stock';

  @override
  String get lowStock => 'Stock critique';

  @override
  String get sync => 'Synchronisation';

  @override
  String get syncNow => 'Synchroniser';

  @override
  String get lastSync => 'Dernière sync';

  @override
  String get online => 'En ligne';

  @override
  String get offline => 'Hors ligne';

  @override
  String get language => 'Langue';

  @override
  String get french => 'Français';

  @override
  String get arabic => 'العربية';

  @override
  String get dailySales => 'Ventes du jour';

  @override
  String get myDailySales => 'Mes ventes du jour';

  @override
  String get mySalesOnly => 'Affichage limité à vos ventes';

  @override
  String get transactions => 'Transactions';

  @override
  String get averageBasket => 'Panier moyen';

  @override
  String get topProducts => 'Top ventes';

  @override
  String topProductsShowMore(int count) {
    return 'Plus de détails ($count)';
  }

  @override
  String get exportPdf => 'Exporter PDF';

  @override
  String get exportExcel => 'Exporter Excel';

  @override
  String get products => 'Produits';

  @override
  String get categories => 'Catégories';

  @override
  String get price => 'Prix';

  @override
  String get quantity => 'Quantité';

  @override
  String get save => 'Enregistrer';

  @override
  String get cancel => 'Annuler';

  @override
  String get search => 'Rechercher';

  @override
  String get noData => 'Aucune donnée';

  @override
  String get errorGeneric => 'Une erreur est survenue';

  @override
  String get loginError => 'Identifiants incorrects';

  @override
  String get connectionError =>
      'Connexion à PostgreSQL impossible. Vérifiez que le serveur est démarré.';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get welcome => 'Bienvenue';

  @override
  String get managerOnly => 'Réservé au Manager';

  @override
  String get invoice => 'Facture';

  @override
  String get clientPhone => 'Téléphone client';

  @override
  String get clientPhoneSearchHint => 'Saisir pour rechercher en base…';

  @override
  String get backup => 'Sauvegarde';

  @override
  String get runBackup => 'Lancer une sauvegarde';

  @override
  String get backupDone => 'Sauvegarde créée';

  @override
  String get backupFailed => 'Échec de la sauvegarde';

  @override
  String get backupPgDumpMissing =>
      'pg_dump introuvable. Installez PostgreSQL (ex. brew install postgresql@14) ou ajoutez son dossier bin au PATH.';

  @override
  String get salesHistory => 'Historique ventes';

  @override
  String get clients => 'Clients';

  @override
  String get recentSales => 'Ventes récentes';

  @override
  String get dashboardManager => 'Tableau de bord administrateur';

  @override
  String get dashboardGestionnaire => 'Tableau de bord caisse';

  @override
  String get storeSettings => 'Informations boutique';

  @override
  String get storeNameFieldLabel => 'Nom de la boutique (paramètres)';

  @override
  String get storeAddress => 'Adresse';

  @override
  String get storePhone => 'Téléphone';

  @override
  String get storeEmail => 'Email';

  @override
  String get rememberCredentials =>
      'Mémoriser l\'identifiant et le mot de passe';

  @override
  String get menuBoutique => 'Produit';

  @override
  String get menuCommerce => 'Ventes & clients';

  @override
  String get menuAdministration => 'Administration';

  @override
  String get addProduct => 'Ajouter un produit';

  @override
  String get inStockProducts => 'Produits en stock';

  @override
  String get selectProductHint =>
      'Cliquez sur un produit pour l\'ajouter au panier';

  @override
  String get productNotFound => 'Aucun produit trouvé pour ce code-barres';

  @override
  String get productExpired =>
      'Ce produit est périmé et ne peut pas être vendu';

  @override
  String get posCatalogEmpty => 'Scannez ou recherchez un produit';

  @override
  String get brand => 'Marque';

  @override
  String get nameFr => 'Nom (français)';

  @override
  String get nameAr => 'Nom (arabe)';

  @override
  String get purchasePrice => 'Prix d\'achat';

  @override
  String get initialStock => 'Stock initial';

  @override
  String get category => 'Catégorie';

  @override
  String get barcode => 'Code-barres / référence';

  @override
  String get monthlyRevenue => 'Chiffre d\'affaires mensuel';

  @override
  String get cart => 'Panier';

  @override
  String get emptyCart => 'Panier vide — sélectionnez un produit ci-dessus';

  @override
  String get tapToAddProduct => 'Touchez un produit pour l\'ajouter au panier';

  @override
  String get minStockAlert => 'Seuil d\'alerte stock';

  @override
  String get minStockAlertHint =>
      'Alerte stock faible lorsque la quantité atteint ce niveau ou moins';

  @override
  String get paymentMethod => 'Mode de paiement';

  @override
  String get alerts => 'Alertes';

  @override
  String get lowStockTab => 'Stock faible';

  @override
  String get expiryTab => 'Expiration proche';

  @override
  String get noLowStock => 'Aucun produit en stock faible';

  @override
  String get noExpiryAlert => 'Aucun produit proche de l\'expiration';

  @override
  String get expiresOn => 'Expire le';

  @override
  String get expired => 'Expiré';

  @override
  String get expiryDate => 'Date d\'expiration';

  @override
  String get edit => 'Modifier';

  @override
  String get delete => 'Supprimer';

  @override
  String get editProduct => 'Modifier le produit';

  @override
  String get confirmDeleteProduct => 'Désactiver ce produit du catalogue ?';

  @override
  String get addClient => 'Ajouter un client';

  @override
  String get editClient => 'Modifier le client';

  @override
  String get clientName => 'Nom du client';

  @override
  String get loyaltyPoints => 'Validations fidélité';

  @override
  String get clientGiftsReceived => 'Cadeaux reçus';

  @override
  String loyaltyProgress(int current, int threshold) {
    return '$current/$threshold validations';
  }

  @override
  String get clientDetail => 'Fiche client';

  @override
  String get loyaltyCard => 'Carte de fidélité';

  @override
  String get loyaltyCardSubtitle => '10 achats = 1 cadeau';

  @override
  String get printLoyaltyCard => 'Imprimer la carte';

  @override
  String get printLoyaltyCardDone => 'Carte de fidélité exportée';

  @override
  String get userActive => 'Actif';

  @override
  String get userInactive => 'Inactif';

  @override
  String usersCount(int count) {
    return '$count utilisateur(s)';
  }

  @override
  String get loyaltyProgramTitle => 'Programme fidélité';

  @override
  String loyaltyUntilGift(int remaining) {
    return 'Encore $remaining validation(s) avant le cadeau';
  }

  @override
  String get giftEligible => 'Cadeau à offrir';

  @override
  String get loyaltyGiftReached =>
      'Ce client a atteint 10 ventes — cadeau à offrir !';

  @override
  String get giftOffered => 'Cadeau offert';

  @override
  String get giftOfferedConfirm =>
      'Confirmer que le cadeau a été offert au client ? La carte repartira à 0 validation.';

  @override
  String get giftOfferedDone => 'Cadeau enregistré — carte remise à zéro';

  @override
  String get redeemGift => 'Cadeau remis';

  @override
  String get redeemGiftConfirm =>
      'Confirmer que le cadeau a été remis au client ? La carte de fidélité sera remise à zéro.';

  @override
  String get redeemGiftDone => 'Cadeau enregistré';

  @override
  String get redeemGiftFailed => 'Impossible d\'enregistrer le cadeau';

  @override
  String get barcodeOptionalHint =>
      'Optionnel — généré automatiquement si vide';

  @override
  String get removeExpiredStock => 'Retirer du stock';

  @override
  String get removeExpiredStockConfirm =>
      'Mettre le stock à zéro pour ce produit expiré ?';

  @override
  String get removeExpiredStockDone => 'Stock expiré retiré';

  @override
  String get confirm => 'Confirmer';

  @override
  String get editExpense => 'Modifier la dépense';

  @override
  String get confirmDeleteExpense => 'Supprimer cette dépense ?';

  @override
  String get confirmDeleteClient => 'Supprimer définitivement ce client ?';

  @override
  String get addUser => 'Ajouter un utilisateur';

  @override
  String get editUser => 'Modifier l\'utilisateur';

  @override
  String get fullName => 'Nom complet';

  @override
  String get role => 'Rôle';

  @override
  String get roleGestionnaire => 'Gestionnaire (caisse)';

  @override
  String get roleManager => 'Manager (admin)';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get passwordMismatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordOptional => 'Laisser vide pour ne pas changer';

  @override
  String get reportsSubtitle =>
      'Indicateurs du jour, meilleures ventes et évolution mensuelle';

  @override
  String get exportReportsHint => 'Exporter le rapport du jour';

  @override
  String get dashboardSubtitle =>
      'Vue d\'ensemble et dernières ventes enregistrées';

  @override
  String get posSubtitle =>
      'Recherche produits, panier et validation des ventes';

  @override
  String get productsHubSubtitle =>
      'Catalogue, prix, stock et dates d\'expiration';

  @override
  String get alertsSubtitle =>
      'Produits en stock faible ou proches de l\'expiration';

  @override
  String get commerceHubSubtitle =>
      'Historique des ventes et gestion des clients';

  @override
  String get reprintReceipt => 'Réimprimer le ticket';

  @override
  String get exportInvoicePdf => 'Facture PDF';

  @override
  String get invoiceDetail => 'Détail de la facture';

  @override
  String get accountLocked =>
      'Compte temporairement verrouillé (trop de tentatives). Réessayez dans 15 minutes.';

  @override
  String get totpCode => 'Code d\'authentification (6 chiffres)';

  @override
  String get totpInvalid => 'Code incorrect';

  @override
  String get totpEnterCode =>
      'Saisissez le code affiché dans votre application Authenticator';

  @override
  String get twoFactorAuth => 'Authentification à deux facteurs (2FA)';

  @override
  String get enable2fa => 'Activer la 2FA';

  @override
  String get disable2fa => 'Désactiver la 2FA';

  @override
  String get disable2faConfirm =>
      'Désactiver la double authentification pour votre compte ?';

  @override
  String get totpSetupHint =>
      'Ajoutez ce secret dans Google Authenticator (ou équivalent) :';

  @override
  String get totpEnabledSuccess => '2FA activée avec succès';

  @override
  String get totpEnabledLabel => 'Activée — code requis à la connexion';

  @override
  String get totpDisabledLabel => 'Désactivée';

  @override
  String get totpFinishSetup => 'Terminer l\'activation 2FA';

  @override
  String get securitySettings => 'Sécurité';

  @override
  String get sessionTimeout => 'Déconnexion automatique (inactivité)';

  @override
  String get sessionTimeoutNever => 'Désactivée';

  @override
  String sessionTimeoutMinutes(int minutes) {
    return '$minutes minutes';
  }

  @override
  String get sessionExpired =>
      'Session expirée pour inactivité. Veuillez vous reconnecter.';

  @override
  String get suppliers => 'Fournisseurs';

  @override
  String get addSupplier => 'Ajouter un fournisseur';

  @override
  String get editSupplier => 'Modifier le fournisseur';

  @override
  String get supplierName => 'Nom du fournisseur';

  @override
  String get confirmDeleteSupplier => 'Désactiver ce fournisseur ?';

  @override
  String get adminHubSubtitle =>
      'Catégories, fournisseurs, utilisateurs et paramètres';

  @override
  String get close => 'Fermer';

  @override
  String get reprintSent => 'Ticket envoyé à l\'imprimante';

  @override
  String get noPrinterFound => 'Aucune imprimante détectée sur ce poste';

  @override
  String get dbMigrationRequired =>
      'Base de données à mettre à jour. Exécutez : psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/004_security_2fa.sql';

  @override
  String get printError => 'Erreur d\'impression';

  @override
  String get pdfExportReady => 'PDF enregistré';

  @override
  String get pdfExportFailed => 'Impossible de générer le PDF';

  @override
  String get reportDateRange => 'Période du rapport';

  @override
  String get reportPresetToday => 'Aujourd\'hui';

  @override
  String get reportPresetWeek => '7 jours';

  @override
  String get reportPresetMonth => '30 jours';

  @override
  String get reportCustomRange => 'Choisir les dates';

  @override
  String get periodRevenue => 'Chiffre d\'affaires (période)';

  @override
  String get revenueEvolution => 'Évolution du CA';

  @override
  String get validatingSale => 'Enregistrement…';

  @override
  String get saleTimeout =>
      'Délai dépassé — vérifiez que PostgreSQL est démarré.';

  @override
  String get addedToCart => 'Ajouté au panier';

  @override
  String get saleSuccess => 'Vente enregistrée';

  @override
  String get expenses => 'Dépenses';

  @override
  String get addExpense => 'Nouvelle dépense';

  @override
  String get expenseCategory => 'Type de dépense';

  @override
  String get expenseCategoryCashSend => 'Envoi d\'argent / personne';

  @override
  String get expenseCategoryPurchase => 'Achat';

  @override
  String get expenseCategoryExit => 'Sortie / frais';

  @override
  String get expenseCategorySupply => 'Approvisionnement';

  @override
  String get expenseCategoryOther => 'Autre';

  @override
  String get expenseAmount => 'Montant';

  @override
  String get expenseBeneficiary => 'Bénéficiaire / destinataire';

  @override
  String get expenseDescription => 'Description';

  @override
  String get expenseDate => 'Date';

  @override
  String get expensesMigrationRequired =>
      'Exécutez la migration : psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/005_expenses.sql';

  @override
  String get reportTabOverview => 'Synthèse';

  @override
  String get reportTabSales => 'Ventes';

  @override
  String get reportTabProducts => 'Produits';

  @override
  String get reportTabStock => 'Stock';

  @override
  String get reportObjectivesTitle => 'Objectifs du module rapports';

  @override
  String get reportObjectivesSubtitle => 'CDC — suivi, performance et décision';

  @override
  String get reportObjectives =>
      'Suivi précis des activités commerciales\nÉvaluation des performances de la boutique\nIdentification des produits rentables\nContrôle des mouvements de stock\nAmélioration des approvisionnements\nAide à la décision stratégique\nDocuments de suivi fiables et exploitables';

  @override
  String get reportDailyTitle => 'Rapport des ventes (période)';

  @override
  String get reportMonthlyHint =>
      'Analyse mensuelle — utilisez le filtre 30 jours ou dates personnalisées';

  @override
  String get reportAnnualHint => 'Évolution sur 12 mois (graphique ci-dessous)';

  @override
  String get estimatedProfit => 'Bénéfice estimé';

  @override
  String get totalDiscounts => 'Remises accordées';

  @override
  String get totalExpenses => 'Dépenses (période)';

  @override
  String get netEstimate => 'Résultat estimé (CA − dépenses)';

  @override
  String get paymentBreakdown => 'Modes de paiement';

  @override
  String get salesByCashier => 'Ventes par caissier';

  @override
  String get periodComparison => 'Comparaison période précédente';

  @override
  String get revenueChange => 'Évolution du CA';

  @override
  String get lowStockReport => 'Produits en rupture / stock critique';

  @override
  String get stockHistory => 'Historique des mouvements de stock';

  @override
  String get salesByCategory => 'Répartition par catégorie';

  @override
  String get saleCount => 'Fréquence ventes';

  @override
  String get lastSale => 'Dernière vente';

  @override
  String get supplier => 'Fournisseur';

  @override
  String get movementType => 'Type';

  @override
  String get reportPresetYear => 'Année';

  @override
  String get reportPresetCurrentMonth => 'Mois en cours';

  @override
  String get reportPresetLastMonth => 'Mois dernier';

  @override
  String get reportTabPeriods => 'Mensuel / Annuel';

  @override
  String get reportYearLabel => 'Année';

  @override
  String get reportAnnualRevenue => 'Recettes annuelles';

  @override
  String get reportYoyChange => 'Évolution vs N-1';

  @override
  String get reportMonthlyBreakdown => 'Évolution mensuelle';

  @override
  String get reportMonthlyTable => 'Tableau mensuel détaillé';

  @override
  String get reportMonthColumn => 'Mois';

  @override
  String get reportPaymentBreakdown => 'Modes de paiement';

  @override
  String get exportAnnualReport => 'Exporter rapport annuel (PDF)';

  @override
  String get permissionsTitle => 'Droits du caissier';

  @override
  String get permissionsSubtitle =>
      'Cochez les actions autorisées pour ce gestionnaire.';

  @override
  String get storeSettingsHint =>
      'Ces informations apparaissent sur les factures, tickets et rapports exportés.';

  @override
  String get storeSettingsSaved => 'Informations boutique enregistrées';

  @override
  String get storeSettingsTechnical => 'Connexion & impression';

  @override
  String get storeCurrency => 'Devise (symbole)';

  @override
  String get storeCurrencyCode => 'Code devise (ex. XAF)';

  @override
  String get storeSloganFr => 'Slogan (français)';

  @override
  String get storeSloganAr => 'Slogan (arabe)';

  @override
  String get storeLegalInfo => 'Informations légales';

  @override
  String get storeOpeningHours => 'Horaires d\'ouverture';

  @override
  String get reportPeriodCurrent => 'Période sélectionnée';

  @override
  String get reportPeriodPrevious => 'Période précédente';

  @override
  String get deleteUser => 'Supprimer l\'utilisateur';

  @override
  String confirmDeleteUser(String name) {
    return 'Supprimer définitivement $name ? Cette action est irréversible.';
  }

  @override
  String get userDeleted => 'Utilisateur supprimé';

  @override
  String get userDeleteHasSales =>
      'Impossible de supprimer : cet utilisateur a des ventes enregistrées. Désactivez-le plutôt.';

  @override
  String get cannotDeleteSelf =>
      'Vous ne pouvez pas supprimer votre propre compte.';

  @override
  String get cannotDeleteManager =>
      'Un compte manager ne peut pas être supprimé.';

  @override
  String get requestSaleReturn => 'Demander un retour';

  @override
  String get saleReturnReason => 'Motif du retour';

  @override
  String get saleReturnReasonHint => 'Optionnel';

  @override
  String get saleReturnRequested =>
      'Demande de retour envoyée — en attente du manager';

  @override
  String get saleReturnPending => 'Retour en attente';

  @override
  String get saleReturnPendingManager =>
      'Retour en attente de validation par le manager';

  @override
  String get saleReturnApproved => 'Retour validé — stock rétabli';

  @override
  String get saleReturnRejected => 'Demande de retour refusée';

  @override
  String get saleReturnFailed => 'Échec du retour';

  @override
  String get saleReturnNotReturnable =>
      'Cette vente ne peut pas faire l\'objet d\'un retour';

  @override
  String get saleReturnAlreadyPending =>
      'Un retour est déjà en attente pour cette vente';

  @override
  String get saleReturnNotFound => 'Vente introuvable';

  @override
  String get saleReturnNotPending => 'Cette demande n\'est plus en attente';

  @override
  String get saleReturnNoReason => 'Aucun motif indiqué';

  @override
  String get saleReturnMigrationRequired =>
      'Exécutez la migration : psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/008_sale_returns.sql';

  @override
  String pendingReturnsTitle(int count) {
    return '$count retour(s) à valider';
  }

  @override
  String get viewReturnDetail => 'Voir le détail';

  @override
  String get pendingReturnDetailTitle => 'Détail de la demande de retour';

  @override
  String get returnDetailProducts => 'Produits de la vente';

  @override
  String get returnDetailNotReturned => 'Non concerné par le retour';

  @override
  String saleReturnQtyLabel(int qty) {
    return 'Retour : $qty';
  }

  @override
  String get loyaltyStampDeductedOnReturn =>
      '1 validation fidélité sera retirée sur la carte client à la validation.';

  @override
  String get approveReturn => 'Valider le retour';

  @override
  String get rejectReturn => 'Refuser';

  @override
  String get confirmApproveReturn => 'Confirmer le retour';

  @override
  String get confirmApproveReturnBody =>
      'Le stock sera réintégré selon les quantités demandées. Confirmer ?';

  @override
  String get saleReturnSelectProducts => 'Produits à retourner';

  @override
  String get saleReturnSelectProductsHint =>
      'Cochez les produits et indiquez la quantité à retourner pour chaque ligne (obligatoire si quantité vendue > 1).';

  @override
  String saleReturnSoldQty(int qty) {
    return 'Vendu : $qty';
  }

  @override
  String get saleReturnQtyToReturn => 'Quantité à retourner';

  @override
  String get saleReturnSelectAtLeastOne =>
      'Sélectionnez au moins un produit à retourner';

  @override
  String get saleReturnInvalidQty => 'Quantité de retour invalide';

  @override
  String get confirmRejectReturn => 'Refuser le retour';

  @override
  String get confirmRejectReturnBody =>
      'La vente restera active. Le caissier pourra soumettre une nouvelle demande.';

  @override
  String get saleReturnsHistory => 'Retours';

  @override
  String get saleReturnsEmpty => 'Aucune demande de retour pour le moment';

  @override
  String get saleReturnFilterAll => 'Tous';

  @override
  String get saleReturnFilterPending => 'En attente';

  @override
  String get saleReturnFilterApproved => 'Validés';

  @override
  String get saleReturnFilterRejected => 'Refusés';

  @override
  String get saleReturnRequestedBy => 'Demandé par';

  @override
  String get saleReturnProcessedAt => 'Traité le';

  @override
  String get dashboardReturnsTitle => 'Retours';

  @override
  String get dashboardReturnsPending => 'En attente';

  @override
  String get dashboardReturnsApprovedMonth => 'Validés (mois)';

  @override
  String get dashboardReturnsRejectedMonth => 'Refusés (mois)';

  @override
  String get dashboardReturnsToday => 'Retours du jour';

  @override
  String get dashboardReturnsApprovedToday => 'Validés aujourd\'hui';

  @override
  String get dashboardReturnsRejectedToday => 'Refusés aujourd\'hui';

  @override
  String get dashboardDailySubtitle =>
      'Activité du jour — données réinitialisées chaque jour';

  @override
  String get dashboardTodaySales => 'Ventes du jour';

  @override
  String get reportReturnsTitle => 'Retours (période)';

  @override
  String get reportReturnsRequested => 'Demandes';

  @override
  String get reportReturnsApproved => 'Validés';

  @override
  String get reportReturnsRejected => 'Refusés';

  @override
  String get saleReturnForbidden =>
      'Seul l\'administrateur (compte manager) peut valider ou refuser un retour';

  @override
  String get columnNumber => 'N°';

  @override
  String get columnActions => 'Actions';

  @override
  String tableProductsCount(int count) {
    return '$count produit(s)';
  }

  @override
  String tableClientsCount(int count) {
    return '$count client(s)';
  }

  @override
  String tableItemsCount(int count) {
    return '$count élément(s)';
  }

  @override
  String get columnMinStock => 'Seuil min.';

  @override
  String get columnDaysLeft => 'Jours restants';
}
