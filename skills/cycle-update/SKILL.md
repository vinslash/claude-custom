---
name: cycle-update
description: >
  Les updates d'un projet Linear au fil du cycle : le **point d'étape** qui donne
  au produit sa vision d'ensemble, et l'**update de fin de cycle** qui le
  contient et y ajoute la passation, pour que le suivant reprenne le rôle sans
  repartir de zéro. Deux formes selon le **rôle** tenu — relevé de rôle sur le
  projet Run, project update sur le projet lui-même pour les rôles de Build. Le
  travail n'est pas d'écrire mais de **rassembler** : GitHub, #daily, Linear,
  incidents et releases. Confronte le réalisé aux **attendus** de la fiche du
  rôle plutôt que d'énumérer, et rédige la passation contre la checklist de prise
  de poste du suivant. Rien n'est posté sans validation explicite.
  **« sprint » vaut « cycle » partout** : l'équipe dit les deux.
  Use when the user says « update de fin de cycle », « point d'étape », « project
  update », « fais le point sur le projet », « je veux faire le point sur mon
  projet », « j'ai le lead sur ce projet ce cycle », « je passe la main sur le
  rôle », « la passation du rôle », « qu'est-ce que j'ai fait ce cycle ou ce
  sprint », « laisser une trace de où on en est », or `/slash:cycle-update`; and
  whenever someone who holds a cycle role or leads a project wants to report on
  it. Se déclencher **même si la demande se lit aussi comme « explique-moi où en
  est ce projet »** : la question d'entrée du skill lève l'ambiguïté en un clic,
  alors qu'un résumé rendu hors skill n'applique aucune de ses règles.
  Ne PAS utiliser pour écrire la **description** d'un projet Linear, pour rédiger
  un daily, ni pour traiter un ticket (→ `slash:process-ticket`).
---

# Les updates de cycle

## Pourquoi ce skill existe

Le rituel est déjà écrit — Fabien, dans #tech le 20/08. Un cycle plus tard, deux
projets sur trois avaient reçu leur update, un seul au format complet.

Les dix minutes annoncées sont sous-estimées : le coût n'est pas d'écrire, il est
de **se rappeler** deux semaines dont la moitié n'a laissé aucune trace dans un
ticket. C'est cette part-là que le skill enlève. Le vécu, la santé et les
arbitrages restent à celui qui a tenu le rôle, et le skill ne les invente pas.

**Les budgets sont le critère de réussite**, pas un vœu : 10 minutes pour une fin
de cycle, 3 pour un point d'étape, validation comprise. Au-delà, c'est la
collecte qu'on coupe.

## Deux moments, dont l'un contient l'autre

Le **point d'étape** répond exactement à ce que le produit demande — santé,
réalisé depuis le dernier update, arbitrages et alertes —, et rien de plus.
L'**update de fin de cycle** est ces trois points, plus la couche de passation.

Il n'est donc pas une corvée en plus : c'est la matière première de la passation,
et un cycle raconté au fil de l'eau réduit la collecte finale aux derniers jours.

**Aucune cadence n'est imposée** : il part à l'initiative de la personne. Le
skill répond, il ne convoque pas. Donc l'update de fin de cycle ne présume jamais
qu'il en existe.

Linear ne type pas les updates : la distinction vit en **première ligne**, sans
rien avant elle.

```
**Point d'étape — cycle 55**
**Fin de cycle 55 — passation du rôle Plateforme**
```

Ce n'est pas cosmétique — c'est ce qui permet de retrouver les points du mandat
courant, et d'éviter de prendre pour un bilan un update écrit par quelqu'un
d'autre sur un tout autre sujet.

## La forme se déduit du rôle

Pas de la nature du projet : de la colonne **Bloc** de la fiche du rôle.

| Rôle | Bloc | Où va l'update | Forme |
| --- | --- | --- | --- |
| Dev Customer value | Run | `[Run] Customer Value` | relevé de rôle |
| Dev Plateforme | Run | `[Run] Tech Value` | relevé de rôle |
| Goal volant | Idle time | `[Run] Goal Volant` | relevé de rôle |
| Dev sur projet standard | Build | le projet lui-même | project update |
| Dev sur projet commando | Build | le projet lui-même | project update |
| Reviewer attitré | Transverse | — | pas d'update propre |

