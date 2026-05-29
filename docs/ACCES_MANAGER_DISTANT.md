# Accès Manager à distance — sans LWS

Le **portail Manager** permet au responsable de consulter la boutique **depuis son téléphone ou son ordinateur**, sans hébergement cloud (LWS). Tout tourne **localement sur le PC caisse**.

## Fonctionnalités (parité avec l'app desktop)

| Module | Description |
|--------|-------------|
| **Caisse (POS)** | Vente simplifiée (recherche produit, panier, paiement) |
| **Produits** | Liste, création / modification |
| **Catégories** | Liste, création / modification |
| **Alertes** | Stock faible, péremption |
| **Ventes** | Historique filtrable, détail facture |
| **Retour** | Tous / en attente / validés / annulés — validation depuis « En attente » |
| **Clients** | Liste, fiche, fidélité, cadeau |
| **Dépenses** | Liste, ajout |
| **Rapports** | Graphiques Chart.js, export PDF |
| **Fournisseurs** | CRUD |
| **Utilisateurs** | CRUD (manager / gestionnaire) |
| **Paramètres** | Infos boutique |

Interface **FR / AR**, menu latéral, badges alertes / retours. Accès : `http://<IP-Tailscale>:8080/manager/`

Accès réservé au rôle **Manager** (compte `admin` ou `Chogar` par défaut).

---

## 1. Prérequis sur le PC boutique

