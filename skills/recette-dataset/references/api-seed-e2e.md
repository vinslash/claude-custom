# Mécanisme A — l'API de seeding e2e en détail

À lire une fois le mécanisme A retenu, pas avant.

`POST /api/e2e/seed` est **additive** (n'efface pas la base), typée, ordonnée, et
`DELETE /api/e2e/seed/:runId` fait office de rollback automatique. Le contrôleur
n'a pas de guard d'auth : `curl` direct suffit.

Prérequis : `E2E_ENDPOINTS_ENABLED=true` dans `backend/.env`, sinon les routes ne
sont même pas montées (`backend/src/e2e/e2e.module.ts:36`). Le vérifier via
`curl http://localhost:<port backend>/api/e2e/health`.

## Ordre de construction

`backend/src/e2e/seed-orchestrator.service.ts:38`

```
features → agency → user → independent
        → clients[] → workers[] → deals[] → contracts[]
        → amendments[] → contractEvents[] → timesheets[]
```

## Couverture réelle de la recipe

`backend/src/e2e/dto/seed-recipe.dto.ts` — à connaître avant de promettre quoi
que ce soit.

| Bloc | Paramétrable |
|---|---|
| `features` | liste de `FeatureName` |
| `agency` | `name` |
| `user` | `email`, `role`, `firstConnection` |
| `clients[]` | `status`, `businessName` |
| `workers[]` | `status`, `firstName`, `lastName` |
| `deals[]` | `status`, `title` |
| `amendments[]` | `status`, taux et coefficients, `refusalExplanation` |
| `contractEvents[]` | `type`, `status` |
| `contracts[]` | **rien** — DTO vide |
| `timesheets[]` | **rien** — DTO vide, et le builder ignore sa config (`timesheet.builder.ts:13`), hardcode `status: ToTreat` + semaine courante |
| `independent` | **rien** — un seul, non paramétrable |

## Deux pièges

`FeatureBuilder` gère déjà le rattachement au user group : une feature n'est
servie par `getAvailableFeatures` que si elle est rattachée à un groupe,
`isDisabled: false` ne suffit pas. Il rattache tous les groupes automatiquement —
ne pas le refaire à la main.

Les builders passent par les repositories TypeORM, donc **les subscribers et les
syncs peuvent se déclencher**. Si une entité seedée est synchronisée vers un
service externe non mocké, on retombe sur le garde-fou 0.2.

## Mécanisme B — étendre un builder

Dès que le manque est **structurel** (un statut non paramétrable, un 2e
conseiller, un champ ajouté par le ticket), étendre le DTO + le builder plutôt
que de contourner en SQL.

C'est le seul livrable **durable** : typé, il casse à la compilation au prochain
changement de schéma, il est reviewable et la CI e2e l'exerce. Un `.sql` posé à
côté rotte en silence.

Attention : cette extension est du **code produit**. Elle va dans un commit
identifié (`:sparkles:` / `:wrench:`) et doit rester générique — pas de champ
`sli8250Flag`. Si elle ne peut pas être générique, c'est le signal qu'on est dans
le cas C.
