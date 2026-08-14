---
name: decoupage-pr
description: >
  Garde-fou sur la taille des pull requests, et mécanique d'ouverture de
  plusieurs PR pour un même ticket SLI — en parallèle sur la branche de base, ou
  empilées quand l'une ne tient pas debout sans l'autre. Mesure le volume hors
  fichiers générés, tranche une PR ou plusieurs, place les magic words Linear (`Part of`
  sur toutes sauf la dernière, qui porte le `Close`), et surcharge
  `slash-create-pr` là où il code en dur `--base main` et pousse à une
  description exhaustive.
  Use when a branch diff exceeds ~400 changed lines or ~15 hand-written files;
  when the user says « ça va faire une grosse PR », « on découpe ? »,
  « plusieurs PR », « PR empilées », « stacked PR », « c'est trop gros pour une
  seule PR »; at the planning and finalisation steps of `slash:process-ticket`;
  and before any `gh pr create` on a branch that exceeds those thresholds.
  Ne PAS utiliser pour découper les commits d'une PR unique
  (→ `slash-commit`, mode découpage), pour rédiger le contenu d'une description
  (→ `slash:redaction`), ni pour une PR sous les seuils — une seule PR, et ce
  skill n'a rien à dire.
---

# Découpage d'un ticket en plusieurs pull requests

## Pourquoi ce skill existe

Une PR de 900 lignes n'est pas relue, elle est approuvée. Le reviewer survole,
fait confiance, et le vrai coût arrive plus tard — en prod, ou six mois après
dans un `git blame` illisible.

Le dispositif avait déjà deux garde-fous : `slash:redaction` borne la
**description**, `slash-commit` borne le **commit**. Personne ne bornait la
**PR** : trois commits bien découpés partaient dans une PR unique et énorme.
C'est le trou que ce skill ferme.

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

Dans tout ce qui suit, `$BASE` désigne cette branche.

## Mesurer avant de discuter

Le volume se mesure **hors fichiers générés** — un lockfile ou une
régénération Orval font exploser le compteur sans rien coûter au reviewer :

```bash
git diff "$BASE"...HEAD --shortstat -- . \
  ':(exclude)*.lock' \
  ':(exclude)**/*.snap' \
  ':(exclude)**/migrations/**' \
  ':(exclude)**/locales/**' \
  ':(exclude)**/*.generated.*' \
  ':(exclude)**/generated/**'
```

**Seuils d'arbitrage** : plus de **400 lignes** (ajoutées + supprimées) **ou**
plus de **15 fichiers** porteurs de logique. En dessous : une PR, ce skill
s'arrête ici, ne pas encombrer l'utilisateur d'une question rhétorique.

Deux corollaires :

- une **régénération mécanique volumineuse** (Orval, swagger, snapshots) part en
  PR séparée même si le reste tient sous les seuils — elle est illisible, et la
  mélanger noie le correctif ;
- les seuils sont un **déclencheur de conversation**, pas une loi. 500 lignes
  dont 400 sont un même pattern répété se relisent mieux que 200 lignes de
  logique dense. Le dire, et laisser l'utilisateur trancher.

## Le découpage se décide au plan, pas après

Au moment du plan (**étape 2** de `slash:process-ticket`), découper coûte le
choix d'un ordre d'implémentation. Après l'implémentation, ça coûte des
cherry-picks, des rebases et une relecture de tout le diff pour retrouver les
frontières. **C'est le même travail à 10 % du prix.**

Donc : dès que le plan laisse prévoir un dépassement des seuils, poser la
question dans le plan lui-même, et faire arbitrer en même temps que l'approche.
L'étape d'ouverture de la PR ne fait qu'une **re-vérification** sur le diff réel —
le découpage y est un rattrapage, pas le cas nominal.

## Rebaser d'abord, découper ensuite

Sur slash-interim, la branche doit être remise à jour sur `develop` **avant**
qu'on la découpe — c'est l'étape 6 de `slash:process-ticket`, via la commande
`/slash-rebase`.

L'ordre n'est pas indifférent : quand le rebase re-timestampe une migration
TypeORM, il **amende l'historique** (`--fixup` puis `--autosquash`). Fait après le
découpage, ce travail est à refaire dans chaque branche du lot. Et sur une pile,
chaque fusion amont impose un rebase de l'aval, donc un nouveau contrôle de
l'ordre des migrations à chaque étage — raison de plus pour garder les piles
courtes.

## Où passent les frontières

Une PR = **une intention, relisible et mergeable seule**. Pas un répertoire, pas
un quota de fichiers.

Les frontières qui marchent, par ordre de rentabilité :