- PostgreSQL démarré (base `souma_parfumerie`)
- PHP 8.1+ et Composer
- Fichier `api/.env` configuré (même base que l'app desktop)

```bash
cd api
composer install
cp .env.example .env
# Éditer DB_HOST=127.0.0.1, DB_USER, DB_PASS, JWT_SECRET
```

---

## 2. Démarrer l'API locale

```bash
chmod +x scripts/start_manager_api.sh
./scripts/start_manager_api.sh
```

Par défaut : port **8080**.

- Portail Manager : `http://127.0.0.1:8080/manager/`
- API santé : `http://127.0.0.1:8080/api/health`

### Démarrage automatique au boot (macOS — MacBook caisse)

Sur un **MacBook boutique**, un **LaunchAgent** lance l'API **à chaque connexion** de l'utilisateur (sans terminal ouvert).

**Prérequis :**
- PostgreSQL démarré (Postgres.app, Homebrew ou MAMP)
- PHP 8.1+ (`brew install php` ou PHP MAMP)
- `api/.env` configuré
- `composer install` exécuté une fois dans `api/`

```bash
cd "/Applications/MAMP/htdocs/Souma Parfumerie"
chmod +x scripts/*.sh
./scripts/install_manager_api_startup_mac.sh
```

| Script | Rôle |
|--------|------|
| `install_manager_api_startup_mac.sh` | Installe le LaunchAgent (login auto) |
| `uninstall_manager_api_startup_mac.sh` | Supprime le démarrage auto |
| `start_manager_api.sh` | Démarrage manuel (terminal visible) |
| `start_manager_api_daemon.sh` | Démarrage arrière-plan (utilisé par LaunchAgent) |
| `stop_manager_api.sh` | Arrête l'API sur le port 8080 |

**Logs :** `logs/manager_api.log`

**Test :**
```bash
curl http://127.0.0.1:8080/api/health
open http://127.0.0.1:8080/manager/
```

**Si PHP MAMP n'est pas détecté :**
```bash
export SOUMA_PHP_BIN="/Applications/MAMP/bin/php/php8.3.1/bin/php"
./scripts/install_manager_api_startup_mac.sh
```

**Désinstallation :**
```bash
./scripts/uninstall_manager_api_startup_mac.sh
```

> Au premier login après installation, macOS peut demander d'autoriser le réseau entrant pour `php` — cliquez **Autoriser**.

### Démarrage automatique au boot (Windows)

Sur le **PC caisse Windows**, une tâche planifiée lance l'API **1 minute après la connexion** (sans fenêtre console).

**Prérequis :** PHP 8.1+ dans le PATH, `api\.env` configuré, `composer install` déjà exécuté une fois.

```powershell
# PowerShell (dossier du projet)
cd "C:\Chemin\Vers\Souma Parfumerie"
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
.\scripts\install_manager_api_startup.ps1
```

| Script | Rôle |
|--------|------|
| `install_manager_api_startup.ps1` | Installe la tâche `SoumaParfumerie-ManagerAPI` |
| `uninstall_manager_api_startup.ps1` | Supprime le démarrage automatique |
| `start_manager_api.bat` | Démarrage manuel (avec console) |
| `start_manager_api_hidden.vbs` | Démarrage sans fenêtre |
| `stop_manager_api.bat` | Arrête le serveur sur le port 8080 |

**Logs :** `logs\manager_api.log`

**Test sans redémarrer le PC :**
```powershell
wscript.exe "scripts\start_manager_api_hidden.vbs"
curl http://127.0.0.1:8080/api/health
```

**Désinstallation :**
```powershell
.\scripts\uninstall_manager_api_startup.ps1
```

> La tâche planifiée Windows se déclenche au **login** de l'utilisateur caisse.

### Pare-feu macOS

Si le Manager ne peut pas accéder depuis Tailscale : **Réglages Système → Réseau → Pare-feu → Options** → autoriser les connexions entrantes pour `php`.

---

**Tailscale** crée un réseau privé chiffré entre appareils, sans ouvrir PostgreSQL ni l'API sur Internet.

### Démarrage automatique de Tailscale

#### Mac caisse (obligatoire pour l'accès distant)

1. Ouvrir l'app **Tailscale** (icône dans la barre de menu).
2. **Settings** / **Réglages** → activer **« Launch at login »** / **« Ouvrir à la connexion »**.
3. L'API Manager (script `install_manager_api_startup_mac.sh`) lance aussi `tailscale up` au démarrage si la commande est installée.

#### Téléphone / tablette Manager

- **iPhone** : Tailscale reste actif en arrière-plan ; ouvrir l'app une fois après redémarrage du téléphone si le portail ne répond plus.
- **Android** : Réglages Tailscale → autoriser le démarrage automatique / désactiver l'économie d'énergie pour Tailscale.

#### Même compte Tailscale

Tous les appareils (caisse + téléphone Manager) peuvent utiliser le **même compte** — c'est le plus simple.

### « Key expiry » / clé expire dans X mois

Message normal dans Tailscale (**Key expiry : in 5 months**).

| Question | Réponse |
|----------|---------|
| Est-ce un problème ? | **Non**, c'est une sécurité standard. |
| Que se passe-t-il ? | La clé de l'appareil est renouvelée **automatiquement** tant que Tailscale tourne et que le Mac est en ligne. |
| Action requise ? | Aucune dans la plupart des cas. |
| Désactiver l'expiration ? | [login.tailscale.com](https://login.tailscale.com) → **Machines** → clic sur le Mac caisse → **Disable key expiry** (réseau personnel / admin). |

Si le Mac caisse reste éteint plusieurs mois sans connexion, il faudra peut-être rouvrir Tailscale une fois pour renouveler la clé.

### Installation

1. Créer un compte gratuit sur [tailscale.com](https://tailscale.com)
2. Installer Tailscale sur le **PC boutique**
3. Installer Tailscale sur le **téléphone** et le **PC du manager** (App Store / Play Store)
4. Connecter les appareils au **même compte** Tailscale (recommandé)

### Accès

1. Sur le PC boutique, noter l'IP Tailscale (ex. `100.64.12.34`) — visible dans l'app Tailscale
2. Démarrer l'API : `./scripts/start_manager_api.sh` (Mac) ou démarrage auto Windows (voir ci-dessous)
3. Sur le téléphone, ouvrir le navigateur :

```
http://100.64.12.34:8080/manager/
```

4. Se connecter avec le compte **Manager**

> Ajouter la page aux favoris ou « Sur l'écran d'accueil » (iPhone/Android) pour un accès rapide comme une app.

### Pare-feu Windows

Autoriser le port **8080** entrant **uniquement** sur l'interface Tailscale, ou désactiver le pare-feu pour le réseau Tailscale.

> La tâche planifiée Windows se déclenche au **login** de l'utilisateur caisse.

---

## 4. Sécurité

| Mesure | Importance |
|--------|------------|
| Compte Manager avec mot de passe fort | Obligatoire |
| Tailscale (pas d'exposition Internet directe) | Recommandé |
| `JWT_SECRET` unique dans `api/.env` | Obligatoire |
| `APP_DEBUG=false` en production | Recommandé |
| Ne pas exposer PostgreSQL (port 5432) | Obligatoire |

L'API Manager lit la **même base locale** que l'application caisse. Aucune donnée ne transite par LWS.

---

## 5. Endpoints API (référence)

Tous requièrent `Authorization: Bearer <token>` et le rôle `manager`.

| Méthode | Route | Description |
|---------|-------|-------------|
| POST | `/api/auth/login` | Connexion |
| GET | `/api/manager/dashboard` | KPI du jour |
| GET | `/api/manager/sales?from=&to=` | Liste ventes |
| GET | `/api/manager/sale?id=` | Détail vente |
| GET | `/api/manager/returns` | Retours en attente |
| GET | `/api/manager/return?id=` | Détail retour |
| POST | `/api/manager/returns/approve` | Approuver retour |
| POST | `/api/manager/returns/reject` | Refuser retour |
| GET | `/api/manager/reports?from=&to=` | Rapport période |
| GET | `/api/manager/reports/yearly?year=` | Rapport annuel |
| GET | `/api/manager/alerts/low-stock` | Alertes stock |

---

## 6. Dépannage

| Problème | Solution |
|----------|----------|
| « Connexion base impossible » | Vérifier `api/.env` et que PostgreSQL tourne |
| « Accès réservé au manager » | Utiliser un compte Manager, pas Gestionnaire |
| Téléphone ne charge pas la page | Vérifier Tailscale actif des deux côtés + API démarrée |
| Port 8080 occupé | `./scripts/start_manager_api.sh 9090` |
| Retours indisponibles | Appliquer migration `008_sale_returns.sql` |

---

© Expérience Tech — SOUMAPARFUMERIE
