# Guide de déploiement — Souma Parfumerie

## État du projet (vérifications)

| Contrôle | Statut |
|----------|--------|
| `flutter analyze` | OK |
| `flutter test` | OK (après correction tests PDF) |
| `flutter build macos --release` | OK |
| API `.env` | À créer sur le serveur (jamais committer) |
| Migrations BDD | Script `scripts/migrate_db.sh` |

---

## 1. Poste boutique (Windows recommandé)

### Prérequis

- Windows 10/11 64 bits
- PostgreSQL 14+ installé en local, service démarré
- (Optionnel) MAMP / PHP pour sync cloud

### Base de données

```bash
# Mac / Linux (développement)
chmod +x scripts/*.sh
./scripts/install_db.sh

# Windows : exécuter avec psql dans le PATH
set DB_USER=postgres
set DB_PASSWORD=votre_mot_de_passe
psql -U %DB_USER% -c "CREATE DATABASE souma_parfumerie;"
psql -U %DB_USER% -d souma_parfumerie -f database\schema.sql
psql -U %DB_USER% -d souma_parfumerie -f database\seeds.sql
# Puis chaque fichier database\migrations\00x_*.sql dans l'ordre
```

**Ne pas** exécuter `009_seed_test_products.sql` en production (produits de démo uniquement).

### Build application

Sur la machine de build (avec Flutter SDK) :

```bash
./scripts/build_release.sh windows \
  --dart-define=SOUMA_DB_USER=postgres \
  --dart-define=SOUMA_DB_PASSWORD=VOTRE_MDP \
  --dart-define=SOUMA_API_URL=https://votre-domaine.fr/api/public \
  --dart-define=SOUMA_DEVICE_ID=boutique-ndjamena-01
```

Copier tout le dossier `app/build/windows/x64/runner/Release/` sur le PC caisse (raccourci vers `souma_parfumerie.exe`).

### Configuration sans recompiler

L’URL API peut aussi être changée dans l’app : **Administration → Paramètres**.

PostgreSQL : modifier `app/lib/core/config/app_config.dart` **avant** le build, ou utiliser les `--dart-define` ci-dessus.

---

## 2. API cloud (LWS / hébergement PHP)

1. Uploader le dossier `api/` ; la racine web doit pointer vers `api/public/`.
2. `composer install --no-dev` dans `api/`.
3. Copier `api/.env.example` → `api/.env` et renseigner :
   - `DB_*` (base LWS)
   - `JWT_SECRET` (32+ caractères aléatoires)
   - `APP_DEBUG=false` en production
4. Importer `database/schema.sql` + `seeds.sql` + migrations `002` à `008` sur la base distante.
5. Tester : `https://votre-domaine.fr/api/health`

---

## 3. macOS (développement / démo)

```bash
cd app
flutter build macos --release
open build/macos/Build/Products/Release/souma_parfumerie.app
```

PostgreSQL local : utilisateur par défaut = nom de session macOS (`hassanechogar` sur votre Mac). Sinon :

```bash
flutter run -d macos --dart-define=SOUMA_DB_USER=postgres
```

---

## 4. Sauvegardes

Cron ou tâche planifiée :

```bash
./scripts/backup_db.sh
```

Fichiers dans `backups/`.

---

## 5. Sécurité avant mise en production

- [ ] Changer les mots de passe par défaut (`Admin@2026`, etc.) dans l’app **Utilisateurs**
- [ ] `JWT_SECRET` et `APP_SECRET` uniques sur le serveur API
- [ ] `APP_DEBUG=false` sur l’API
- [ ] Ne pas committer `api/.env`
- [ ] Limiter l’accès PostgreSQL au localhost sur le poste caisse
- [ ] Supprimer les produits test (`barcode` LIKE `TEST-%`) si migration 009 a été appliquée par erreur

---

## 6. Dépannage rapide

| Symptôme | Action |
|----------|--------|
| Connexion PostgreSQL | `psql -U USER -d souma_parfumerie -c "SELECT 1"` |
| Table dépenses absente | `./scripts/migrate_db.sh` |
| Export PDF échoue | Redémarrer l’app ; fichiers dans `~/Documents/Souma Parfumerie/exports/` |
| Sync échoue | Vérifier URL API dans Paramètres + `curl .../api/health` |

---

© Expérience Tech — SOUMAPARFUMERIE
