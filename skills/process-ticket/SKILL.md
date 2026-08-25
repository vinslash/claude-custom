---
name: process-ticket
description: >
  Parcours complet de traitement d'un ticket Linear SLI dans un worktree
  slash-interim ou slash-web, du worktree déjà créé jusqu'à la PR ouverte. Impose
  l'ordre qui compte : faire CONSTATER le problème à l'utilisateur avant
  d'écrire une ligne, faire arbitrer le plan, implémenter, faire constater la
  résolution,
  committer, remettre la branche à jour sur `develop`, puis ouvrir la PR. Deux
  points d'arrêt bloquants — la validation du plan, passée par le mode plan, et la
  validation de la résolution. Impose l'appel explicite de la commande
  `/slash-rebase` avant toute PR, seul endroit où l'ordre des migrations TypeORM
  est contrôlé — un CI rouge qui ne se voit pas dans le diff. Délègue la
  compréhension et le constat à `slash:constat`, le jeu de données à
  `slash:recette-dataset`, les commits et la PR aux skills du dépôt slash-interim
  (`slash-commit`, `slash-create-pr`), la taille de la PR et son découpage
  éventuel à `slash:decoupage-pr`, et le contenu rédigé des écrits GitHub à
  `slash:redaction`.
  Use when the user says « mission : traiter ce ticket », « traite le ticket »,
  « on attaque SLI-XXXX », « je viens de créer le worktree », or
  `/slash:process-ticket SLI-XXXX`; and at the start of any session whose cwd is
  an `sli-XXXX-*` worktree. Ne PAS utiliser pour reprendre une PR déjà ouverte
  (→ `slash:redaction`), pour une review, ni pour un travail sans ticket
  Linear — exploration, question, correctif ponctuel demandé dans le chat.
---

# Traitement d'un ticket Linear, du worktree à la PR

## Pourquoi ce skill existe

Le réflexe naturel, sur un ticket, est de lire la description et de se mettre à
coder. Ça produit deux échecs classiques : on corrige quelque chose que personne
n'a vu casser, et on n'a rien pour prouver que c'est réparé.

Le parcours ci-dessous existe pour empêcher ça. Il tient sur un ordre —
**constater avant d'implémenter, faire constater avant de committer** — et sur
deux points d'arrêt où l'utilisateur arbitre. Tout le reste est de l'intendance.

Une troisième raison, apprise à l'usage : un parcours qui déroule tout seul finit
par produire un développeur qui ne sait plus défendre son propre ticket en
review. C'est pourquoi la première étape n'est pas une analyse, c'est un constat
partagé.

## Préconditions

Le ticket est porté par le nom de la branche, et un hook l'injecte au démarrage
de la session. Si ce contexte est absent — pas de worktree, branche sans
identifiant — le dire et s'arrêter plutôt que d'improviser un périmètre.

## Le suivi d'avancement

Avant l'étape 1, matérialiser le parcours en **task list** : une tâche par étape,
sept en tout, dans l'ordre, en reprenant les intitulés des titres d'étape
ci-dessous pour que deux tickets se lisent pareil. Pas plus fin — les phases
internes de `slash:constat` ou `slash:recette-dataset` n'y entrent pas, elles
transformeraient la liste en bruit.

C'est ce qui permet de reprendre un ticket après en avoir traité un autre :
plusieurs worktrees tournent en parallèle, et savoir où on en est ne doit pas
dépendre de ce qu'on se rappelle.

**Commencer par `TaskList`.** Si les tâches existent déjà, ne pas les recréer.

**Si la liste est vide alors que le travail a commencé** — nouvelle session sur un
ticket entamé, ou session précédente perdue — la reconstruire et marquer d'emblée
`completed` ce qui est déjà fait. L'état se lit dans le fichier d'observation,
dans les commits de la branche et dans le diff, jamais dans la mémoire de la
session.

Ensuite : `in_progress` en entrant dans une étape, `completed` en la quittant.
Les deux barrières s'encodent en dépendances plutôt qu'en bonnes intentions —
l'étape 3 `addBlockedBy` l'étape 2, l'étape 7 `addBlockedBy` l'étape 4.

**Une étape à barrière ne passe à `completed` que sur validation explicite de
l'utilisateur**, jamais sur l'appréciation de l'agent. C'est la règle qui compte,
parce qu'une checklist invite exactement au travers que ce skill existe pour
empêcher : prendre le fait de cocher pour l'accomplissement. Une case cochée sans
que l'utilisateur ait rien constaté a l'air de la rigueur et n'en est pas.

Enfin, la liste porte la **position** dans le parcours ; le fichier d'observation
porte le **contenu**. Ni l'un ni l'autre ne remplace le rapport de trois à cinq
lignes ci-dessous : cocher une case n'est pas rendre compte.

## Ce que « rapport » veut dire ici

À chaque étape, un rapport de **trois à cinq lignes en prose** : ce qui a été
constaté, ce qui est proposé, ce qui bloque ou manque.

