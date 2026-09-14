# D'où l'écran lit ses données, et comment l'y faire apparaître

À lire dès qu'on cible un écran de liste, ou qu'une écriture en base reste
invisible dans l'interface.

## Le chemin de lecture

Beaucoup de listes admin lisent **Typesense**, pas Postgres : une écriture SQL
directe reste alors invisible. Collections existantes
(`SearchCollectionNames`) : `overdue_bill`, `deal_global_information`,
`deal_prolongation_amendment`, `candidate_search`, `timesheets_overview`.

Un écran de **détail ou de formulaire** lit en général l'entité directement : pas
de Typesense, pas de réindexation. Le vérifier plutôt que de le supposer.

## Les feature flags

Vérifier les flags qui gouvernent l'écran **et** l'écriture dans la collection :
`SEARCH_COLLECTION_WRITE_FEATURE_FLAG` dans
`backend/src/search-collection/core/domain/types/search-collection.types.ts`.

## Rendre le jeu de données visible

Une écriture en base ne suffit presque jamais. Dans l'ordre :

1. **Migrations**, si le ticket en ajoute une :
   `docker compose exec backend yarn migration:run`
2. **Feature flags** : via `features` dans la recipe (mécanisme A), qui gère le
   rattachement au user group.
3. **Réindexation Typesense**, si l'écran lit une collection :
   ```bash
   docker compose exec backend yarn command populate-search-collection --collection <nom>
   ```
   À faire **après** toutes les écritures. Une fixture SQL bypasse les
   subscribers ; le mécanisme A passe par les repositories TypeORM et déclenche
   normalement la sync — le vérifier plutôt que de le supposer.
4. **Contrôle** : recharger l'écran et vérifier que le cas apparaît. Si non, ne
   pas continuer : le dataset est inopérant.

## Le piège d'URL

Vérifier l'URL exacte de l'écran visé. Un chemin sans préfixe `/admin` peut
afficher une page homonyme côté indépendant, déjà fonctionnelle, et faire croire
que le ticket est déjà livré.
