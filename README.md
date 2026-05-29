# SOUMAPARFUMERIE

Application professionnelle de gestion de boutique (offline-first) — **Expérience Tech**.

## Structure du projet

```
Souma Parfumerie/
├── app/                 # Flutter Desktop (Windows / macOS / Linux) — caisse boutique
├── api/                 # API REST PHP (sync LWS + portail Manager local)
├── api/public/manager/  # Portail web Manager (téléphone / PC, Tailscale)
├── database/            # Schéma PostgreSQL + seeds + migrations
├── scripts/             # Installation BDD, API Manager, sauvegardes
├── docs/                # Guides (CDC, déploiement, accès distant)
└── backups/             # Dumps PostgreSQL (générés)
```

## Prérequis

- **Flutter** 3.16+ avec support desktop (`flutter doctor`)
- **PostgreSQL** 14+ (local sur le poste boutique)
- **PHP** 8.1+ et **Composer** (API — MAMP, Homebrew ou binaire système)
- **Windows** ou **macOS** pour la caisse en production

## 1. Base de données locale

```bash
chmod +x scripts/*.sh
./scripts/install_db.sh
```

Migrations :

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

Connexion PostgreSQL : `app/lib/core/config/app_config.dart` ou variables `--dart-define` au build — voir [docs/DEPLOIEMENT.md](docs/DEPLOIEMENT.md).

Sur **macOS**, l’API Manager utilise souvent l’utilisateur système dans `api/.env` (`DB_USER=hassanechogar`, mot de passe vide) — voir `api/.env.example`.

## 2. API REST

```bash
cd api
composer install
cp .env.example .env   # éditer DB_* et JWT_SECRET
```

Documentation des routes : [api/README.md](api/README.md).

**MAMP (exemple)** — document root vers `api/public/` :

`http://localhost:8888/Souma%20Parfumerie/api/public/api/health`

**Serveur PHP intégré (tests / portail Manager)** :

```bash
cd api
php -S localhost:8080 -t public
curl "http://localhost:8080/api/health"
```

## 3. Application desktop (Flutter)

```bash
cd app
flutter pub get
flutter gen-l10n
flutter analyze
flutter test
flutter run -d macos      # développement Mac
flutter run -d windows    # production Windows
```

Logo : `app/assets/branding/logo.jpg` (référencé dans `pubspec.yaml`).

Build production :

```bash
chmod +x scripts/build_release.sh
./scripts/build_release.sh windows   # ou macos / linux
```

Guide : [docs/DEPLOIEMENT.md](docs/DEPLOIEMENT.md).

### Fonctionnalités — application desktop

| Module | Description |
|--------|-------------|
| **Caisse** | Recherche produits, panier, paiement, client, impression ticket |
| **Catalogue** | Produits (CRUD Manager), catégories, codes-barres, stock, expiration |
| **Alertes** | Stock faible, péremption |
| **Ventes** | Historique, détail facture, demandes de retour |
| **Retours** | Validation / refus (Manager), historique avec filtres |
| **Clients** | CRUD, carte fidélité, cadeau |
| **Dépenses** | Saisie et suivi |
| **Rapports** | KPI, graphiques, export PDF et Excel (Manager) |
| **Administration** | Fournisseurs, utilisateurs, permissions gestionnaire, paramètres boutique, 2FA |
| **Sync cloud** | Push ventes / pull catalogue via API JWT (option LWS) |
| **i18n** | Français / Arabe avec RTL |

> La caisse complète, l’impression, la 2FA et les exports Excel sont **réservés à l’app desktop**. Le portail web couvre la supervision et une caisse simplifiée (voir ci-dessous).

## 4. Portail Manager web (`/manager/`)

Portail **responsive** pour le rôle **Manager** : même base PostgreSQL que la caisse, **sans LWS obligatoire**. Accès distant recommandé via **Tailscale**.

```bash
./scripts/start_manager_api.sh
# Local : http://127.0.0.1:8080/manager/
# Distant (ex.) : http://100.x.x.x:8080/manager/  (IP Tailscale du Mac caisse)
```

