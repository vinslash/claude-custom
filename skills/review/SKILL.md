---
name: review
description: >
  Les quatre situations de review d'une pull request : l'auto-review avant de
  soumettre la sienne, le traitement de la review reçue, la review de la PR d'un
  collègue, et la seconde passe qui vérifie ses corrections. Le mode se **déduit**
  de l'état de la PR — auteur, reviews déjà soumises — sans rien demander. Impose
  ce qui fait qu'une review se termine : le périmètre du ticket et rien d'autre,
  un poids sur chaque remarque, une proposition attachée, une seconde passe qui ne
  juge que ce que la première a demandé, et une reco globale. Impose aussi que le
  **recettage précède la lecture du code** : le script « Comment tester » de la PR
  se déroule dans le navigateur avant d'ouvrir le diff, et une seconde passe n'en
  rejoue que les étapes que les corrections touchent. Rien n'est posté sur
  GitHub sans arbitrage de l'utilisateur, remarque par remarque. On ne modifie
  jamais le code d'une PR qu'on relit.
  Use when the user says « fais l'auto-review », « fais la self-review », « je
  relis ma PR avant de la soumettre », « avant de soumettre la PR à review », « untel a fait la review, il faut traiter », « on m'a assigné à la
  review de cette PR », « untel a traité nos retours », « on vérifie et on
  approuve », or `/slash:review`. Remplace `slash-pr-review` et
  `slash-review-code` du dépôt slash-interim sur ces quatre situations. Ne PAS
  utiliser pour rédiger une description de PR (→ `slash:writing`), pour traiter un
  ticket de bout en bout (→ `slash:process-ticket`), ni pour auditer un plan avant
  implémentation (→ `slash-review-plan`).
---

# La review d'une pull request

## Pourquoi ce skill existe

Une review qui ne finit pas coûte plus cher que le ticket qu'elle relit. Quatre
causes, toujours les mêmes :

- une remarque **hors périmètre** : l'auteur corrige, ça crée de la surface, ça
  crée des remarques ;
- une remarque **sans poids** : l'auteur traite une broutille au même niveau
  qu'un bug ;
- une remarque **sans proposition** : l'auteur devine, se trompe, et revient ;
- une **seconde passe qui rejuge tout** au lieu de juger ce qu'elle avait
  demandé. C'est la plus chère, parce qu'elle est sans fin par construction.

D'où la règle qui commande les quatre modes, et qui vaut dans les deux sens —
auteur comme relecteur :

> **Une seconde passe ne juge que ce que la première a demandé.**

Ce qu'on découvre au second tour et qui n'était pas demandé n'est pas une
remarque de cette PR. C'est un ticket.

## Le mode se déduit, il ne se demande pas

**Première action, avant toute autre**, depuis la racine du worktree :

```bash
python3 <base-dir de ce skill>/scripts/mode.py [PR]
```

Il interroge GitHub — qui tu es, qui a ouvert la PR, qui a déjà soumis une
review, quels threads attendent une réponse de toi —, en déduit le mode, et
**imprime les instructions de ce mode**. Il n'y a donc pas de fichier à aller
lire ensuite, et les trois modes qui ne servent pas ne coûtent rien.

Sans argument, la PR se résout depuis la branche courante : vrai dans le worktree
de son propre ticket comme dans celui d'une PR sortie pour la relire. Un numéro
ou une URL en `$ARGUMENTS` prime sur cette résolution.

**La phrase de l'utilisateur prime sur la détection.** Une auto-review demandée
sur une PR déjà commentée est un mode 1, pas un mode 2 : `--mode 1` le force, et
le script le dit dans son en-tête.

**Annoncer le mode déduit en une ligne**, avec ce qui l'a décidé — le script le
donne. Une détection muette qui se trompe fait perdre toute la passe.

## La porte anti-overkill

Le script répond à la deuxième question tout seul : en mode 2 et 4, il refuse de
sortir des instructions si aucun thread n'attend de réponse. Les deux autres se
posent avant de s'engager, et dès qu'une réponse coupe, on rend la main en trois
lignes.

1. **Y a-t-il quelque chose à juger ?** Un renommage mécanique, une montée de
   version, un fichier généré : la CI en dit plus que nous.
2. **Y a-t-il quelque chose à traiter ?** — tranché par le script.
3. **Le ticket est-il connu ?** Sans le POURQUOI du ticket, une review n'a
   aucune référence contre quoi juger et dérive vers le goût. Le lire avant.