Pas de tableau, pas de recopie du diff, pas de liste de fichiers touchés, pas de
récapitulatif étape par étape. Si le rapport ne tient pas en cinq lignes, c'est
qu'il contient autre chose qu'un rapport.

Ne pas charger `slash:redaction` pour ces rapports : il exclut explicitement la
rédaction destinée au chat. Il gouverne en revanche le **document de plan** de
l'étape 2 et les écrits GitHub de l'étape 7 — un rapport de cinq lignes et un
plan soumis à arbitrage ne sont pas le même écrit.

## Rester dans le périmètre

Le ticket, et rien que le ticket. Pas de refactor opportuniste, pas de correction
d'un bug adjacent croisé en route, pas de nettoyage de code qu'on trouve laid.

Ce qui est hors périmètre tient en **une ligne** dans le rapport de l'étape en
cours — et on continue. L'utilisateur décidera s'il en fait un ticket.

---

## Étape 1 — Constat partagé

Appeler **`slash:constat`** en mode « avant ». Il possède tout le bloc «
comprendre » : la lecture du ticket — **la seule de tout le parcours**, ne pas
la refaire ensuite —, la localisation du code, l'appel à `slash:recette-dataset`
si le cas manque en base, la phase où l'utilisateur reproduit le problème de ses
propres mains, et la répétition des challenges du PM et des reviewers.

Il produit un fichier d'observation : le POURQUOI du ticket avec les mots de
l'utilisateur, les questions restées ouvertes, et le script de rejeu. **Ce fichier
voyage jusqu'à la dernière étape** — c'est de lui que sortira la description de
PR, et non du diff.

**Si le problème ne se reproduit pas, s'arrêter là.** Ou le ticket décrit mal le
problème, ou l'environnement ne correspond pas : dans les deux cas, coder est
prématuré.

## Étape 2 — Plan et arbitrage (point d'arrêt bloquant)

Proposer un plan : l'approche retenue et pourquoi, les fichiers concernés, les
effets de bord attendus, ce qu'on laisse volontairement de côté. Une alternative
ne se présente que si le choix change quelque chose pour l'utilisateur ; sinon,
recommander et avancer.

**Charger `slash:redaction` avant de rédiger le plan.** Un plan est un livrable
long relu par un humain, et c'est ce skill qui en porte la forme : 200 lignes au
plus, la passe d'élagage avant de soumettre, pas de plaidoirie sur des décisions
que personne ne conteste, et le hors-périmètre réduit à une ligne de renvoi.
L'analyse coûteuse qui n'entre pas dans le plan ne se perd pas pour autant : elle
part en commentaire du ticket Linear, dans les 250 mots.

**Passer par le mode plan** et soumettre via `ExitPlanMode`. C'est une vraie
porte d'approbation : elle ne se franchit pas sur un « ok » qui répondait à autre
chose. **Ne rien écrire dans le dépôt à ce stade** — pas de code, pas de fichier
préparatoire, pas de branche annexe.

Le plan peut se raffiner à deux avant d'être soumis.

### Une PR ou plusieurs — ça se tranche ici

Si le plan laisse prévoir un diff au-delà de **400 lignes ou 15 fichiers**
porteurs de logique, charger **`slash:decoupage-pr`** et faire arbitrer le
découpage **dans le même plan** que l'approche.

Découper maintenant coûte le choix d'un ordre d'implémentation. Découper à
l'étape 7 coûte des cherry-picks et des rebases sur du code déjà écrit : c'est le
même travail à dix fois le prix. Un lot arbitré ici fixe aussi l'ordre des
commits, ce qui rend le découpage des branches mécanique le moment venu.

## Étape 3 — Implémentation et vérification

Implémenter le plan validé, rien de plus. Un écart au plan se signale, il ne se
décide pas en cours de route.

Vérifier soi-même dans le navigateur, sur le parcours exact du script
d'observation : le constat doit avoir disparu. Un test vert ne remplace pas cette
vérification.

Lancer les tests et le lint **pertinents** — ciblés sur ce qui est touché, pas la
suite complète si ce n'est pas nécessaire.

Les captures vont dans le scratchpad. `gh` ne sait pas uploader d'image sur
GitHub : elles ne peuvent pas atterrir seules dans la description de PR. Dire où
elles sont pour que l'utilisateur les colle s'il le souhaite, ou les attacher au
ticket Linear. Ne pas promettre une PR illustrée qu'on ne peut pas produire.

**Rapport** : ce qui a été fait, ce qui a résisté, les écarts au plan. Puis la
question : faut-il remettre le jeu de données en état pour constater la
résolution ?

## Étape 4 — Constat de la résolution (point d'arrêt bloquant)

Appeler **`slash:constat`** en mode « après ». Il rejoue le script à l'identique
et reprend les critères d'acceptation un par un, avec l'utilisateur aux
commandes — c'est lui qui devra affirmer en review que ça marche.

Attendre sa validation explicite **avant de committer**.

