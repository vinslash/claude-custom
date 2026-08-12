---
name: recette-dataset
description: >
  Fabrique un jeu de données de recette scopé à un ticket SLI dans un worktree
  slash-interim, pour pouvoir CONSTATER le problème avant implémentation puis
  PROUVER sa résolution après. Commence par une phase d'exploration en lecture
  seule qui aboutit à un plan soumis à validation, puis part de l'API de seeding
  e2e (`POST /api/e2e/seed` + `DELETE /api/e2e/seed/:runId`) et ne descend au SQL
  brut qu'en échappatoire. Signale tout critère d'acceptation qui dépend d'un
  service externe (Tempo en tête, non mocké). Produit un jeu de données visible à
  l'écran, un handoff dans le scratchpad, et la capitalisation de la connaissance
  réutilisable.
  Use when the user says « jeu de données », « dataset de recette », « fixture »,
  « prépare la recette de SLI-XXXX », « je veux constater le bug avant de le
  corriger », « peuple la base pour ce ticket », « baseline avant implémentation »,
  or `/slash:recette-dataset SLI-XXXX`. À proposer aussi de manière proactive au
  démarrage d'un ticket dont la recette dépend de données absentes de la base
  clonée. Ne PAS utiliser pour écrire des tests automatisés (→ `slash-e2e-generate`,
  tests Jest) ni pour rédiger des scénarios de test fonctionnels (→
  `slash-functional-test-scenarios`).
---

# Jeu de données de recette scopé au ticket

## Pourquoi ce skill existe

Les worktrees arrivent avec un **clone de la base locale** (elle-même clone de
staging) — cf. `docs/adr/0004-infra-worktree-strategie-donnees.md`. En pratique
la base clonée manque souvent du cas précis que le ticket adresse : statut rare
absent, mois courant vide, une seule occurrence là où il en faut deux pour
distinguer un comportement d'un autre, feature flag éteint.

Sans le cas, la recette est impossible.

**Ne pas confondre avec le seed.** On ne répare pas le seed global, on ne wipe pas
la base : on ajoute **le strict nécessaire**, de façon réversible.

**Deux temps stricts.** Les phases -1 et 0 sont en **lecture seule** et
aboutissent à un plan validé par l'utilisateur. Rien ne s'écrit — ni en base, ni
vers un service externe — avant cette validation.

## Où est le détail

Ce fichier ne porte que ce qui s'applique toujours. Le reste est dans
`references/`, à lire **au moment où la question se pose**, pas avant :

| Fichier | À lire quand |
|---|---|
| `references/api-seed-e2e.md` | mécanisme A ou B retenu |
| `references/services-externes.md` | un critère parle de synchronisation ou d'envoi |
| `references/lecture-ecran.md` | l'écran est une liste, ou l'écriture reste invisible |
| `references/sql-brut.md` | A et B écartés |
| `references/capitalisation.md` | phase de consignation |

---

## Phase -1 — Garde-fou d'isolation (BLOQUANT, avant tout le reste)

Ce skill **écrit en base**. Deux façons de faire des dégâts irréversibles :

- lancé depuis le **checkout principal**, il mute la base locale du
  développeur — celle qui sert de **source de clone à tous les futurs
  worktrees**. La contamination se propage à chaque worktree créé ensuite ;
- lancé en ciblant un conteneur par son **nom**, il peut écrire dans la stack
  d'un **autre worktree** : plusieurs stacks tournent en parallèle, un nom repéré
  à l'œil dans `docker ps` ou recopié d'une session précédente est silencieusement
  le mauvais.

**Exécuter le garde-fou en premier, systématiquement :**

```bash
bash <base-dir-du-skill>/scripts/check-worktree-isolation.sh
```

Il vérifie que le worktree git est **lié** (et non le checkout principal), que la
stack Compose est **dédiée au worktree courant**, que les données Postgres sont
une **copie interne au worktree**, et que le port PG est **décalé** (≠ 5432). Il
affiche les cibles résolues.

**Sortie non nulle → ne rien écrire, s'arrêter et le dire.** Ne jamais contourner
le garde-fou ni « vérifier à la main à la place ».

Deux règles en découlent :

1. **Toujours passer par Compose depuis la racine du worktree**, qui résout le
   projet depuis le répertoire courant :
   `docker compose exec db.backend psql -U postgres -d postgres -c '...'`.
   **Jamais** `docker exec <nom-de-conteneur>`.
2. **Jamais de hostname `*.slash-interim.local`** : ils pointent sur la stack du
   checkout principal. Utiliser l'URL affichée par le garde-fou.

---

## Phase 0 — Exploration en lecture seule, puis plan validé

Non destructive : lecture de ticket, lecture de code, `SELECT`. Aucune écriture,
aucun appel sortant. Utiliser le **mode plan** pour la mener.

**0.1 — Critères d'acceptation.** Les lister explicitement, un par un. C'est la
liste qui pilote tout le reste : un dataset ne se justifie que par rapport à un
critère à observer.

**0.2 — Garde-fou « services externes » (BLOQUANT par critère).** Pour chaque
critère : sa validation implique-t-elle une écriture vers un service externe ? Un
critère du type « … et correctement synchronisé avec X » est un signal direct.
**Tempo n'est pas mocké et pointe sur le staging partagé : écrire dessus depuis
un worktree local est interdit.** Détail et liste complète dans
`references/services-externes.md`.

