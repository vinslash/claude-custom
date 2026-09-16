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
  Use when the user says « fais l'auto-review », « avant de soumettre la PR à
  review », « untel a fait la review, il faut traiter », « on m'a assigné à la
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

Deux appels, en parallèle, avant toute autre chose :

```bash
gh api user --jq .login
gh pr view --json number,title,author,isDraft,reviewDecision,reviews,headRefName
```

Sans argument, `gh pr view` résout la PR depuis la branche courante — vrai dans
le worktree de son propre ticket comme dans celui d'une PR sortie pour la
relire. Un numéro ou une URL en `$ARGUMENTS` prime sur cette résolution.

| Auteur de la PR | Reviews soumises | Mode |
| --- | --- | --- |
| moi, ou pas encore de PR | aucune d'un tiers | **1** — auto-review |
| moi | au moins une d'un tiers | **2** — traiter la review reçue |
| un collègue | aucune de moi | **3** — reviewer |
| un collègue | au moins une de moi | **4** — vérifier les corrections |

Deux règles ferment le reste :

- **la phrase de l'utilisateur prime sur la détection.** Une auto-review demandée
  sur une PR déjà commentée est un mode 1, pas un mode 2 ;
- **le mode déduit s'annonce en une ligne**, avec ce qui l'a décidé. Une
  détection muette qui se trompe fait perdre toute la passe.

Pas de PR du tout — l'auto-review précède l'étape 7 de `slash:process-ticket` —
c'est le mode 1, et le périmètre se lit sur `origin/$BASE...HEAD`, où
`BASE=$(git symbolic-ref --short refs/remotes/origin/HEAD | sed 's|^origin/||')`.
Viser `origin/$BASE` et jamais `$BASE` nu : dans un worktree, le nom nu désigne
une ref figée au dernier `pull` fait dans le checkout principal.

## La porte anti-overkill

Avant de s'engager, trois questions. Dès qu'une réponse coupe, on s'arrête et on
rend la main en trois lignes.

1. **Y a-t-il quelque chose à juger ?** Un renommage mécanique, une montée de
   version, un fichier généré : la CI en dit plus que nous.
2. **Y a-t-il quelque chose à traiter ?** En mode 2 et 4, si aucun thread n'est
   ouvert avec un dernier message de l'autre partie, il n'y a pas de passe à
   jouer — le dire plutôt qu'inventer du travail.
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
une seconde passe ne rejoue que ce que les corrections touchent.

| Mode | Ce qu'on fait du script |
| --- | --- |
| **1** — auto-review | On ne le rejoue pas : l'étape 4 de `slash:process-ticket` vient de le dérouler. On vérifie qu'il est **jouable par un tiers** — prérequis, jeu de données, point d'entrée, attendu à chaque étape. Absent ou illisible, ce n'est pas une remarque : la PR n'est pas prête à être soumise. |
| **2** — traiter la review | On rejoue **les étapes que les corrections touchent**, avant de pousser. Une correction de review défait le constat aussi bien qu'un rebase, et personne ne le rejouera après. |
| **3** — reviewer | On le déroule **en entier, avant d'ouvrir le diff**. |
| **4** — vérifier | On rejoue **les étapes visées par les remarques bloquantes** du premier tour, et rien de plus. |

Le navigateur est celui du serveur MCP `chrome`, une instance dédiée au
worktree : charger **`slash:chrome-isolation`** avant la première action. La forme
du script, elle, ne se discute pas ici — c'est `slash:writing` qui la porte.

**Ce que la CI dit déjà, la review ne le dit pas.** Lint, typage, tests, red
flags SDDD : une remarque humaine sur du formatage est du crédit dépensé là où un
script est meilleur que nous. Les contrôles mécaniques se **lancent** au début des
modes 1 et 3, et ce qu'ils sortent se traite selon qui possède le code — sur la
sienne, ça se corrige ou s'assume avant de soumettre, et ça ne se présente pas ;
sur celle d'un collègue, c'est au contraire la remarque la plus solide de toutes,
puisqu'elle cite une règle du dépôt et non un goût.

