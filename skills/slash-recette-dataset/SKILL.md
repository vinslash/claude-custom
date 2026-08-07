---
name: slash-recette-dataset
description: >
  Fabrique un jeu de données de recette scopé à un ticket SLI dans un worktree
  slash-interim, pour pouvoir CONSTATER le problème avant implémentation puis
  PROUVER sa résolution après. Commence par une phase d'exploration en lecture
  seule qui aboutit à un plan soumis à validation, puis part de l'API de seeding
  e2e (`POST /api/e2e/seed` + `DELETE /api/e2e/seed/:runId`) et ne descend au SQL
  brut qu'en échappatoire. Signale tout critère d'acceptation qui dépend d'un
  service externe (Tempo en tête, non mocké). Produit une baseline « avant »
  constatée en navigateur, un handoff dans le scratchpad, et la capitalisation de
  la connaissance réutilisable.
  Use when the user says « jeu de données », « dataset de recette », « fixture »,
  « prépare la recette de SLI-XXXX », « je veux constater le bug avant de le
  corriger », « peuple la base pour ce ticket », « baseline avant implémentation »,
  or `/slash-recette-dataset SLI-XXXX`. À proposer aussi de manière proactive au
  démarrage d'un ticket dont la recette dépend de données absentes de la base
  clonée. Ne PAS utiliser pour écrire des tests automatisés (→ `slash-e2e-generate`,
  tests Jest) ni pour rédiger des scénarios de test fonctionnels (→
  `slash-functional-test-scenarios`).
---

# Jeu de données de recette scopé au ticket

## Pourquoi ce skill existe

Les worktrees arrivent avec un **clone de la base locale** (elle-même clone de
staging) — cf. `docs/adr/0004-infra-worktree-strategie-donnees.md`. L'ADR acte
cette stratégie mais liste en conséquence négative : *« le clone fige les
dates »*. En pratique la base clonée manque souvent du cas précis que le ticket
adresse : statut rare absent, mois courant vide, une seule occurrence là où il
en faut deux pour distinguer un comportement d'un autre, feature flag éteint.

Sans le cas, la recette est impossible. Sans baseline « avant », on ne prouve
rien.

**Ne pas confondre avec le seed.** On ne répare pas le seed global, on ne wipe
pas la base : on ajoute **le strict nécessaire**, de façon réversible.

**Deux temps stricts.** Phase -1 et Phase 0 sont en **lecture seule** et
aboutissent à un plan validé par l'utilisateur. Rien ne s'écrit — ni en base, ni
vers un service externe — avant cette validation.

---

## Phase -1 — Garde-fou d'isolation (BLOQUANT, avant tout le reste)

Ce skill **écrit en base**. Deux façons de faire des dégâts irréversibles :

- lancé depuis le **checkout principal**, il mute la base locale du
  développeur — celle qui sert de **source de clone à tous les futurs
  worktrees**. La contamination se propage à chaque worktree créé ensuite ;
- lancé en ciblant un conteneur par son **nom**, il peut écrire dans la stack
  d'un **autre worktree** : plusieurs stacks tournent en parallèle, un nom
  repéré à l'œil dans `docker ps` ou recopié d'une session précédente est
  silencieusement le mauvais.

**Exécuter le garde-fou en premier, systématiquement :**

```bash
bash <base-dir-du-skill>/scripts/check-worktree-isolation.sh
```

(`<base-dir-du-skill>` est annoncé au chargement du skill — aujourd'hui
`~/.claude/skills/slash-recette-dataset`, demain `.claude/skills/…` après
promotion dans le dépôt. Ne pas coder ce chemin en dur ailleurs.)

Il vérifie que le worktree git est **lié** (et non le checkout principal), que
la stack Compose est **dédiée au worktree courant**, que les données Postgres
sont une **copie interne au worktree** (bind mount sous la racine du worktree,
pas un volume partagé), et que le port PG est **décalé** (≠ 5432). Il affiche
les cibles résolues (projet Compose, port PG, URL backend).

**Sortie non nulle → ne rien écrire, s'arrêter et le dire à l'utilisateur.**
Ne jamais contourner le garde-fou ni « vérifier à la main à la place ».

### Deux règles qui découlent du garde-fou

1. **Toujours passer par Compose depuis la racine du worktree**, qui résout le
   projet depuis le répertoire courant :
   ```bash
   docker compose exec db.backend psql -U postgres -d postgres -c '...'
   docker compose exec backend yarn migration:run
   ```
   **Jamais** `docker exec <nom-de-conteneur>`.
2. **Jamais de hostname `*.slash-interim.local`** : ils pointent sur la stack du
   checkout principal. Utiliser l'URL backend affichée par le garde-fou
   (`http://localhost:<port décalé>`).

---

## Phase 0 — Exploration en lecture seule, puis plan validé

