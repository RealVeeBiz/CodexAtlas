# Hydro-Québec — Test de compétence

Application web autonome : le candidat entre son nom, répond à des questions tirées au hasard, et un admin gère la banque via `/admin`.

## Démarrage

```bash
cd hydrotest
cp .env.example .env   # optionnel
npm install
npm start
```

Ouvrir :
- Test : http://localhost:3000
- Admin : http://localhost:3000/admin (mot de passe par défaut : `hydroadmin`)

## Fonctionnalités

- Saisie du nom avant le test
- Tirage aléatoire de questions + mélange des réponses
- Seuil de réussite configurable (`PASS_PERCENT`)
- Admin : CRUD questions (activer / désactiver)
- Historique des résultats (`data/results.json`)
- Banque initiale avec catégories Sécurité, Batterie, Consignation, Urgence…

## Configuration (`.env`)

| Variable | Défaut | Rôle |
|----------|--------|------|
| `PORT` | `3000` | Port HTTP |
| `ADMIN_PASSWORD` | `hydroadmin` | Mot de passe admin |
| `QUESTIONS_PER_TEST` | `8` | Nombre de questions par tentative |
| `PASS_PERCENT` | `70` | Seuil de réussite |

Les questions sont stockées dans `data/questions.json`.
