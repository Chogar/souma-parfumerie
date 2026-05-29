# Conformité CDC SOUMAPARFUMERIE

État d'avancement par rapport au cahier des charges complet.

## Implémenté (v1.2)

| Module | Statut |
|--------|--------|
| Auth BCrypt, rôles Gestionnaire / Manager | OK |
| Tableau de bord / KPI caisse | OK |
| Caisse : scan, panier, paiement, monnaie, reçu | OK |
| Catalogue produits, prix (Manager) | OK |
| Stock : alertes, mouvements, expiration | OK |
| Historique ventes (permissions, scope caissier) | OK |
| Retours vente (demande caissier, validation manager) | OK |
| Clients + fidélité (10 ventes = cadeau) | OK |
| Catégories, fournisseurs (Manager) | OK |
| Utilisateurs (Manager) : CRUD, suppression caissier | OK |
| Dépenses (Manager) | OK |
| Rapports : KPI, top ventes, graphiques, PDF/Excel | OK |
| Rapports mensuels / annuels détaillés + export PDF annuel | OK |
| Permissions granulaires caissier (UI cases à cocher) | OK |
| Paramètres boutique (factures, tickets) | OK |
| Restrictions Gestionnaire (ventes propres, pas CA global) | OK |
| Multilingue FR/AR + RTL | OK |
| Sync cloud, API REST | OK |
| Sauvegarde PostgreSQL (script) | OK |
| PostgreSQL offline, UUID, audit | OK |

## En cours / prochaines phases

| Module CDC | Priorité |
|------------|----------|
| Restauration sauvegarde depuis l'UI | P2 |
| Images produits | P3 |
| Formation / doc utilisateur (livrable §13) | P3 |

## Migrations base

Exécuter dans l'ordre si la base existe déjà :

```bash
psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/002_cdc_extensions.sql
psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/003_product_expiry.sql
psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/004_security_2fa.sql
psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/005_expenses.sql
psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/006_store_settings.sql
psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/007_client_loyalty.sql
psql -U VOTRE_USER -d souma_parfumerie -f database/migrations/008_sale_returns.sql
```

Installation neuve : `./scripts/install_db.sh` inclut le schéma de base ; appliquer ensuite les migrations manquantes si besoin.
