# Consigner et capitaliser

Deux niveaux, à ne pas mélanger.

## Éphémère — non committé, dans le scratchpad

`SLI-XXXX-HANDOFF.md`, à côté des SQL et des captures, contenant : les critères
d'acceptation et lesquels sont validables localement, le constat de carence
chiffré, le mécanisme retenu et pourquoi, l'ordre exact de rejeu, le `runId` e2e
ou le marqueur SQL, la baseline et l'attendu après, les pièges rencontrés.

Ces fichiers sont **régénérables**, donc leur perte est indolore — `/private/tmp`
peut être purgé par macOS, ce n'est pas un problème à condition que le niveau
suivant existe.

## Durable — committé, dans le dépôt

| Quoi | Où |
|---|---|
| Extension de builder ou de DTO (mécanisme B) | `backend/src/e2e/builders/`, `backend/src/e2e/dto/` |
| Recipe promue en seed réutilisable | `frontend/e2e/seeds/**` |
| Connaissance de domaine réutilisable | `docs/wiki/14-database-seeding.md`, `docs/wiki/13-feature-management.md` |

Ce qu'il faut capitaliser, c'est **la connaissance**, pas le SQL : quelle carence
a la base clonée, quel écran lit quelle collection, quel flag gouverne quoi, quel
critère est bloqué par quel externe. Ça survit aux re-clones ; le SQL non.

**Pas de note mémoire.** La mémoire de session est indexée par répertoire de
projet : une note écrite depuis le worktree `sli-8298` est invisible depuis
`sli-8412`. Pour une connaissance qui doit servir au ticket suivant, le seul
emplacement qui marche est le dépôt.