**Chaque remarque porte un poids** — bloquant, suggestion, nit. Sans lui, tout est
traité au même niveau.

**Chaque remarque porte problème → conséquence → proposition.** Sans la
conséquence, l'auteur ne sait pas s'il doit corriger ; sans la proposition, il ne
sait pas par quoi remplacer. C'est `slash:writing` qui gouverne le texte, et il
se charge **avant** de rédiger quoi que ce soit qui parte sur GitHub.

**Une reco globale**, toujours, qui se traduit en un état GitHub : commenter,
demander des changements, approuver.

**Rien ne part sans arbitrage.** Ni une réponse, ni une remarque, ni une
approbation. C'est le point de ce skill.

**On ne modifie jamais le code d'une PR qu'on relit.** En mode 3 et 4, le worktree
porte la branche d'un collègue : on lit, on lance, on constate. Aucune écriture,
aucun commit, aucun push.

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

---

## Mode 1 — L'auto-review, avant de soumettre

Ce qu'on cherche : ce que le relecteur va demander, pour qu'il n'ait pas à le
demander.

1. **Lancer les contrôles mécaniques** sur la branche — lint et typage ciblés sur
   ce qui est touché, et le contrôle des red flags SDDD si le diff touche
   `backend/src/` — `python3 <base-dir de ce skill>/../process-ticket/scripts/red-flags-sddd.py`,
   depuis la racine du worktree. Ce qu'ils sortent se corrige, il ne se présente pas.
2. **Relire le diff contre le ticket**, pas contre un idéal : un critère
   d'acceptation non couvert, un cas limite du ticket oublié, un effet de bord
   hors périmètre qui a été livré quand même.
3. **Vérifier que la PR est relisible** : le script « Comment tester » est jouable
   par un tiers — voir plus haut —, les captures avant/après sont là si l'UI
   bouge, le lien Linear referme le ticket. C'est `slash:writing` qui porte ces
   trois exigences ; une PR qui les rate se fera retoquer avant même la lecture
   du code. Si la PR n'est
   pas encore ouverte, le point tient quand même : c'est ce qu'il restera à
   écrire, et l'étape 7 de `slash:process-ticket` s'en charge.

Rien n'est posté. Le livrable est le tableau, la reco globale — soumettre, ou
corriger d'abord —, et les corrections appliquées après ton arbitrage.

## Mode 2 — Traiter la review reçue

1. **Lire tous les threads**, résolus compris : un débat déjà tranché ne se
   rouvre pas.
2. **Ne retenir que les threads ouverts dont le dernier message vient du
   relecteur.** Un thread `isOutdated` se vérifie sur le code actuel avant d'être
   traité — la remarque peut être tombée toute seule.
3. **Pour chaque thread, une position** : corrigé, corrigé autrement, ou assumé.
   « Assumé » est une réponse légitime et fréquente — un choix volontaire se
   défend, il ne se plie pas par politesse.
4. **Appliquer les corrections** dans le code, groupées par intention, puis
   **rejouer les étapes du script que ces corrections touchent**. Une correction
   faite pour satisfaire un relecteur peut casser ce qu'un autre a validé.
5. **Présenter le tableau** : un thread par ligne, la position, et la réponse
   proposée en une ou deux phrases.

Après arbitrage : committer (`slash-commit`), pousser, puis poster les réponses
retenues et résoudre les threads traités. Un thread dont la réponse n'a pas été
retenue reste ouvert — et on dit lesquels.

Les réponses partent **sous ton nom**, sans préfixe ni signature d'agent : tu les
as arbitrées, elles sont de toi.

## Mode 3 — Reviewer la PR d'un collègue