**0.3 — État des lieux de la base.** Requêter pour **chiffrer** ce qui manque.
Des constats numériques, pas des impressions : « 0 relevé `WAITING_FOR_REVIEW`
sur le mois courant », « 1 seul conseiller possède les 11 deals », « 6 valeurs
dans l'enum, la cible absente ».

**0.4 — Chemin de lecture.** Identifier d'où l'écran lit ses données. Beaucoup de
listes admin lisent Typesense, pas Postgres — une écriture SQL directe y reste
invisible. Voir `references/lecture-ecran.md`.

**0.5 — Porte anti-overkill.** Trois questions. **Dès qu'une réponse conclut
« pas de dataset », s'arrêter là.**

1. **Y a-t-il un critère observable dans l'UI ou l'API ?** Non → pas de dataset
   (refactor pur, renommage, migration de typage : les tests suffisent).
2. **La base contient-elle déjà le cas ?** À vérifier par requête (0.3), jamais
   par supposition. Oui → pas de dataset : noter les identifiants à utiliser.
3. **Le cas est-il distinguable ?** Pour valider un tri, un fan-out ou un filtre,
   il faut au moins **deux lignes qui divergent** sur la dimension testée. Une
   seule valeur en base → dataset nécessaire, même s'« il y a des données ».

**0.6 — Proposer le plan et attendre la validation.** Le plan contient, dans cet
ordre : les critères d'acceptation ; pour chacun, validable localement ou non et
pourquoi ; le constat de carence chiffré ; le verdict de la porte anti-overkill ;
si dataset, le périmètre exact et le mécanisme retenu ; ce qui restera **non
couvert**, explicitement.

**Proposer des options plutôt qu'une voie unique** dès qu'il y a un arbitrage réel
— quelle entité cibler, jusqu'où étendre un builder, comment traiter un critère
bloqué par un externe. Passer par `AskUserQuestion`. **Pas de go explicite → on ne
passe pas en Phase 1.**

---

## Phase 1 — Construire le jeu de données

Trois mécanismes, **dans cet ordre de préférence**. Ne descendre d'un cran que si
le précédent ne couvre pas le besoin, et dire pourquoi.

- **A — API de seeding e2e (défaut).** Additive, typée, ordonnée, avec rollback
  par `runId`. Couverture réelle et pièges : `references/api-seed-e2e.md`.
- **B — Étendre un builder e2e.** Dès que le manque est structurel. C'est le seul
  livrable durable de cette phase, et c'est du code produit : commit identifié,
  et générique. Même référence.
- **C — SQL brut.** Échappatoire pour le ponctuel non généralisable.
  `references/sql-brut.md`.

## Phase 2 — Rendre le jeu de données visible

Migrations, feature flags, réindexation Typesense, puis **contrôle à l'écran**.
Le détail et l'ordre exact sont dans `references/lecture-ecran.md`. Si le cas
n'apparaît pas, ne pas continuer : le dataset est inopérant.

## Phase 3 — La baseline « avant »

**Appelé par `slash:constat`, s'arrêter ici** et le lui rendre la main : la
baseline se constate avec Vince, c'est précisément son travail et non le nôtre.
Se contenter de dire que le cas est visible, et où.

**Appelé seul**, faire la baseline soi-même : se placer sur la branche avant
implémentation, naviguer jusqu'à l'écran, capturer l'état fautif, noter les
valeurs observées — compteurs, badges, ordre des lignes — et pas seulement
l'image. Décrire dès maintenant l'attendu « après ». Ne pas déclencher d'écriture
externe en naviguant (garde-fou 0.2).

## Phase 4 — Consigner et capitaliser

Un handoff éphémère dans le scratchpad, et la connaissance durable dans le dépôt.
Voir `references/capitalisation.md`.

## Phase 5 — Nettoyage

- Mécanisme A : `DELETE /api/e2e/seed/:runId` (repasse aussi les features
  optionnelles à `isDisabled: true`).
- Mécanisme C : rollback puis **réindexation Typesense**.
- Ne nettoyer qu'après validation de la recette « après implémentation ». Tant
  que la PR est en review, le dataset doit rester rejouable.

---

## Erreurs à ne pas commettre

- **Écrire en base sans avoir passé la Phase -1**, ou la contourner en
  « vérifiant à la main » : les dégâts survivent au ticket et se propagent aux
  worktrees suivants.
- **Écrire vers un service externe non mocké** — Tempo en tête. Le dégât est sur
  un système partagé, et souvent irréversible.
- **Cibler un conteneur par son nom** : un nom stale écrit dans la base d'un
  autre ticket sans rien signaler.
- **Enchaîner sur la Phase 1 sans plan validé.**
- Lancer `yarn test:integration` ou `yarn run command seed` pour peupler : les
  deux **détruisent** la base locale.
- Fabriquer un dataset sans avoir vérifié le chemin de lecture : on obtient une
  base correcte et un écran vide.
- Capturer la baseline **après** avoir commencé à implémenter.
- Un seul cas là où il en faut deux pour distinguer le bon comportement du mauvais.
- Committer la fixture SQL, ou l'oublier dans `git add -A`.
- Annoncer un critère « validé » alors qu'il dépend d'un externe non mocké.
