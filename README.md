# SOUMAPARFUMERIE

Application professionnelle de gestion de boutique (Offline-First) — **Expérience Tech**.

## Structure du projet

```
Souma Parfumerie/
├── app/                 # Flutter Desktop (Windows / macOS / Linux)
├── api/                 # API REST PHP (sync cloud LWS)
├── database/            # Schéma PostgreSQL + seeds
├── scripts/             # Installation BDD, sauvegardes
└── backups/             # Dumps PostgreSQL (générés)
```

## Prérequis

- **Flutter** 3.41+ avec support desktop
- **PostgreSQL** 14+ (local sur le poste boutique)
- **PHP** 8.1+ et **Composer** (API + MAMP)
- **Windows** pour déploiement production caisse

## 1. Base de données locale

```bash
chmod +x scripts/*.sh
./scripts/install_db.sh
```

Comptes par défaut :

| Utilisateur | Rôle         | Mot de passe |
|-------------|--------------|--------------|
| `admin`     | Manager      | `Admin@2026` |
| `caisse`    | Gestionnaire | `Admin@2026` |

Adapter `app/lib/core/config/app_config.dart` (hôte, port, utilisateur PostgreSQL).

## 2. API REST (MAMP / LWS)

```bash
cd api
composer install
cp .env.example .env   # si besoin
```

URL locale MAMP (exemple) :

`http://localhost:8888/Souma%20Parfumerie/api/public/api/health`

Tester :

```bash
curl http://localhost:8888/Souma%20Parfumerie/api/public/api/health
```

Connexion :

```bash
curl -X POST http://localhost:8888/Souma%20Parfumerie/api/public/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin@2026"}'
```

## 3. Application Flutter

```bash
cd app
flutter pub get
flutter gen-l10n
flutter run -d windows   # ou macos / linux en dev
```

Build Windows production :

```bash
flutter build windows --release
```

## Fonctionnalités livrées (v1.0)

- Authentification locale (BCrypt) — Gestionnaire / Manager
- Caisse : scan code-barres, panier, remises (Manager), paiement, monnaie
- Catalogue produits (lecture + modification prix Manager)
- Stock : alertes rupture, journal mouvements
- Rapports : KPI journalier, top ventes, graphique, export PDF / Excel
- Multilingue FR / AR avec **RTL** automatique
- Sync cloud : push ventes/mouvements, pull catalogue (HTTPS + JWT)
- Audit logs, champs `id` UUID, `updated_at`, `is_synced`

## Synchronisation (règles CDC)

| Données              | Priorité   |
|----------------------|------------|
| Ventes / factures    | **Local**  |
| Catalogue / tarifs   | **Cloud**  |
| Stocks               | Mouvements ±X |

## Sauvegarde quotidienne

```bash
./scripts/backup_db.sh
```

Sur Windows, planifier `pg_dump` via le Planificateur de tâches à la fermeture de l’application.

## Déploiement LWS

1. Uploader `api/` sur l’hébergement (document root → `public/`)
2. Créer la base PostgreSQL côté LWS et importer `database/schema.sql` + `seeds.sql`
3. Configurer `api/.env` (secrets JWT, BDD)
4. Dans l’app : **Paramètres** → URL API + token après login cloud

---

© Expérience Tech — SOUMAPARFUMERIE
