# API REST — Souma Parfumerie

API PHP 8.1+ pour la synchronisation cloud (hébergement LWS / MAMP).

## Installation

```bash
cd api
composer install
cp .env.example .env
# Éditer .env : DB_*, JWT_SECRET, APP_SECRET
```

## Base de données

Utilise la même base PostgreSQL que l’app desktop (`database/schema.sql`).

Variables `.env` :

| Variable   | Description        |
|-----------|--------------------|
| DB_HOST   | Hôte PostgreSQL    |
| DB_PORT   | Port (5432)        |
| DB_NAME   | `souma_parfumerie` |
| DB_USER   | Utilisateur        |
| DB_PASS   | Mot de passe       |
| JWT_SECRET| Clé JWT (32+ car.) |

## URL MAMP (exemple)

Document root : `api/public/`

- Santé : `GET .../api/public/api/health`
- Login : `POST .../api/public/api/auth/login`
- Sync pull : `GET .../api/public/api/sync/pull` (Bearer JWT)
- Sync push : `POST .../api/public/api/sync/push` (Bearer JWT)
- **Portail Manager** : `.../api/public/manager/` (téléphone / PC, sans LWS)

### API Manager (accès distant local)

Routes réservées au rôle `manager` (Bearer JWT) :

| Route | Description |
|-------|-------------|
| `GET /api/manager/dashboard` | KPI du jour |
| `GET /api/manager/sales` | Historique ventes |
| `GET /api/manager/reports` | Rapports période |
| `GET /api/manager/reports/yearly` | Rapport annuel |
| `GET /api/manager/returns` | Retours en attente |
| `POST /api/manager/returns/approve` | Approuver retour |

Démarrage local : `./scripts/start_manager_api.sh` — voir [docs/ACCES_MANAGER_DISTANT.md](../docs/ACCES_MANAGER_DISTANT.md).

Le chemin `/api/...` est normalisé automatiquement depuis l’URL complète MAMP.

## Test rapide

```bash
curl "http://localhost:8888/Souma%20Parfumerie/api/public/api/health"
```

```bash
curl -X POST "http://localhost:8888/Souma%20Parfumerie/api/public/api/auth/login" \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"Admin@2026"}'
```

## Structure

```
api/
├── public/index.php    # Point d'entrée
├── src/
│   ├── Core/           # Router, Request, Database
│   ├── Controllers/    # Auth, Sync, Health
│   ├── Middleware/     # CORS, JWT
│   └── Services/       # JWT, Audit
└── .env.example
```
