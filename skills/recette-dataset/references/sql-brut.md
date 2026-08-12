# Mécanisme C — le SQL brut, en échappatoire

À lire seulement après avoir écarté les mécanismes A et B, et avoir dit pourquoi.

Réservé au ponctuel non généralisable : forcer un état incohérent exprès, tordre
une date, casser une invariante pour tester un garde-fou.

Avantage secondaire : il **contourne les subscribers**, donc n'émet rien vers
l'extérieur — parfois la seule façon de préparer un cas sans toucher un service
externe non mocké.

## Règles non négociables

- **Deux fichiers systématiquement** : `sli-XXXX-fixture.sql` et
  `sli-XXXX-rollback.sql`. Jamais de fixture sans son rollback.
- **Idempotent** : rejouable sans dupliquer (`ON CONFLICT DO NOTHING`, ou
  `DELETE` ciblé en tête).
- **Marqueur identifiable** dans un champ texte, sur le modèle du `runId` e2e,
  pour que le rollback soit ciblé et non « tout ce qui a été créé aujourd'hui ».
- **Jamais committé.** Ces fichiers sont calibrés sur un instantané du clone
  (identifiants, dates, cardinalités) : après le prochain re-clone ils sont faux
  tout en ayant l'air autoritaires, et rien en CI ne les exerce.

## Nettoyage

Jouer `sli-XXXX-rollback.sql`, puis **réindexer Typesense** — sinon les documents
supprimés en base restent visibles dans la collection.
