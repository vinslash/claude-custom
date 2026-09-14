---
name: scope
description: >
  Ce qu'une pull request doit embrasser pour être relisible : un lot
  **constatable** — quelque chose qu'on peut mettre devant quelqu'un et montrer
  que ça marche. Le critère n'est ni le volume ni le nombre de fichiers, c'est
  de pouvoir jouer un « après » sur le lot. Se tranche à l'analyse, où le
  périmètre ne coûte que le choix d'un ordre d'implémentation, et non après
  l'implémentation, où la même décision coûte des cherry-picks. Donne les
  frontières qui marchent, les cas qui ne livrent rien d'observable, et la
  branche de base déduite du remote plutôt que `main` codé en dur.
  Use at the analysis or planning step of a ticket, before any code is written —
  step 2 of `slash:process-ticket`; when the user says « qu'est-ce qu'on livre
  dans cette PR ? », « on met tout dans une seule PR ? », « par où on commence »,
  « est-ce que ça se constate », « ça se teste comment », or `/slash:scope`.
  Also before `gh pr create` when nothing in the branch can be demonstrated.
  Ne PAS utiliser pour découper les commits d'une PR (→ `slash-commit`), pour
  rédiger une description (→ `slash:redaction`), ni pour arbitrer la **taille**
  d'une PR : une grosse PR qui livre un lot constatable est le cas nominal, et
  ce skill n'a rien à en dire.
---

# Le périmètre d'une pull request

## Pourquoi ce skill existe

La taille d'une PR n'est plus le problème : l'équipe a arbitré qu'une PR livre
une fonctionnalité ou un correctif entier, et que c'est la **review** qu'on
découpe en blocs. Découper la livraison, elle, coûtait des rebases en cascade
pour un bénéfice que la review par blocs donne sans eux.

Ce qui reste un problème, et que ce skill ferme : **un lot qui ne livre rien
qu'on puisse mettre devant quelqu'un.** Le relecteur — humain ou Claude — n'a
alors aucune intention unique contre quoi juger, et la relecture part dans le
détail technique sans fin, faute de savoir ce qu'elle est censée valider.

## Le critère : la PR livre quelque chose de constatable

Une seule question, et elle se pose à l'analyse :

> **Peut-on jouer un « après » sur ce lot ?**

C'est-à-dire : ouvrir l'application, dérouler quelques étapes, et voir que ça
fait ce que le ticket promettait. Si on ne sait pas dire quoi aller regarder, le
périmètre est **mauvais** — pas trop gros, mauvais.

Ce critère est déjà le prérequis de deux autres skills, ce qui est la meilleure
preuve qu'il est le bon :

- `slash:constat` en mode « après » rejoue le script critère par critère. Il n'a
  aucune prise sur un lot dont rien n'est observable ;
- `slash:redaction` impose une section **« Comment tester »** sur toute PR. Un lot
  sans rien de constatable ne peut en produire que la forme dégénérée — celle qui
  dit pourquoi il n'y en a pas.

Donc : si la section « Comment tester » ne peut être qu'un aveu, c'est le
périmètre qu'il fallait revoir, à l'analyse, pas la description au moment de la
rédiger.

## Les cas qui ne livrent rien d'observable

Ils existent, et ils sont nommés à l'identique dans `slash:constat` et
`slash:recette-dataset` : **refactor pur, renommage, migration de typage.**

Là, les tests tiennent lieu de constat, et « Comment tester » le dit franchement
plutôt que de mimer un script. Deux conséquences :

- un tel lot part **seul**. Mélangé à une fonctionnalité, il noie ce qu'elle
  livre, et la review se met à parler du renommage ;
- une **régénération mécanique volumineuse** — Orval, swagger, snapshots — suit
  la même règle pour la même raison : illisible, et elle noie le reste.

## Où passent les frontières

Par défaut, **une seule PR** : le ticket livre une chose, elle se constate d'un
bloc. On ne sépare que si le ticket livre **deux choses constatables
distinctes** — ce qui est rare, et se voit à l'analyse ou jamais.

Quand c'est le cas, les frontières qui marchent, par ordre de rentabilité :

1. **le mécanique d'un côté, le pensé de l'autre** — un renommage, un
   déplacement de fichiers, une extraction sans changement de comportement ;
2. **la préparation avant l'usage** — la migration et son entité, le helper
   avant son appelant ;
3. **le producteur avant le consommateur** — le contrat d'API backend, puis
   l'écran frontend qui le consomme.

Ce qui ne fait **pas** une frontière : « backend / frontend » quand les deux
portent la même intention et se constatent ensemble — c'est même le contre-exemple
type, puisque séparés, aucun des deux ne se montre —, ni « les tests d'un côté ».

## Ça se tranche à l'analyse, pas après

Au moment du plan (**étape 2** de `slash:process-ticket`), le périmètre ne coûte
que le choix d'un ordre d'implémentation. Après l'implémentation, la même
décision coûte des cherry-picks, des rebases et une relecture de tout le diff
pour retrouver les frontières. **C'est le même travail à 10 % du prix.**

Il n'y a donc **pas de rattrapage à l'ouverture de la PR** : ce qui a été
délimité au plan est ce qui part. Si le lot s'avère ne rien livrer de
constatable, c'est une conversation à avoir avec l'utilisateur, pas un découpage
à faire d'autorité sur une branche déjà écrite.

## La branche de base n'est pas `main` partout

`slash-interim` a pour branche par défaut **`develop`** — et `main` n'y existe
pas, même pas sur le remote. `slash-web` est bien sur `main`. Un `main` écrit en
dur échoue donc sur un dépôt sur deux, avec un `fatal: bad revision`.

La déduire, une fois, et la réutiliser partout ensuite :

```bash
BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')
```

Si la commande ne renvoie rien (remote HEAD jamais résolu), `git remote set-head
origin --auto` puis retenter. En dernier recours, demander à l'utilisateur
plutôt que de parier sur `main`.

## Surcharge de `slash-create-pr`

Ce skill ne remplace pas `slash-create-pr`. On garde tout ce qu'il fait —
l'extraction du SLI depuis la branche, le titre tiré du ticket Linear, le
template du dépôt, `--body-file` plutôt qu'un heredoc, l'interdiction d'échapper
les backticks, le `--draft` et le `--assignee @me`. Deux substitutions :

| Chez `slash-create-pr` | Ici |
| --- | --- |
| `--base main` codé en dur (étape 4), et `git diff main...HEAD` à l'étape 1.6 | `$BASE` déduit du remote — `develop` sur slash-interim, où `main` n'existe pas |
| « intègre un diagramme mermaid », description « aussi claire et informative que possible » (étape 6) | **ne s'applique pas** — `slash:redaction` gouverne : 150 à 250 mots, en prose, pas de mermaid décoratif |

La première ligne n'est pas une préférence, c'est un **bug** de `slash-create-pr`
qui échoue sur slash-interim. Elle a vocation à remonter en PR sur le dépôt
d'équipe, et cette surcharge à disparaître avec.