## Étape 5 — Commits

Découper les commits **par intention** : le correctif d'un côté, un renommage ou
un déplacement de l'autre. Un commit qui mélange les deux est illisible en
`git blame`.

**Dans slash-interim, passer par `slash-commit`** — gitmoji, référence SLI, mode
découpage, et il ne stage jamais rien sans demander. Il impose un **titre seul,
sans corps** : `slash:redaction` ne s'applique donc pas aux messages de commit de
ce dépôt.

Ne pas committer les artefacts de recette : scripts de seed jetables, captures,
fichiers du scratchpad.

## Étape 6 — Remise à jour sur la branche de base

Les commits faits, et **avant toute PR**, remettre la branche à jour sur
`develop` avec la commande **`/slash-rebase`** du dépôt slash-interim.

C'est une **commande**, pas un skill : elle ne se déclenche jamais toute seule,
il faut l'appeler. C'est précisément pour ça que cette étape existe en dur dans
le parcours.

Ce qu'elle apporte et qu'on ne peut pas obtenir autrement : **elle contrôle
l'ordre des migrations TypeORM.** Quand `develop` a ramené une migration
au timestamp plus récent que celle de la branche, celle de la branche se retrouve
avant elle dans l'ordre d'exécution, et la CI sort rouge sur
`handle-migrations.sh`. **Ce cas ne se voit pas dans le diff** — le fichier de
migration est intact, seul un ordre relatif a bougé. Ni la self-review, ni le
relecteur, ni les tests locaux ne l'attrapent.

Trois points de vigilance :

- **rebaser avant d'ouvrir la PR, jamais après.** `/slash-rebase` finit sur un
  `git push --force-with-lease` ; un force-push sur une PR déjà relue replie les
  commentaires ancrés en *outdated* ;
- **rebaser avant de découper en plusieurs branches.** Le re-timestampage d'une
  migration amende l'historique (`--fixup` puis `--autosquash`) : fait après le
  découpage, il faut le refaire dans chaque branche de la pile ;
- **si le rebase ramène un changement de `develop` dans la zone touchée**, le
  constat de résolution validé à l'étape 4 ne vaut plus tout à fait. Le dire, et
  rejouer le script d'observation si le conflit était réel — pas si le rebase
  s'est déroulé sans toucher au périmètre.

`/slash-rebase` s'arrête d'elle-même avant le push et rend la main. Ne pas la
court-circuiter en rebasant à la main : elle porte la parade au *racy git* en
conteneur et le backup préalable.

## Étape 7 — Ouverture de la PR

**Passer par `slash-create-pr`**, jamais un `gh pr create` monté à la main : il
extrait le SLI de la branche, remplit le template, choisit le magic word Linear
(`Close`, `Part of`, `Ref`), pousse et ouvre la PR en draft. C'est un skill du
dépôt slash-interim, et on ne le court-circuite pas.

### Re-vérifier le volume avant d'ouvrir la PR

Mesurer le diff réel avant d'appeler `slash-create-pr`. La branche de base se
déduit, elle ne s'écrit pas en dur — `slash-interim` est sur `develop` et n'a
**pas** de `main` :

```bash
BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')
git diff "$BASE"...HEAD --shortstat -- . \
  ':(exclude)*.lock' ':(exclude)**/*.snap' ':(exclude)**/migrations/**' \
  ':(exclude)**/locales/**' ':(exclude)**/*.generated.*' ':(exclude)**/generated/**'
```

Au-delà de **400 lignes ou 15 fichiers**, charger **`slash:decoupage-pr`**. Si le
découpage a déjà été arbitré à l'étape 2, il ne reste que sa mécanique à dérouler ;
sinon c'est un rattrapage, et il faut le dire comme tel. Le découpage vient
**après** le rebase de l'étape 6, jamais avant.

Un dépassement ne se contourne pas en silence : soit on découpe, soit
l'utilisateur assume une PR unique en connaissance de cause.

**La description part du fichier d'observation**, pas du diff. Les cinq lignes de
POURQUOI écrites à l'étape 1, avec ses mots, sont très exactement ce que
`slash:redaction` réclame et que personne ne sait reconstituer deux jours plus
tard en relisant un diff. Charger `slash:redaction` **avant** de rédiger.

Là où les deux se croisent, `slash-create-pr` donne la structure et la mécanique,
`slash:redaction` la façon d'écrire — une description qui remplit
consciencieusement le template en recopiant le diff n'est pas conforme pour
autant. En particulier, l'étape 6 de `slash-create-pr`, qui réclame un diagramme
mermaid et une description « aussi claire et informative que possible », **ne
s'applique pas** : c'est `slash:redaction` qui tranche, 150 à 250 mots en prose.

Dans slash-web, qui n'a pas ces skills de dépôt, la PR se crée à la main et
`slash:redaction` gouverne seul.

Enfin, vérifier que la référence Linear figure bien dans la description — c'est ce
qui referme le ticket.