Toute cette phase est **non destructive** : lecture de ticket, lecture de code,
`SELECT` en base. Aucune écriture, aucun appel sortant. Utiliser le **mode plan**
(`EnterPlanMode`) pour la mener si disponible.

Elle se termine **obligatoirement** par un plan soumis à l'utilisateur. Ne
jamais enchaîner directement sur la Phase 1.

### 0.1 — Critères d'acceptation

Lire le ticket et **lister explicitement chaque critère d'acceptation**, un par
un. C'est la liste qui pilote tout le reste : un dataset ne se justifie que par
rapport à un critère à observer.

### 0.2 — Garde-fou « services externes » (BLOQUANT par critère)

Pour **chaque** critère, se demander : *sa validation implique-t-elle une
écriture vers un service externe ?* Un critère du type « … et correctement
synchronisé avec X » est un signal direct.

Services externes du produit : **Tempo**, Firebase Auth, Brevo, Allianz
(assurance), Armado (GED), DPAE URSSAF, All My SMS, Hiresweet, Microsoft Graph,
AWS SES, S3.

**Règle dure — Tempo.** Tempo **n'est pas mocké**. `TEMPO_BASE_URL` a pour
défaut `https://ws-stg.slash-interim.com/api/tempo`
(`backend/src/tempo/tempo.module.ts:43`), c'est-à-dire le **Tempo de staging
partagé**. Écrire dessus depuis un worktree local est **interdit** :

- ça pollue un système partagé par toute l'équipe, de façon souvent
  irréversible (Tempo n'expose pas de DELETE sur certaines entités — c'est la
  cause d'origine de l'ADR 0004) ;
- un mock serveur Tempo est **souhaité mais n'existe pas encore**, donc il n'y
  a pas d'échappatoire technique aujourd'hui.

Pour les autres externes, vérifier ce que couvre le mockserver local :
`backend/mockserver/expectations.json` (Brevo, Microsoft Graph, INSEE Sirene,
SMTP, Hellowork y figurent). Ce qui est mocké est validable localement ; ce qui
ne l'est pas, non.

