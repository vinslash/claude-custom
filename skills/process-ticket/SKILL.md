---
name: process-ticket
disable-model-invocation: true
description: >
  Parcours **optionnel**, lancé seulement à la main, de traitement d'un ticket
  Linear SLI dans un worktree slash-interim ou slash-web, du worktree déjà créé
  jusqu'à la PR ouverte. Dans slash-interim, le parcours par défaut est
  `slash-develop-ticket`, du dépôt : celui-ci n'en est que l'alternative
  accompagnée, pour un ticket qu'on veut constater et défendre soi-même. Impose
  l'ordre qui compte : faire CONSTATER le problème à l'utilisateur avant
  d'écrire une ligne, faire arbitrer le plan, implémenter, faire constater la
  résolution, committer, remettre la branche à jour sur `develop`, puis ouvrir
  la PR. Deux points d'arrêt bloquants — la validation du plan, passée par le
  mode plan, et la validation de la résolution. Délègue la compréhension et le
  constat à `slash:observe`, le jeu de données à `slash:case-dataset`, les
  commits, la remise à jour et la PR aux outils du dépôt slash-interim
  (`slash-create-commit`, `/slash-rebase-branch`, `slash-create-pr`), et le
  contenu rédigé des écrits GitHub à `slash:writing`.
  Invoked only through `/slash:process-ticket SLI-XXXX`.
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
internes de `slash:observe` ou `slash:case-dataset` n'y entrent pas, elles
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

Ne pas charger `slash:writing` pour ces rapports : il exclut explicitement la
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

Appeler **`slash:observe`** en mode « avant ». Il possède tout le bloc «
comprendre » : la lecture du ticket — **la seule de tout le parcours**, ne pas
la refaire ensuite —, la localisation du code, l'appel à `slash:case-dataset`
si le cas manque en base, la phase où l'utilisateur reproduit le problème de ses
propres mains, et la répétition des challenges du PM et des reviewers.

Il produit un fichier d'observation : le POURQUOI du ticket avec les mots de
l'utilisateur, les questions restées ouvertes, et le script de rejeu. **Ce fichier
voyage jusqu'à la dernière étape** — c'est de lui que sortira la description de
PR, et non du diff.

`slash:observe` porte deux portes qui peuvent terminer l'étape sans passer à la
suivante : celle de l'anti-overkill, et celle du **ticket périmé** — produit qui a
bougé depuis la rédaction, comportement qui ne se reproduit pas ou se reproduit
autrement. La seconde est **bloquante** : le parcours s'arrête jusqu'à ce que le
PM confirme ou réaligne. Ne pas enchaîner sur l'étape 2 en attendant, et ne pas
réinterpréter le ticket pour le rendre implémentable.

## Étape 2 — Plan et arbitrage (point d'arrêt bloquant)

Proposer un plan : l'approche retenue et pourquoi, les fichiers concernés, les
effets de bord attendus, ce qu'on laisse volontairement de côté. Une alternative
ne se présente que si le choix change quelque chose pour l'utilisateur ; sinon,
recommander et avancer.

**Charger `slash:writing` avant de rédiger le plan.** Un plan est un livrable
long relu par un humain, et c'est ce skill qui en porte la forme : 200 lignes au
plus, la passe d'élagage avant de soumettre, pas de plaidoirie sur des décisions
que personne ne conteste, et le hors-périmètre réduit à une ligne de renvoi.
L'analyse coûteuse qui n'entre pas dans le plan ne se perd pas pour autant : elle
part en commentaire du ticket Linear, dans les 250 mots.

**Charger `slash-guideline-backend-ddd` avant de rédiger**, dès que le ticket
touche `backend/src/` : ports, mappers, entité ou value-object se décident dans le
plan, et à l'étape 3 c'est figé. Nominalement auto-déclenché, il ne part pas tout
seul au milieu d'une étape de dizaines d'appels d'outils — d'où le nommage en dur.

