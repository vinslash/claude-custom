---
name: constat
description: >
  Fait CONSTATER un ticket SLI à l'utilisateur lui-même, plutôt que de lui
  rapporter un constat. Deux modes : « avant », qui explique le ticket côté
  métier, le lui fait reproduire de ses propres mains dans le navigateur et
  répète avec lui les
  challenges du PM et des reviewers ; « après », qui rejoue le même script critère
  par critère pour vérifier la résolution. Le mode se déduit de l'existence du
  fichier d'observation. Produit le POURQUOI du ticket avec ses mots — la
  matière première de la description de PR — la liste des questions à poser au PM,
  et un script de rejeu. Délègue le jeu de données à `slash:recette-dataset` et la
  localisation du code à un sous-agent d'exploration.
  Use when the user says « fais-moi constater », « explique-moi le ticket »,
  « je veux comprendre SLI-XXXX », « montre-moi le problème », « on vérifie la
  résolution », or `/slash:constat SLI-XXXX`; and as the first step of
  `slash:process-ticket`. Utile aussi hors parcours : avant un affinage, quand un
  PM challenge un ticket, avant de relire la PR d'un collègue. Ne PAS utiliser
  pour fabriquer des données (→ `slash:recette-dataset`), pour implémenter, ni
  pour un ticket sans rien d'observable.
---

# Constater le ticket, à deux

## Pourquoi ce skill existe

Le réflexe d'un agent est de lire le ticket, aller voir, et rapporter.
L'utilisateur lit le rapport, dit « ok », et se retrouve deux jours plus tard
face à un PM ou à un reviewer sans modèle mental du problème. Lire un bon rapport
donne l'illusion de
comprendre ; un point d'arrêt qu'on franchit en lisant un rapport finit tamponné.

Ce skill inverse la manœuvre : **l'agent prépare le terrain, l'utilisateur
manipule.** La différence entre regarder et faire est exactement la différence
entre « il y avait un truc sur les avenants » et pouvoir répondre à une
objection.

Corollaire : ce qui sort d'ici n'est pas un compte rendu de l'agent, c'est **la
compréhension de l'utilisateur, écrite avec ses mots**. C'est aussi ce que
`slash:redaction` réclamera à l'heure de la PR — le POURQUOI que le diff ne dit
pas — et qu'on ne sait plus reconstituer après coup à partir du diff.

## Quel mode

Le fichier d'observation est `<scratchpad de session>/SLI-XXXX-OBSERVATION.md`.

- absent → **mode avant** ;
- présent → **mode après**.

**Annoncer le mode déduit en une ligne** et laisser l'utilisateur le corriger.
Ne jamais le deviner en silence.

---

# Mode « avant »

## 1. Comprendre, sans rien montrer encore

Lire le ticket **une seule fois mais à fond** — description, commentaires, liens
(Sentry, PR précédente, capture, document) réellement ouverts. C'est la seule
lecture du ticket de tout le parcours : `slash:recette-dataset` et
`slash:process-ticket` s'appuient sur celle-ci, ne pas les laisser recommencer.

Localiser le code concerné **via un sous-agent d'exploration**, qui rend la
conclusion sans ramener les fichiers dans la conversation — elle doit rester
disponible pour la partie didactique.

Chercher aussi **pourquoi le comportement actuel existe** : un `git log -S` ou un
`git blame` sur la ligne fautive sort souvent la PR d'origine et son intention.
C'est ce qui distingue « c'est un bug » de « c'était voulu, dans un contexte qui
a changé » — et c'est la première chose qu'un reviewer demandera.

## 2. La porte anti-overkill

Trois questions, avant d'engager quoi que ce soit :

1. **Y a-t-il quelque chose d'observable ?** Non (refactor, renommage, migration
   de typage) → pas de phase didactique. Dire ce que fait le ticket en trois
   lignes et rendre la main.
2. **L'utilisateur connaît-il déjà cette zone du produit ?** S'il la pratique
   tous les jours, la partie métier se réduit à ce qui est nouveau.
3. **Un challenge est-il probable ?** Un ticket qui change une règle de gestion,
   un montant, un droit d'accès ou un comportement visible client en attirera
   un ; une correction d'affichage, non.

Calibrer la profondeur là-dessus, et **le dire** : « ticket simple, je te montre
en deux minutes » est une réponse légitime. Un skill qui impose quinze minutes de
socratisme sur un libellé mal orthographié se fait contourner, et un skill
contourné ne sert plus à rien.

## 3. Les données

Juger si le cas est dans la base clonée. S'il manque, appeler
**`slash:recette-dataset`**, qui s'arrêtera une fois le cas visible à l'écran :
la baseline se constate ici, avec l'utilisateur.

