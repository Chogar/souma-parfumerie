# SOUMAPARFUMERIE

Application professionnelle de gestion de boutique (offline-first) — **Expérience Tech**.

## Structure du projet

```
Souma Parfumerie/
├── app/                 # Flutter Desktop (Windows / macOS / Linux)
├── api/                 # API REST PHP (sync cloud LWS / MAMP)
├── database/            # Schéma PostgreSQL + seeds + migrations
├── scripts/             # Installation BDD, sauvegardes
├── docs/                # Conformité CDC ([CDC_CONFORMITE.md](docs/CDC_CONFORMITE.md))
└── backups/             # Dumps PostgreSQL (générés)
```

## Prérequis

- **Flutter** 3.16+ avec support desktop (`flutter doctor`)
- **PostgreSQL** 14+ (local sur le poste boutique)
- **PHP** 8.1+ et **Composer** (API — MAMP ou LWS)
- **Windows** recommandé pour la caisse en production

## 1. Base de données locale

```bash
chmod +x scripts/*.sh
./scripts/install_db.sh
```

Migrations (installation neuve : incluses dans `install_db.sh`) :

```bash
./scripts/migrate_db.sh
# Données de démo uniquement :
INCLUDE_TEST_SEED=1 ./scripts/migrate_db.sh
```

Comptes par défaut :

| Utilisateur | Rôle         | Mot de passe   |
|-------------|--------------|----------------|
| `Chogar`    | Manager      | `Hassouni1`    |
| `admin`     | Manager      | `Admin@2026`   |
| `caisse`    | Gestionnaire | `Admin@2026`   |

PostgreSQL / API : `app/lib/core/config/app_config.dart` ou variables `--dart-define` au build (voir [docs/DEPLOIEMENT.md](docs/DEPLOIEMENT.md)).

## 2. API REST (MAMP / LWS)

```bash
cd api
composer install
cp .env.example .env   # puis éditer DB_* et JWT_SECRET
```

Voir [api/README.md](api/README.md) pour les routes et exemples `curl`.

URL locale MAMP (exemple) :

`http://localhost:8888/Souma%20Parfumerie/api/public/api/health`

> **Important :** démarrer les serveurs MAMP avant le `curl`. Si le port 8888 ne répond pas, vérifier dans MAMP → Préférences → Ports (souvent **8888** ou **80**).

**Sans MAMP** (serveur PHP intégré, pour tests rapides) :

```bash
cd api
php -S localhost:8080 -t public
curl "http://localhost:8080/api/health"
```

Dans ce cas, mettre `defaultApiBaseUrl` à `http://localhost:8080` dans `app_config.dart`.

## 3. Application Flutter

```bash
cd app
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run -d macos      # développement Mac
flutter run -d windows    # développement / production Windows
```

Logo : placer `Logo.jpg` à la racine puis copier vers `app/assets/branding/logo.jpg` (déjà référencé dans `pubspec.yaml`).

Build production :

```bash
chmod +x scripts/build_release.sh
./scripts/build_release.sh windows   # ou macos / linux
```

Guide complet : [docs/DEPLOIEMENT.md](docs/DEPLOIEMENT.md).

## Fonctionnalités (application)

| Module | Description |
|--------|-------------|
| **Caisse** | Recherche produits, panier, validation vente, téléphone client |
| **Produit** | CRUD catalogue (Manager), seuil alerte stock, date expiration |
| **Alertes** | Stock faible + produits proches expiration |
| **Ventes & clients** | Historique ventes, retours (validation manager), CRUD clients, fidélité |
| **Rapports** | KPI, top ventes, export PDF/Excel (Manager) |
| **Administration** | Catégories, utilisateurs (suppression caissier), fournisseurs, paramètres |
| **Sync** | Push ventes / pull catalogue via API JWT |
| **i18n** | Français / Arabe avec RTL |

## Synchronisation (règles CDC)

| Données              | Priorité   |
|----------------------|------------|
| Ventes / factures    | **Local**  |
| Catalogue / tarifs   | **Cloud**  |
| Stocks               | Mouvements ±X |

## Sauvegarde

```bash
./scripts/backup_db.sh
```

## Dépannage

| Problème | Piste |
|----------|--------|
| Connexion PostgreSQL | Vérifier que PostgreSQL tourne : `psql -U USER -d souma_parfumerie -c "SELECT 1"` |
| API 404 / connexion refusée | Démarrer MAMP ; vérifier le port ; ou utiliser `php -S localhost:8080 -t api/public` |
| Vente lente | Vérifier PostgreSQL local ; impression désactivée par défaut |
| Logo absent | `cp Logo.jpg app/assets/branding/logo.jpg` puis hot restart |
| Dossiers `app` / `api` en rouge dans l’IDE | Ouvrir la racine **Souma Parfumerie** (pas seulement `app/`). Fichier `.vscode/settings.json` : analyse Dart dans `app/`, PHP sans `vendor/`. Puis `cd app && flutter analyze` (doit afficher « No issues found »). |

## Documentation

- [Conformité CDC](docs/CDC_CONFORMITE.md)
- [API REST](api/README.md)
- [Application Flutter](app/README.md)

## Déploiement LWS

1. Uploader `api/` (document root → `public/`)
2. Créer la base PostgreSQL LWS, importer `database/schema.sql` + `seeds.sql`
3. Configurer `api/.env`
4. Dans l’app : **Paramètres** → URL API

---

© Expérience Tech — SOUMAPARFUMERIE