**Passer par le mode plan** et soumettre via `ExitPlanMode`. C'est une vraie
porte d'approbation : elle ne se franchit pas sur un « ok » qui répondait à autre
chose. **Ne rien écrire dans le dépôt à ce stade** — pas de code, pas de fichier
préparatoire, pas de branche annexe.

Le plan peut se raffiner à deux avant d'être soumis.

### La forme du code s'énonce dans le plan

Sur tout ticket qui touche `backend/src/`, le plan dit en **trois à cinq lignes** :
arbo plate ou SDDD — `ARCHITECTURE.md` §2 laisse la distinction « à trancher au cas
par cas » sans nommer d'arbitre —, use-case ou application service, ports, entité
ou value-object, et **le fichier existant sur lequel chacun est calqué**.

Ce dernier point décide du reste : 62 % des fichiers créés naissent dans un dossier
qui n'existait pas, donc c'est la référence imitée qui fait la forme — et
`cooperation/`, que le guide SDDD donne pour modèle, injecte un repository
service dans son controller, ce que le même skill interdit ailleurs. Nommer le
modèle rend le choix arbitrable en dix secondes ; le taire le laisse surgir en
review, sur du code déjà écrit.

### Ce que la PR va livrer — ça se tranche ici

Lire **`../pr-scope/SKILL.md`** (le skill `slash:pr-scope`, qui ne se charge
qu'à la main : le lire comme un fichier) et faire arbitrer **dans le même plan** que l'approche
ce que la PR livrera de **constatable** : ce qu'on pourra mettre devant
quelqu'un, et montrer.

La taille n'entre pas dans cette décision — une PR qui livre une fonctionnalité
entière est le cas nominal, et c'est la review qu'on découpe en blocs. Ce qui se
décide ici, c'est qu'il y ait quelque chose à constater. Un lot dont rien n'est
observable ne donne au relecteur aucune intention contre quoi juger, et la
relecture part dans le détail technique sans fin.

Le moment n'est pas indifférent : ici, le périmètre ne coûte que le choix d'un
ordre d'implémentation ; à l'étape 7 il coûterait des cherry-picks sur du code
déjà écrit. Il n'y a donc pas de rattrapage plus tard — ce qui est délimité ici
est ce qui part.

## Étape 3 — Implémentation et vérification

Implémenter le plan validé, rien de plus. Un écart au plan se signale, il ne se
décide pas en cours de route.

Vérifier soi-même dans le navigateur, sur le parcours exact du script
d'observation : le constat doit avoir disparu. Un test vert ne remplace pas cette
vérification.

Lancer les tests et le lint **pertinents** — ciblés sur ce qui est touché, pas la
suite complète si ce n'est pas nécessaire.

Puis, **depuis la racine du worktree**, le contrôle des red flags SDDD :

```bash
python3 <base-dir-du-skill>/scripts/red-flags-sddd.py
```

Il rejoue sur les fichiers back de la branche la table « Red flags » du guide
SDDD et les invariants de `.claude/rules/sddd-structure.md`, et
nomme lui-même ce qu'il trouve. Sortie non nulle : **traiter tout signalement avant
le rapport d'étape**. Un red flag non traité part en review, où il coûte un
aller-retour sur une décision de conception, donc sur du code déjà écrit. Il se
corrige, ou il s'assume en une ligne du rapport — jamais en silence.

Les captures vont dans le scratchpad, avec celle de l'écran fautif prise à
l'étape 1 : ce sont l'avant et l'après de la section « Preuve de test » de la PR.
`slash-create-pr` les joint avec `gh --attach` (gh ≥ 2.99) ; le navigateur, par
**`slash:github-screenshots`**, n'est plus que le repli.

**Rapport** : ce qui a été fait, ce qui a résisté, les écarts au plan. Puis la
question : faut-il remettre le jeu de données en état pour constater la
résolution ?

## Étape 4 — Constat de la résolution (point d'arrêt bloquant)

Appeler **`slash:observe`** en mode « après ». Il rejoue le script à l'identique
et reprend les critères d'acceptation un par un, avec l'utilisateur aux
commandes — c'est lui qui devra affirmer en review que ça marche.

Attendre sa validation explicite **avant de committer**.

## Étape 5 — Commits

Découper les commits **par intention** : le correctif d'un côté, un renommage ou
un déplacement de l'autre. Un commit qui mélange les deux est illisible en
`git blame`.

**Dans slash-interim, passer par `slash-create-commit`** — gitmoji, référence SLI,
découpage des gros diffs, et il ne stage jamais rien sans demander. Il impose un
**titre seul, sans corps ni `Co-Authored-By`** : `slash:writing` ne s'applique
donc pas aux messages de commit de ce dépôt.

Ne pas committer les artefacts de recette : scripts de seed jetables, captures,
fichiers du scratchpad.

## Étape 6 — Remise à jour sur la branche de base

Les commits faits, et **avant toute PR**, remettre la branche à jour sur
`develop` avec la commande **`/slash-rebase-branch`** du dépôt slash-interim.

C'est une **commande**, pas un skill : elle ne se déclenche jamais toute seule,
il faut l'appeler. C'est précisément pour ça que cette étape existe en dur dans
le parcours.

Ce qu'elle apporte et qu'un rebase à la main n'a pas : la parade au *racy git*
en conteneur, le backup préalable, et le **contrôle de l'ordre des migrations
TypeORM**. Quand `develop` a ramené une migration au timestamp plus récent que
celle de la branche, celle de la branche n'est plus la dernière exécutée, et un
`migration:revert` local déroulerait celle de `develop` à sa place. Le
déploiement ne s'en plaint plus depuis le passage en forward-only ; c'est le
poste de développement qui casse, et **ça ne se voit pas dans le diff**.

Deux points de vigilance :

- **rebaser avant d'ouvrir la PR, jamais après.** La commande s'arrête avant le
  push et propose un `git push --force-with-lease` ; un force-push sur une PR
  déjà relue replie les commentaires ancrés en *outdated* ;
- **si le rebase ramène un changement de `develop` dans la zone touchée**, le
  constat de résolution validé à l'étape 4 ne vaut plus tout à fait. Le dire, et
  rejouer le script d'observation si le conflit était réel — pas si le rebase
  s'est déroulé sans toucher au périmètre.

## Étape 7 — Ouverture de la PR

**Passer par `slash-create-pr`**, jamais un `gh pr create` monté à la main : il
extrait le SLI de la branche, calcule tout contre `origin/develop`, fait son
auto-revue cosmétique, pose les labels, remplit le template en pyramide, le fait
relire à contexte vierge, et ouvre la PR en draft. Le hook `pr-body-budget.sh`
du dépôt refuse toute description qui sort du cadre : **sa structure fait foi**,
`slash:writing` n'y ajoute aucune section.

Le périmètre a été arbitré à l'étape 2 et ne se rejoue pas ici. La seule chose à
vérifier est qu'il a tenu : si le lot n'a finalement rien de constatable, le dire
à l'utilisateur plutôt que de rattraper d'autorité sur une branche déjà écrite.

**La description part du fichier d'observation**, pas du diff. Les cinq lignes de
POURQUOI écrites à l'étape 1, avec ses mots, sont la matière de la section
« Description », qui en garde soixante mots : ce que le ticket et le diff ne
disent pas. Charger `slash:writing` **avant** de rédiger, pour la façon d'écrire.

Le **script de rejeu** du même fichier n'a pas de section dans le template de
slash-interim : la recette y vit dans le sous-ticket de tests, que
`slash-create-test-scenarios` rédige. Le lui donner comme matière plutôt que de
le laisser repartir du ticket. Les captures de l'étape 3 vont dans « Preuve de
test ».

Dans slash-web, qui n'a pas ces skills de dépôt, la PR se crée à la main et
`slash:writing` gouverne seul, section « Comment tester » comprise.

Proposer ensuite `/slash-review-code <n>` : c'est la revue du dépôt, par des
modèles tiers.