**Conséquence à énoncer clairement dans le plan** : un critère qui dépend d'un
externe non mocké **n'est pas validable en recette locale**. Ne pas le
contourner, ne pas le passer sous silence. Le plan doit dire, pour ce critère :
ce qui **est** couvert localement (mapping vérifié par test unitaire, payload
inspecté avant envoi, valeur persistée en base) et ce qui **reste** à valider
ailleurs (recette humaine en staging/preprod, ou différé jusqu'au mock).

### 0.3 — État des lieux de la base

Requêter pour **chiffrer** ce qui manque, et le consigner. Formuler des constats
numériques, pas des impressions : « 0 relevé `WAITING_FOR_REVIEW` sur le mois
courant », « 1 seul conseiller possède les 11 deals », « 6 valeurs dans l'enum,
la cible absente ».

### 0.4 — Chemin de lecture

Identifier **d'où l'écran lit ses données**. Beaucoup de listes admin lisent
**Typesense**, pas Postgres : une écriture SQL directe reste alors invisible.
Collections (`SearchCollectionNames`) : `overdue_bill`,
`deal_global_information`, `deal_prolongation_amendment`, `candidate_search`,
`timesheets_overview`.

Vérifier aussi les **feature flags** qui gouvernent l'écran ET l'écriture dans
la collection (`SEARCH_COLLECTION_WRITE_FEATURE_FLAG` dans
`backend/src/search-collection/core/domain/types/search-collection.types.ts`).

Un écran de **détail / formulaire** lit en général l'entité directement : pas de
Typesense, pas de reindex. Le vérifier plutôt que de le supposer.

### 0.5 — Porte anti-overkill

Trois questions. **Dès qu'une réponse conclut « pas de dataset », s'arrêter là.**

1. **Y a-t-il un critère observable dans l'UI ou l'API ?**
   Non → **pas de dataset** (refactor pur, renommage interne, migration de
   typage : les tests unitaires suffisent).
2. **La base contient-elle déjà le cas ?** À vérifier par requête (0.3), jamais
   par supposition. Oui → **pas de dataset** : noter les identifiants des
   entités à utiliser et passer directement à la baseline (Phase 3).
3. **Le cas est-il distinguable ?** Un cas unique ne prouve souvent rien : pour
   valider un tri, un fan-out ou un filtre, il faut au moins **deux lignes qui
   divergent** sur la dimension testée. Une seule valeur en base → **dataset
   nécessaire**, même s'« il y a des données ».

### 0.6 — Proposer le plan et attendre la validation

Soumettre un plan qui contient, dans cet ordre :

- la liste des critères d'acceptation ;
- pour chacun : **validable localement ou non**, et pourquoi (garde-fou 0.2) ;
- le constat de carence chiffré ;
- le verdict de la porte anti-overkill : dataset nécessaire ou non ;
- si dataset : périmètre exact, mécanisme retenu (Phase 1) et ce qui sera écrit
  en base ;
- ce qui restera **non couvert**, explicitement.

**Proposer des options plutôt qu'une voie unique** dès qu'il y a un arbitrage
réel (quel client / quelle entité cibler, jusqu'où étendre un builder, comment
traiter un critère bloqué par un externe). Passer par `AskUserQuestion` : elle
laisse toujours à l'utilisateur la possibilité d'en proposer une autre.

**Attendre le go explicite.** Pas de go → on ne passe pas en Phase 1.

---

## Phase 1 — Construire le jeu de données

Trois mécanismes, **dans cet ordre de préférence**. Ne descendre d'un cran que
si le précédent ne couvre pas le besoin, et dire pourquoi.

### Mécanisme A — API de seeding e2e (défaut)

`POST /api/e2e/seed` est **additive** (n'efface pas la base), typée, ordonnée,
et `DELETE /api/e2e/seed/:runId` fait office de rollback automatique. Le
contrôleur n'a pas de guard d'auth : `curl` direct suffit. Prérequis :
`E2E_ENDPOINTS_ENABLED=true` dans `backend/.env`, sinon les routes ne sont même
pas montées (`backend/src/e2e/e2e.module.ts:36`) — le vérifier via
`curl http://localhost:<port backend>/api/e2e/health`.

Ordre de construction (`backend/src/e2e/seed-orchestrator.service.ts:38`) :

```
features → agency → user → independent
        → clients[] → workers[] → deals[] → contracts[]
        → amendments[] → contractEvents[] → timesheets[]
```

Couverture réelle de la recipe (`backend/src/e2e/dto/seed-recipe.dto.ts`) — à
connaître avant de promettre quoi que ce soit :

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

Bon à savoir : `FeatureBuilder` gère déjà le piège du rattachement au user group
(une feature n'est servie par `getAvailableFeatures` que si elle est rattachée à
un groupe — `isDisabled: false` ne suffit pas). Il rattache tous les groupes
automatiquement. Ne pas le refaire à la main.

Attention aux **effets de bord sortants** : les builders passent par les
repositories TypeORM, donc les subscribers et les syncs peuvent se déclencher.
Si une entité seedée est synchronisée vers un externe non mocké, on retombe sur
le garde-fou 0.2.

### Mécanisme B — Étendre un builder e2e

Dès que le manque est **structurel** (un statut non paramétrable, un 2e
conseiller, un champ ajouté par le ticket), étendre le DTO + le builder plutôt
que de contourner en SQL.

C'est le seul livrable **durable** de la Phase 1 : typé, il casse à la
compilation au prochain changement de schéma, il est reviewable et la CI e2e
l'exerce. Un `.sql` posé à côté rotte en silence.

Attention : cette extension est du **code produit**. Elle va dans un commit
identifié (`:sparkles:` / `:wrench:`) et doit rester générique — pas de champ
`sli8250Flag`. Si elle ne peut pas être générique, c'est un signal qu'on est
dans le cas C.

### Mécanisme C — SQL brut (échappatoire)

Réservé au ponctuel non généralisable : forcer un état incohérent exprès,
tordre une date, casser une invariante pour tester un garde-fou. Avantage
secondaire : il **contourne les subscribers**, donc n'émet rien vers l'extérieur
— parfois la seule façon de préparer un cas sans toucher un service externe.

Règles non négociables :

- **Deux fichiers systématiquement** : `sli-XXXX-fixture.sql` et
  `sli-XXXX-rollback.sql`. Jamais de fixture sans son rollback.
- **Idempotent** : rejouable sans dupliquer (`ON CONFLICT DO NOTHING`, ou
  `DELETE` ciblé en tête).
- **Marqueur identifiable** dans un champ texte, sur le modèle du `runId` e2e,
  pour que le rollback soit ciblé et non « tout ce qui a été créé aujourd'hui ».
- **Jamais committé** (voir Phase 4).

---

## Phase 2 — Rendre le jeu de données visible

Une écriture en base ne suffit presque jamais. Dans l'ordre :

1. **Migrations** si le ticket en ajoute une :
   `docker compose exec backend yarn migration:run`.
2. **Feature flags** : via `features` dans la recipe (mécanisme A), qui gère le
   user group.
3. **Réindexation Typesense** si l'écran lit une collection :
   ```bash
   docker compose exec backend yarn command populate-search-collection --collection <nom>
   ```
   À faire **après** toutes les écritures. Une fixture SQL bypasse les
   subscribers ; le mécanisme A passe par les repositories TypeORM et déclenche
   normalement la sync — le vérifier plutôt que de le supposer.
4. **Contrôle** : recharger l'écran et vérifier que le cas apparaît. Si non,
   ne pas continuer : le dataset est inopérant.

---

## Phase 3 — Baseline « avant implémentation »

C'est ce qui donne sa valeur à tout le reste : sans baseline, la PR ne prouve
pas qu'elle corrige quelque chose.

- Se placer **sur la branche avant implémentation** (le code du ticket n'est pas
  écrit, ou stashé).
- Naviguer jusqu'à l'écran et **capturer** l'état fautif (Chrome DevTools).
  Viewport max **1440×820**, au-delà la fenêtre dépasse l'écran et les captures
  sont tronquées.
- **Vérifier l'URL exacte** de l'écran visé. Piège récurrent : un chemin sans
  préfixe `/admin` peut afficher une page homonyme côté indépendant, déjà
  fonctionnelle, et faire croire que le ticket est déjà livré.
- **Ne pas déclencher d'écriture externe** en naviguant : si valider le
  formulaire pousse vers un externe non mocké, s'arrêter avant la sauvegarde et
  le dire (garde-fou 0.2).
- Noter les valeurs observées (compteurs, badges, ordre des lignes) — pas
  seulement l'image.

Ce qui est capturé ici sera rejoué à l'identique après implémentation. Décrire
dès maintenant l'attendu « après ».

---

## Phase 4 — Consigner et capitaliser

Deux niveaux, à ne pas mélanger.

### Éphémère — non committé, dans le scratchpad

`SLI-XXXX-HANDOFF.md` à côté des SQL et des captures, contenant : critères
d'acceptation et lesquels sont validables localement, constat de carence
chiffré, mécanisme retenu et pourquoi, ordre exact de rejeu, `runId` e2e ou
marqueur SQL, baseline + attendu après, pièges rencontrés.

Ces fichiers sont **régénérables**, donc leur perte est indolore — `/private/tmp`
peut être purgé par macOS, ce n'est pas un problème à condition que le niveau
suivant existe.

### Durable — committé

| Quoi | Où |
|---|---|
| Extension de builder / DTO (mécanisme B) | `backend/src/e2e/builders/`, `backend/src/e2e/dto/` |
| Recipe promue en seed réutilisable | `frontend/e2e/seeds/**` |
| Connaissance de domaine réutilisable | `docs/wiki/14-database-seeding.md`, `docs/wiki/13-feature-management.md` |

**Ne jamais committer les `.sql` ad hoc.** Ils sont calibrés sur un instantané
du clone (IDs, dates, cardinalités) : après le prochain re-clone ils sont faux
tout en ayant l'air autoritaires, et rien en CI ne les exerce.

Ce qu'il faut capitaliser, c'est **la connaissance**, pas le SQL : quelle
carence a la base clonée, quel écran lit quelle collection, quel flag gouverne
quoi, quel critère est bloqué par quel externe. Ça survit aux re-clones ; le SQL
non. Ajouter aussi une note mémoire `sli-XXXX-recette-dataset` pointant le
handoff et les pièges.

---

## Phase 5 — Nettoyage

- Mécanisme A : `DELETE /api/e2e/seed/:runId` (repasse aussi les features
  optionnelles à `isDisabled: true`).
- Mécanisme C : jouer `sli-XXXX-rollback.sql`, puis **réindexer Typesense** —
  sinon les documents supprimés en base restent visibles dans la collection.
- Ne nettoyer qu'après validation de la recette « après implémentation ». Tant
  que la PR est en review, le dataset doit rester rejouable.

---

## Erreurs à ne pas commettre

- **Écrire en base sans avoir passé la Phase -1**, ou la contourner en
  « vérifiant à la main » : c'est l'erreur dont les dégâts survivent au ticket
  et se propagent aux worktrees suivants.
- **Écrire vers un service externe non mocké depuis un worktree local** — Tempo
  en tête. Le dégât est sur un système partagé par l'équipe, et souvent
  irréversible.
- **Cibler un conteneur par son nom** (`docker exec slash-sli-XXXX-db...`) :
  plusieurs stacks tournent en parallèle, un nom stale écrit dans la base d'un
  autre ticket sans rien signaler. Toujours `docker compose exec` depuis la
  racine du worktree.
- **Enchaîner sur la Phase 1 sans plan validé** : la Phase 0 se termine par une
  validation, pas par une conclusion personnelle.
- Lancer `yarn test:integration` ou `yarn run command seed` pour peupler : les
  deux **détruisent** la base locale de l'utilisateur.
- Fabriquer un dataset sans avoir vérifié le chemin de lecture : on obtient une
  base correcte et un écran vide.
- Capturer la baseline **après** avoir commencé à implémenter.
- Un seul cas là où il en faut deux pour distinguer le bon comportement du
  mauvais.
- Committer la fixture SQL, ou l'oublier dans `git add -A`.
- Annoncer un critère « validé » alors qu'il dépend d'un externe non mocké.