Le reviewer attitré n'a pas de projet à lui : son attendu — aucune PR du projet
qui traîne — se dit dans l'update du projet qu'il relit. Ne pas lui en fabriquer.

## Ce qu'on passe en argument

Un argument **impose** ce qu'il nomme et supprime la question correspondante ; le
reste se demande ou se déduit. Ils se combinent en langue naturelle.

| Ce qu'on nomme | Effet |
| --- | --- |
| `point d'étape`, `fin de cycle` | Fixe le moment |
| un rôle — `plateforme`, `customer value`, `volant` | Fixe la forme et la fiche |
| un projet — `proforma`, `ATS` | Vise ce projet ; la forme devient le project update |
| un cycle — `cycle 55` | Rejoue une période close |
| quelqu'un d'autre que soi | Le brouillon se prépare, mais **le vécu du rôle reste vide** et l'update part au nom de l'intéressé, qui seul peut le valider |

## D'où viennent les attendus

Chaque rôle a une fiche dans la base
[Une fiche par rôle](https://app.notion.com/p/f315ce1f4311447f9f9475353d3662df)
de la page
[Gestion du Run](https://app.notion.com/p/3aee0f751bd681c6b24ed6b3d151ef69) : la
base donne l'`Attendu de fin de cycle` et le `Bloc`, la fiche donne la
**checklist de prise de poste** et les pièges.

```
notion-query-data-sources, mode sql, sur
collection://d61d41eb-2e59-4a77-812e-f75c67aa5c5b
```

**Les attendus ne se recopient pas ici** : les figer les périmerait en silence.
La page étant un brouillon non validé, deux précautions — la source de vérité est
[SLI-8235](https://linear.app/slash-interim/issue/SLI-8235), qui gagne sur toute
divergence signalée ; et fiche absente ou Notion inaccessible, on **poursuit sans
les attendus** en le disant, jamais de mémoire.

## Le geste

### 1. Demander le rôle et le moment, avant tout le reste

**Ça se demande, ça ne se devine pas.** Le rôle commande la forme, la fiche, les
attendus et le projet : une erreur ici fait un update entier à jeter.

Un `AskUserQuestion`, deux questions, **la réponse déduite déjà proposée en
premier**. Six rôles pour quatre options : les trois rôles de Run et d'Idle time
tiennent leur place, les rôles de Build se groupent en une quatrième — le projet
se demande alors dans la foulée, puisque c'est lui qui sépare le standard du
commando. Le reviewer attitré n'y figure pas.

Ce qui sert à pré-remplir : la **description du canal #tech** (`C03D79QFQ68`)
pour les rôles de Run et d'Idle time, où un rôle marqué `-` n'est tenu par
personne ; la position dans le cycle (`list_cycles`) pour le moment, les deux
derniers jours ou après la clôture valant fin de cycle.

Pour un rôle de **Build**, rien de fiable — ni #tech, qui ne les liste pas, ni
l'assignee Linear, qui désigne le relecteur. C'est pourquoi la question se pose.

### 2. La période

**Le cycle est le cadre, toujours** (`list_cycles`) : du début du cycle visé à
aujourd'hui pour un point d'étape, à sa clôture pour une fin de cycle.

Le **dernier update ne fait que remonter le départ**, jamais l'inverse : posté
pendant le cycle, la période reprend où il s'arrête ; antérieur au cycle, il ne
sert qu'à mesurer le trou. **Ce trou ne se publie pas** : il se dit à l'auteur
au moment de valider, pour qu'il sache ce que l'update ne couvre pas, et
n'apparaît jamais dans le texte posté — un lecteur n'a que faire de ce qui n'a
pas été écrit. Remonter à un update vieux d'un mois ferait raconter trois cycles
et le travail de plusieurs personnes. Regarder aussi **qui l'a écrit** : un update du produit
sur une recette peut être le plus récent sans rien dire de la livraison.

### 3. Rassembler

Sur la période et pour la personne. Les sources sont indépendantes : les lancer
**en parallèle**, via des sous-agents pour que les résultats bruts ne remplissent
pas la session.

| Source | Ce qu'on y prend |
| --- | --- |
| GitHub | Les PR **dont la personne est l'auteur**, et le **nombre de reviews** faites sur celles des autres |
| #daily | Ses posts — la **seule** source du travail qui n'a jamais eu de ticket |
| Linear | Issues fermées ou déplacées, milestones, changements de statut |
| #tech, #urgences-tech, #métier, releases, Sentry | Incidents pris, releases et hotfixes, opérations de prod, alertes |

**Un point d'étape ne prend que les deux premières** : quelques jours, pas de
passation à préparer, et trois minutes à tenir.

#### Établir qui a fait quoi — deux passes

**L'assignee Linear ne désigne pas l'auteur.** L'assignee de la PR GitHub est
renseigné avec le **relecteur**, et c'est lui qui pilote l'assignee Linear. Les
issues qu'une personne porte au cycle sont donc le plus souvent celles qu'elle a
**relues**. Un skill qui l'ignore écrit l'update de quelqu'un d'autre : sur les
cas éprouvés, l'erreur était systématique, dans les deux sens.

**D'abord GitHub.** Sur un **relevé de rôle**, par auteur — `gh pr list -R
slash-interim/slash-interim --author <login> --state all` sur la période. Sur un
**project update**, par les tickets du projet, quel qu'en soit l'auteur : le
cadre est le projet, et les reviews faites ailleurs n'y ont pas leur place.
Prendre `all` et pas `merged` : une PR ouverte en fin de période est une
information, souvent la plus utile.

**Ensuite Linear, pour vérifier.** Pour chaque issue attribuée à la personne,
résoudre sa PR (`gh pr list --search "SLI-XXXX"`) et lire son `author.login` :

- auteur ≠ la personne → c'est une **review**. Elle se compte, elle ne se raconte
  pas comme une livraison ;
- auteur = la personne → c'est son travail, même si Linear l'attribue ailleurs ;
- **aucune PR** → travail sans code : opération de prod, incident traité dans
  Slack, qualification. Ça se croise avec #daily et les fils d'incident.

**Le login GitHub ne se déduit pas du nom Linear ou Slack**, et aucune table ne
les relie. Le résoudre sur l'historique des PR de la période et le faire
confirmer au moindre doute : se tromper de login vide la collecte sans rien
signaler.

**La review est un poste de charge** — jusqu'à 28 PR sur un cycle, absentes des
deux outils de suivi. Elle se compte et elle se dit.

### 4. Rédiger le brouillon, complet

**Fin de cycle → lire `references/fin-de-cycle.md` avant d'écrire.** Ses sections
supplémentaires et leurs règles ne sont pas ici, et ne s'improvisent pas.

**Le réalisé dit ce que ça change, pas quels tickets ont bougé.** Linear affiche
déjà la liste des issues à côté de l'update : la répéter en prose ne dit rien de
neuf, et c'est le même principe que « le relecteur a déjà le diff ». Une
énumération de tickets habillée en phrase reste une énumération.

**Ni liste, ni compte.** « 9 livrés, 2 doublons », « les 4 premiers tickets
tournent en prod », « le jalon est à 100 % » ne disent rien à qui n'ouvre pas le
tracker. Ce qui parle, ce sont les **fonctionnalités** : ce qu'un utilisateur
peut faire maintenant et ne pouvait pas avant, et ce qui l'attend à la prochaine
release.

Donc : **une phrase-chapeau en gras par idée, la conséquence en prose**, et une
**prochaine étape qui nomme qui fait quoi** quand il y en a une. Un identifiant
SLI ne se cite que si le lecteur doit aller voir **celui-là précisément** — un
arbitrage, une alerte, un sujet que le suivant reprend. Le modèle est ce que le
produit écrit lui-même sur ses projets : « l'axe de découpage change », « next
step : Julien explore la spec » — trois lignes qui portent plus qu'une liste de
sept livraisons.

Un **point d'étape** porte quatre choses. La santé et le réalisé tiennent en
**120 mots** ; les arbitrages, une ligne chacun, sans plafond — on coupe le
récit, jamais une décision à prendre.

C'est un **plafond, pas une cible**. Les updates de référence du produit vont de
40 à 450 mots : ce qui est constant chez lui n'est pas la longueur mais qu'il n'y
figure **rien qui ne soit une décision ou un point en suspens**. Le gras à éviter
est le récit du travail fait, pas le volume.

- **La santé** — `On track` / `At risk` / `Off track` ;
- **Le réalisé** depuis le dernier point ;
- **Les attendus, en projection** : ce qui n'est pas encore engagé, tant qu'il
  est temps de corriger. C'est la meilleure raison d'en faire un sur un rôle de
  Run — « le runbook n'est pas engagé » à mi-parcours est un signal ;
- **Décisions & arbitrages**, puis **Alertes** — deux sections, pas une. Un
  arbitrage demande à quelqu'un de trancher et se nomme avec lui ; une alerte
  signale un risque sans appeler de décision immédiate. Les mélanger noie les
  décisions dans les risques. C'est là qu'elles servent encore : sur un projet,
  le **débordement qui se voit venir** est une alerte, et annoncé à mi-parcours
  il se replanifie.

### 5. Le brouillon, puis poster

Afficher le brouillon entier, **santé exceptée** : elle seule ne sort pas de la
collecte, elle se remplit après.

Avec le brouillon, **une** question : le **verdict** — `On track` / `At risk` /
`Off track`. Celui que la collecte suggère est proposé en premier, son motif
observable dans la description de l'option.

Une **seconde question ne se pose que si la réponse la rend utile** : verdict
`At risk` ou `Off track`, ou verdict qui **contredit** ce que la collecte
suggérait. C'est là, et seulement là, que la raison est ailleurs que dans
l'avancement. Elle demande alors **ce qui porte le jugement**, en choix
multiple : congés sur une partie de l'équipe, difficulté avec un tiers,
complexité technique imprévue. La liste n'est pas fermée — `AskUserQuestion`
ajoute « autre » de lui-même, en saisie libre ; ne pas le mettre dans les
options, ce serait gaspiller une des quatre places, et c'est souvent là qu'est la
vraie raison.

**Un verdict nominal et conforme à la suggestion ne déclenche rien** : la ligne
s'écrit du verdict et de ce qui l'explique. Une question dont la réponse est
« rien d'autre » est un clic volé, et c'est comme ça qu'un geste de trois minutes
devient un questionnaire.

Puis **écrire la ligne de santé** à partir des deux réponses — le verdict, puis
ce qui le porte, en une phrase qui les tient ensemble. Jamais l'énumération des
cases cochées.

Dans le même message, la seule question qui reste, en prose : *qu'est-ce que j'ai
raté ?* C'est la plus rentable — la personne corrige au lieu de composer. C'est
aussi là qu'on lui dit ce que l'update ne couvre pas, quand la période laisse un
trou derrière elle.

Puis `save_status_update`, **sur go explicite**. Un update notifie les abonnés :
il part une fois.

## Garde-fous

- **La santé est un jugement humain, jamais un calcul.** L'état des tickets
  l'alimente, il ne la produit pas : des congés sur une partie de l'équipe, une
  difficulté avec un tiers, une complexité technique imprévue pèsent autant et
  n'apparaissent dans aucune source. « Tous les tickets sont clos et le jalon est
  à 100 % » n'est donc pas une santé, c'est une métrique. Elle se **demande**, et
  s'écrit en **une ligne** — le verdict, puis ce qui le porte, qui n'est pas
  forcément un chiffre. Quand elle n'est pas tranchable, l'autre lecture descend
  dans les arbitrages. Sur un relevé de rôle, elle se lit contre les attendus de
  la fiche, pas contre un plan que le run n'a pas.
- **Rien ne s'invente.** Une source muette donne une section vide et un « je n'ai
  rien trouvé sur X », jamais une phrase de remplissage. Un update qui brode est
  pire qu'un update absent.
- **Rien n'est posté sans validation explicite** — vaut pour tout `save_*`.
- **Le texte part sur Linear**, donc `slash:writing` s'applique : un paragraphe
  s'écrit sur une seule ligne, et c'est le rendu qui décide où couper.
- **Un cycle sans rien à signaler existe.** Le dire en deux lignes est un update
  valable ; sur un point d'étape, c'est même une raison de ne pas en poster.
- **Le point d'étape doit se payer lui-même.** S'il ne fait pas baisser le coût
  de la fin de cycle, il n'a pas de raison d'exister. Ça se mesure après deux
  cycles, et ça se dit à l'équipe.