**Démarrage automatique au login Mac :**

```bash
./scripts/install_manager_api_startup_mac.sh
```

**Windows :** `.\scripts\install_manager_api_startup.ps1`

Guide détaillé : [docs/ACCES_MANAGER_DISTANT.md](docs/ACCES_MANAGER_DISTANT.md).

### Fonctionnalités — portail Manager

| Module | Description |
|--------|-------------|
| **Caisse** | Vente simplifiée : recherche, panier, paiement, téléphone client |
| **Produits** | Liste, ajout / modification (formulaire modal) |
| **Catégories** | Liste, ajout / modification |
| **Alertes** | Stock faible, produits proches de la péremption |
| **Ventes** | Historique par période, détail facture |
| **Retour** | Filtres : Tous, En attente, Validés, Annulés — approbation / refus |
| **Clients** | Recherche, fiche, fidélité, offre cadeau |
| **Dépenses** | Liste, saisie |
| **Rapports** | Synthèse période / annuel, graphiques Chart.js, export PDF |
| **Fournisseurs** | CRUD |
| **Utilisateurs** | CRUD (Manager / Gestionnaire) |
| **Paramètres** | Informations boutique |

### Interface portail

- Menu latéral par sections (Boutique, Ventes & clients, Finance, Administration)
- **FR / AR** avec RTL
- Connexion : mémorisation de l’identifiant, affichage du mot de passe
- **Mobile** : menu coulissant ☰, défilement des entrées, langue et déconnexion en bas du menu
- **PC** : menu fixe à gauche ; langue et déconnexion dans l’en-tête
- Badges sur **Alertes** et **Retours en attente**
- Au rechargement de la page (session active), ouverture automatique sur **Caisse**

### Non disponible sur le portail web

- Tableau de bord (retiré du menu)
- Impression tickets / factures
- Export Excel des rapports
- Configuration 2FA et permissions granulaires gestionnaire
- Caisse aussi complète que l’app desktop (pas de scan code-barres dédié, etc.)

## Synchronisation cloud (optionnelle — app desktop)

| Données              | Priorité   |
|----------------------|------------|
| Ventes / factures    | **Local**  |
| Catalogue / tarifs   | **Cloud**  |
| Stocks               | Mouvements ±X |

Configurer l’URL API dans l’app : **Paramètres** → URL API. Voir [docs/DEPLOIEMENT.md](docs/DEPLOIEMENT.md) pour LWS.

## Sauvegarde

```bash
./scripts/backup_db.sh
```

## Dépannage

| Problème | Piste |
|----------|--------|
| Connexion PostgreSQL | PostgreSQL démarré ; `psql -U USER -d souma_parfumerie -c "SELECT 1"` |
| API : `role "postgres" does not exist` (Mac) | Dans `api/.env`, utiliser l’utilisateur macOS (`whoami`) et mot de passe vide |
| Port 8080 déjà utilisé | L’API Manager tourne déjà (LaunchAgent) — normal |
| Portail : écran vide après refresh | Recharger avec cache vidé (Cmd+Shift+R) ; vérifier session Manager |
| API 404 / connexion refusée | MAMP démarré ou `php -S localhost:8080 -t api/public` |
| Logo absent | `cp Logo.jpg app/assets/branding/logo.jpg` puis redémarrer l’app |
| Analyse IDE | Ouvrir la racine du repo ; `cd app && flutter analyze` |

## Documentation

- [Accès Manager distant (Tailscale)](docs/ACCES_MANAGER_DISTANT.md)
- [Conformité CDC](docs/CDC_CONFORMITE.md)
- [Déploiement](docs/DEPLOIEMENT.md)
- [API REST](api/README.md)
- [Application Flutter](app/README.md)

## Déploiement LWS (sync cloud optionnelle)

1. Uploader `api/` (document root → `public/`)
2. Créer la base PostgreSQL LWS, importer `database/schema.sql` + `seeds.sql`
3. Configurer `api/.env`
4. Dans l’app desktop : **Paramètres** → URL API

---

© Expérience Tech — SOUMAPARFUMERIE