## Ce qui ne change pas d'un mode à l'autre

**Le périmètre est le ticket.** Pas le code adjacent qu'on trouve laid, pas la
dette croisée en route. Ce qui est hors périmètre tient en **une ligne**, et
c'est l'utilisateur qui décide d'en faire un ticket.

**Le recettage précède la lecture du code.** La section « Comment tester » d'une
PR existe pour être déroulée : c'est le seul moment où quelqu'un vérifie que la
PR fait ce qu'elle annonce, et le relecteur assigné la joue avant d'ouvrir le
diff. Ce qu'on en fait dépend du mode, et suit la même règle que tout le reste —
une seconde passe ne rejoue que ce que les corrections touchent. Le navigateur
est celui du serveur MCP `chrome`, une instance dédiée au worktree : charger
**`slash:chrome-isolation`** avant la première action. La forme du script, elle,
ne se discute pas ici — c'est `slash:writing` qui la porte.

**Ce que la CI dit déjà, la review ne le dit pas.** Lint, typage, tests, red
flags SDDD : une remarque humaine sur du formatage est du crédit dépensé là où un
script est meilleur que nous. Les contrôles mécaniques se **lancent** au début
des modes 1 et 3 ; ce qu'ils sortent se traite selon qui possède le code, et
chaque mode le dit.

**Chaque remarque porte un poids** — bloquant, suggestion, nit. Sans lui, tout est
traité au même niveau.

**Chaque remarque porte problème → conséquence → proposition.** Sans la
conséquence, l'auteur ne sait pas s'il doit corriger ; sans la proposition, il ne
sait pas par quoi remplacer. C'est `slash:writing` qui gouverne le texte, et il
se charge **avant** de rédiger quoi que ce soit qui parte sur GitHub.

**Une reco globale**, toujours, qui se traduit en un état GitHub : commenter,
demander des changements, approuver. C'est l'`event` qui la porte, et GitHub
l'affiche en tête de la PR — donc **le corps de la review ne la répète pas**. Il
dit ce que ce verdict veut dire pour l'auteur : ce qui est sûr, ce qui ne l'est
pas, ce qu'il lui reste à faire. « Reco : approuver » en ouverture est le
vocabulaire du **tableau d'arbitrage**, celui qu'on soumet avant de publier, et
il n'a rien à faire dans le texte publié (paire annotée dans
`slash:writing`, `references/exemples.md`, PR 1110).

**Rien ne part sans arbitrage.** Ni une réponse, ni une remarque, ni une
approbation. C'est le point de ce skill.

**On ne modifie jamais le code d'une PR qu'on relit.** En mode 3 et 4, le worktree
porte la branche d'un collègue : on lit, on lance, on constate. Aucune écriture,
aucun commit, aucun push — fichier de review-patterns compris.

## L'arbitrage

Les remarques se présentent en **un seul tableau**, ordonné du plus lourd au plus
léger, jamais une par une :

```
| # | Poids      | Où                                  | La remarque |
| 1 | bloquant   | backend/src/…/foo.use-case.ts:42    | … en une phrase |
| 2 | suggestion | frontend/src/…/Bar.tsx:88           | … |
| 3 | nit        | …                                   | … |

Reco globale : demander des changements — 1 est un bug sur le cas nominal.
```

L'utilisateur amende **par exception** — « retire la 3, passe la 5 en nit » — et
ce qui n'est pas amendé est retenu. Le texte complet de chaque remarque ne
s'écrit qu'après l'arbitrage, sur les seules retenues.

**Une dizaine de remarques au plus.** Au-delà, la remarque à faire n'est plus sur
le code mais sur la nature de la PR, et c'est celle-là qu'on pose.

La mécanique `gh` — lire les threads, poster une review ancrée aux lignes,
répondre, résoudre, approuver — est dans `references/mecanique-gh.md`. La lire au
moment de publier, pas avant.

## Ce que ce skill ne fait pas

- Il ne rédige pas la description de la PR — c'est `slash:writing`.
- Il ne pousse pas et ne merge pas une PR qu'il relit.
- Il ne rejoue pas le périmètre de la PR : arbitré à l'analyse par
  `slash:pr-scope`, il ne se rattrape pas sur une branche déjà écrite.
- Il ne remplace pas `slash-review-plan`, qui audite un plan avant le code.