**Commencer par recetter, pas par lire le diff.** Le worktree porte déjà sa
branche : dérouler le script en entier, et noter à chaque étape l'écart entre
l'attendu annoncé et ce qu'on voit. Un écart est une remarque en soi, et la plus
solide de toutes — elle ne se discute pas.

Absence de « Comment tester », ou script qui ne se déroule pas : c'est la
première remarque, elle est bloquante, et elle se pose **tout de suite** plutôt
qu'à la fin. On ne relit pas le code d'une PR dont personne ne peut vérifier
l'effet, et l'auteur peut réparer ça pendant qu'on lit.

Puis, dans cet ordre :

1. **Les contrôles mécaniques**, comme en mode 1 — ce qu'ils sortent est une
   remarque solide, ancrée sur une règle du dépôt et non sur un goût.
2. **Le ticket contre la PR** : ce que le ticket demande est-il livré, entier, et
   rien d'autre ?
3. **Le code** : correction sur les cas limites, régression sur l'existant,
   décision de conception qui coûtera cher à défaire. Pas le style.

Livrable : le tableau et la reco globale. Après arbitrage, la review part d'un
bloc — remarques ancrées aux lignes et état de review dans le même envoi.

## Mode 4 — Vérifier les corrections

**Ne juger que ce que la première passe a demandé.** C'est la règle du skill, et
c'est ici qu'elle s'applique le plus littéralement.

**Rejouer avant de juger sur pièces.** Les étapes du script visées par les
remarques bloquantes du premier tour, et elles seules : un thread peut être
répondu correctement et la correction ne pas marcher. Si les corrections ont
changé le script lui-même, c'est le nouveau qu'on déroule.

Puis reprendre les threads ouverts par nous, un par un, et leur donner un
verdict :

| Verdict | Ce qu'on en fait |
| --- | --- |
| **traité** | résoudre le thread |
| **traité autrement, et c'est recevable** | résoudre, en le disant en une phrase |
| **pas traité**, ou la réponse ne répond pas | laisser ouvert, relancer sur ce point précis |

Ce qu'on découvre en relisant et qui n'était pas demandé au premier tour ne
devient une remarque que s'il est **bloquant** — une régression, un bug sur le cas
nominal. Tout le reste est un ticket, et se dit en une ligne.

Reco globale : approuver si le rejeu passe, qu'aucun verdict n'est « pas traité »
et qu'aucun bloquant n'est apparu. Sinon, demander des changements sur les seuls
points qui restent.

## La capitalisation, en modes 2 et 4 seulement

Une remarque qu'un humain a attrapée et qu'un script aurait dû attraper est le
seul vrai signal pour faire évoluer les guidelines. C'est ce qu'on capitalise, et
rien d'autre : nos propres remarques des modes 1 et 3 n'ont pas cette valeur de
preuve — personne ne les a validées.

Verser ces cas dans `.claude/review-patterns/<slug-branche>.md`, au format que
`slash-process-review-patterns` consomme. Si rien n'est généralisable, ne pas
créer le fichier : un pattern creux coûte plus cher que pas de pattern.

En mode 2, le fichier part avec la branche, dans les commits de la PR. En mode 4,
il n'y a pas de branche à nous : l'écrire dans le **clone principal du dépôt**, pas
dans le worktree de relecture, et le laisser non committé — l'utilisateur le
versera avec son prochain ticket. Rien ne s'écrit jamais sur la branche d'un
collègue, fichier de patterns compris.

## Ce que ce skill ne fait pas

- Il ne rédige pas la description de la PR — c'est `slash:writing`.
- Il ne pousse pas et ne merge pas une PR qu'il relit.
- Il ne rejoue pas le périmètre de la PR : arbitré à l'analyse par
  `slash:pr-scope`, il ne se rattrape pas sur une branche déjà écrite.
- Il ne remplace pas `slash-review-plan`, qui audite un plan avant le code.
