# Application Flutter — Souma Parfumerie

Client desktop **offline-first** (Windows / macOS / Linux) pour la gestion de la boutique.

## Documentation complète

Voir le [README principal](../README.md) à la racine du projet (installation PostgreSQL, API, comptes, déploiement).

## Démarrage rapide

```bash
cd app
flutter pub get
flutter gen-l10n
flutter run -d macos    # ou windows / linux
```

## Configuration locale

Fichier `lib/core/config/app_config.dart` :

- Utilisateur / mot de passe PostgreSQL
- URL de l’API (`defaultApiBaseUrl`)

## Tests

```bash
flutter analyze
flutter test
```

## Build production (Windows)

```bash
flutter build windows --release
```

Sortie : `build/windows/x64/runner/Release/`