Il signale aussi les critères qui dépendent d'un service externe non mocké. Si le
constat en dépend, le remonter tout de suite.

## 4. La phase didactique

Le navigateur est celui du serveur MCP `chrome` : une instance dédiée au
worktree, que l'utilisateur voit et dans laquelle il peut cliquer. Charger
`slash:chrome-ancrage` avant la première action.

Quatre règles, dans cet ordre.

**Prédire avant de voir.** Avant d'ouvrir l'écran, poser une question fermée sur
ce qu'il va montrer — « à ton avis, la liste affiche zéro ligne ou trois ? » —
via `AskUserQuestion`. Se tromper est ce qui fixe le souvenir ; se faire raconter
la réponse ne fixe rien.

**Laisser l'utilisateur manipuler.** Naviguer jusqu'à la page — ça, c'est de
l'intendance — puis **rendre le clavier**. Donner l'étape suivante en une phrase
et attendre ce qu'il observe. Ne pas cliquer à sa place, ne pas décrire ce qu'il
va voir avant qu'il l'ait vu.

**Expliquer le métier, pas le code.** Un PM ne demande jamais quelle méthode de
repository. Il demande qui est impacté, ce qu'il advient de l'existant, pourquoi
ça marchait comme ça avant. C'est ce registre-là qu'il faut tenir.

**Marquer la confiance.** Séparer explicitement ce qui est **lu dans le code**
(fait), ce qui est **déduit** (hypothèse), et ce qui reste **inconnu** (question
pour le PM). Un agent qui enseigne un modèle métier faux est pire qu'un agent
muet : l'utilisateur le répétera. La liste des inconnues est un livrable —
arriver chez le PM avec trois questions précises, c'est exactement l'objectif.

## 5. La répétition du challenge

Faire jouer le PM puis le reviewer par un **sous-agent naïf**, qui ne reçoit que
le texte du ticket et les quelques lignes d'explication de l'utilisateur —
**pas** le code, pas l'analyse. C'est la condition pour qu'il challenge comme
quelqu'un qui n'a pas lu le code, c'est-à-dire comme le vrai PM. Un agent qui
sait tout pose des questions d'initié.

Trois questions suffisent. Celles auxquelles l'utilisateur ne sait pas répondre
sont les trous à combler — repérés avant qu'une ligne soit écrite, quand c'est
encore gratuit.

## 6. Ce qu'on écrit

`<scratchpad>/SLI-XXXX-OBSERVATION.md`, court :

- **Le POURQUOI, cinq lignes, avec ses mots** : ce que ça change, pour
  qui, pourquoi c'était comme ça. Le lui faire formuler plutôt que le rédiger à
  sa place — c'est le test de la compréhension, et c'est la matière de la PR.
- **Les questions pour le PM**, telles quelles.
- **Le script de rejeu** : URL exacte, étapes, ce qu'on observe aujourd'hui, ce
  qu'on devra observer après. C'est lui qui sera rejoué en mode « après », puis
  recopié tel quel dans la section « Recettage » de la PR — l'écrire déjà comme
  des étapes numérotées avec leur attendu.
- **Ce qui n'est pas validable localement**, s'il y en a.

---

# Mode « après »

Rejouer le script d'observation **à l'identique**, dans le même ordre, sur le
même écran — c'est ce qui rend les deux états comparables.

Puis reprendre **les critères d'acceptation un par un** : chacun est constaté,
ou il ne l'est pas et on le dit. Un critère bloqué par un service externe reste
bloqué, il ne devient pas vert parce que le reste fonctionne.

Là encore, c'est l'utilisateur qui manipule : c'est lui qui devra affirmer en
review que ça marche.

Si un écart apparaît, **ne pas le réparer en passant**. Le décrire et rendre la
main : la correction relève de l'étape d'implémentation, pas d'ici.

---

## Erreurs à ne pas commettre

- **Faire le constat à sa place** puis le lui résumer : c'est le comportement que
  ce skill existe pour remplacer.
- Relire le ticket une deuxième fois parce qu'un autre skill l'a déjà lu, ou
  laisser un autre skill le relire après nous.
- Dérouler la phase didactique sur un ticket qui ne la mérite pas.
- Présenter une déduction comme un fait — surtout sur l'intention métier, où
  l'agent extrapole le plus.
- Donner au sous-agent qui joue le PM autre chose que le ticket et les mots de
  l'utilisateur.
- Enchaîner sur le plan ou l'implémentation : ce skill s'arrête au constat.
- Écrire le POURQUOI à la place de l'utilisateur.