1. **le mécanique d'un côté, le pensé de l'autre** — un renommage, un
   déplacement de fichiers, une extraction sans changement de comportement. 300
   lignes relues en deux minutes, si et seulement si elles sont seules ;
2. **la préparation avant l'usage** — la migration et son entité, le helper
   avant son appelant ;
3. **le producteur avant le consommateur** — le contrat d'API backend, puis
   l'écran frontend qui le consomme.

Ce qui ne fait **pas** une frontière : « backend / frontend » quand les deux
portent la même intention et se relisent ensemble, ni « les tests d'un côté »
— une PR de code sans ses tests est une PR incomplète.

## Parallèle ou empilé

**Par défaut : parallèle.** Chaque branche part de `$BASE`, chaque PR passe la CI
seule, l'ordre de merge est libre. L'empilement a un coût réel — un rebase à
chaque merge amont, un diff pollué par les commits de la PR précédente tant
qu'elle n'est pas fusionnée, et un ordre de merge imposé aux reviewers.

**Le test** : si la PR n°2 partait seule sur `$BASE`, est-ce qu'elle passe la CI ?

- **oui** → parallèle ;
- **non** (elle appelle un helper introduit par la n°1, consomme un champ créé
  par sa migration, importe un type qui n'existe pas encore) → **empilée**.

La mécanique d'empilement, le retargeting après merge et les pièges vérifiés
sont dans `references/empilement.md`, à lire **au moment où l'empilement est
retenu** — pas avant.

## Liaison Linear quand il y a plusieurs PR

`slash-create-pr` ne connaît que deux cas : une PR pour un ticket, ou plusieurs
tickets dans une PR. **Plusieurs PR pour un ticket n'existe pas chez lui** — il
mettrait `Close` partout, et la première PR fusionnée fermerait le ticket alors
que le travail est à moitié fait.

La règle :

- PR 1 à n−1 : `Part of [SLI-XXXX](url)` ;
- PR n, **celle qui sera fusionnée en dernier** : `Close [SLI-XXXX](url)`.

Si l'ordre de merge change en route, **déplacer le `Close`**. Un ticket resté
ouvert après la dernière fusion est un oubli visible ; un ticket fermé au milieu
du travail ne se voit pas.

Le titre porte l'ordinal, pour que la liste des PR se lise sans les ouvrir :

```
:recycle: SLI-1234 (1/3): extraire le calcul des heures dans un helper
:bug: SLI-1234 (2/3): corriger l'arrondi sur les semaines à cheval
:sparkles: SLI-1234 (3/3): afficher le total corrigé dans le récapitulatif
```

## Ce que chaque description doit dire de plus

`slash:redaction` gouverne le contenu et la longueur — **150 à 250 mots par PR,
pas par lot**. Ne pas recopier le POURQUOI complet dans les trois : la PR 1 le
porte, les suivantes y renvoient d'un lien.

Ce qui s'ajoute, et qui est exactement le genre de chose qu'un reviewer ne peut
pas deviner : **de quelle PR celle-ci dépend, et dans quel ordre merger.** Une
phrase, en tête de description :

```markdown
Part of [SLI-1234](https://linear.app/slash-interim/issue/SLI-1234)

Deuxième de trois. À merger après #4521, dont elle reprend le helper.
```

## Surcharge de `slash-create-pr`

Ce skill ne remplace pas `slash-create-pr` : il l'appelle **une fois par PR,
dans l'ordre**, avec des substitutions. Ce qu'on garde de lui, sans discuter :
l'extraction du SLI depuis la branche, le titre tiré du ticket Linear, le
template du dépôt, `--body-file` plutôt qu'un heredoc, l'interdiction
d'échapper les backticks, le `--draft` et le `--assignee @me`.

Ce qu'on lui substitue :

| Chez `slash-create-pr` | Ici |
| --- | --- |
| `--base main` codé en dur (étape 4), et `git diff main...HEAD` à l'étape 1.6 | `$BASE` déduit du remote — `develop` sur slash-interim, où `main` n'existe pas ; **la branche précédente** en empilé |
| `Close` par défaut (étape 3.5, scénario A) | `Part of` sauf la dernière PR |
| Titre `SLI-1234: sujet` | Titre `SLI-1234 (i/n): sujet` |
| « intègre un diagramme mermaid », description « aussi claire et informative que possible » (étape 6) | **ne s'applique pas** — `slash:redaction` gouverne : 150 à 250 mots, en prose, pas de mermaid décoratif |

Cette dernière ligne vaut aussi pour une PR unique : les deux skills se
contredisent, et c'est `slash:redaction` qui tranche.

Ces surcharges vivent ici, dans le plugin, et non dans `slash-create-pr` —
elles s'éprouvent avant d'être proposées au dépôt.
