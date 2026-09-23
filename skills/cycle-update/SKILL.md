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
  Use when the user says « update de fin de cycle », « point d'étape », « project
  update », « fais le point sur le projet », « je passe la main sur le rôle »,
  « la passation du rôle », « qu'est-ce que j'ai fait ce cycle », or
  `/slash:cycle-update`; and whenever someone holding a cycle role wants to leave
  a trace of where things stand.
  Ne PAS utiliser pour écrire la **description** d'un projet Linear, pour rédiger
  un daily, ni pour traiter un ticket (→ `slash:process-ticket`).
---

# Les updates de cycle

## Pourquoi ce skill existe

Le rituel est déjà écrit. Fabien l'a posé dans #tech le 20/08 : un update en fin
de cycle sur le projet Linear du rôle, dix minutes, trois puces sur ce qui a été
fait, trois sur le vécu du rôle. Objectifs : fluidifier la passation, garder
trace de ce qui se fait **hors tickets Linear**, prendre du recul sur le rôle.

Un cycle plus tard, deux projets sur trois avaient reçu leur update, et un seul
au format complet.

Ça ne se lit pas comme de la mauvaise volonté : les dix minutes sont
sous-estimées. Le coût n'est pas d'écrire, il est de **se rappeler** deux
semaines dont la moitié n'a laissé aucune trace dans un ticket. C'est cette
part-là que ce skill enlève. Le reste — le vécu, la santé du projet, les
arbitrages à poser — personne ne peut le produire à la place de celui qui a tenu
le rôle, et ce skill ne l'invente pas.

**Les dix minutes sont le critère de réussite**, pas un vœu. Si l'aller-retour en
prend vingt, c'est la collecte qu'il faut couper.

S'y ajoute une demande du produit, qui veut une vision d'ensemble **pendant** le
cycle et pas seulement à sa clôture. D'où deux moments, et non deux rituels.

## Ce qu'on passe en argument

Sans argument, le rôle et le moment se demandent à l'étape 1, réponse déduite
déjà proposée. Un argument **impose** ce qu'il nomme et supprime la question
correspondante ; le reste se demande ou se déduit comme d'habitude. Ils se
combinent librement, en langue naturelle :

| Ce qu'on nomme | Effet |
| --- | --- |
| `point d'étape`, `fin de cycle` | Fixe le moment, au lieu de le déduire de la position dans le cycle |
| un rôle — `plateforme`, `customer value`, `volant` | Fixe la forme et la fiche, sans passer par la description de #tech |
| un projet — `proforma`, `ATS` | Vise ce projet ; la forme devient le project update |
| un cycle — `cycle 55` | Rejoue une période close au lieu de la période courante |
| quelqu'un d'autre que soi | Le brouillon se prépare, mais **le vécu du rôle reste vide** et l'update part au nom de l'intéressé, qui seul peut le valider |

## La forme se déduit du rôle

Pas de la nature du projet, ni d'une heuristique : de la colonne **Bloc** de la
fiche du rôle.

| Rôle | Bloc | Où va l'update | Forme |
| --- | --- | --- | --- |
| Dev Customer value | Run | `[Run] Customer Value` | relevé de rôle |
| Dev Plateforme | Run | `[Run] Tech Value` | relevé de rôle |
| Goal volant | Idle time | `[Run] Goal Volant` | relevé de rôle |
| Dev sur projet standard | Build | le projet lui-même | project update |
| Dev sur projet commando | Build | le projet lui-même | project update |
| Reviewer attitré | Transverse | — | pas d'update propre |

Le reviewer attitré est le seul sans domicile : il n'a pas de projet à lui, et
son attendu — aucune PR du projet qui traîne — se dit dans l'update du projet
qu'il relit. Ne pas lui en fabriquer un.

## Deux moments, dont l'un contient l'autre

Le **point d'étape** répond exactement à ce que le produit demande — santé,
réalisé depuis le dernier update, arbitrages et alertes —, et rien de plus.
L'**update de fin de cycle** est ces trois points, plus la couche de passation :
les attendus du rôle en bilan, ce qui attend le suivant, le vécu du rôle.

Le point d'étape n'est donc pas une corvée en plus : c'est **la matière première
de la passation**. Le coût de l'update de fin de cycle n'est pas d'écrire mais de
se rappeler deux semaines dont la moitié n'a pas de ticket. Un cycle raconté au
fil de l'eau réduit la collecte finale aux derniers jours.

**Aucune cadence n'est imposée** : le point d'étape part à l'initiative de la
personne, quand elle juge qu'il y a quelque chose à dire. Le skill répond, il ne
convoque pas. Conséquence directe : l'update de fin de cycle ne peut **jamais
présumer** qu'il en existe. Il en cherche, s'en sert s'il en trouve, et fait la
collecte entière sinon.

Le moment ne se suppose pas : il se demande d'entrée, avec l'étape 1 — une
passation peut se faire en cours de cycle, et un départ en congés ne s'aligne sur
rien.

### Le marqueur de première ligne

Linear ne type pas les updates. La distinction vit donc dans le texte, première
ligne, sans rien avant elle :

```
**Point d'étape — cycle 55**
**Fin de cycle 55 — passation du rôle Plateforme**
```

Ce n'est pas cosmétique : c'est ce qui permet de retrouver les points d'étape du
mandat courant pour composer la synthèse finale, et ce qui évite de prendre pour
un bilan un update écrit par quelqu'un d'autre sur un tout autre sujet.

## D'où viennent les attendus

Chaque rôle a une fiche, dans la base
[Une fiche par rôle](https://app.notion.com/p/f315ce1f4311447f9f9475353d3662df)
de la page
[Gestion du Run](https://app.notion.com/p/3aee0f751bd681c6b24ed6b3d151ef69).
Deux appels suffisent : la base donne l'`Attendu de fin de cycle` et le `Bloc` de
chaque rôle, la fiche donne la **checklist de prise de poste** et les pièges.

```
notion-query-data-sources, mode sql, sur
collection://d61d41eb-2e59-4a77-812e-f75c67aa5c5b
```

**Les attendus ne se recopient pas ici.** Ils vivent dans la fiche, qui est leur
seul domicile ; les figer dans ce fichier les périmerait en silence.

Deux précautions, parce que la page est un brouillon non validé :

- la **source de vérité est [SLI-8235](https://linear.app/slash-interim/issue/SLI-8235)**.
  En cas de divergence signalée par l'utilisateur, le ticket gagne ;
- fiche absente ou Notion inaccessible → **poursuivre sans les attendus**, et le
  dire. Jamais les reconstituer de mémoire.

## Le geste

### 1. Demander le rôle et le moment, avant tout le reste

**C'est la première chose, et elle se demande — elle ne se devine pas.** Le rôle
commande la forme, la fiche, les attendus et le projet visé : tout ce qui suit
est bâti dessus, et une erreur ici fait un update entier à jeter.

Un `AskUserQuestion`, deux questions, **la réponse déduite déjà proposée en
premier** : le rôle, et le moment — point d'étape ou fin de cycle. Un clic quand
c'est juste, une correction sinon. Ce qu'un argument a déjà nommé ne se redemande
pas.

Six rôles pour quatre options : les trois rôles de Run et d'Idle time tiennent
leur place, et les rôles de Build se groupent en une quatrième — le projet se
demande alors dans la foulée, puisque c'est lui qui sépare le standard du
commando. Le reviewer attitré n'apparaît pas : il n'a pas d'update à lui.

Ce qui sert à pré-remplir :

- pour un rôle de **Run ou d'Idle time**, la **description du canal Slack #tech**
  (`C03D79QFQ68`), tenue à jour cycle après cycle, qui nomme les trois
  titulaires. Un rôle marqué `-` n'est tenu par personne : le dire, et ne pas en
  fabriquer d'update ;
- pour un rôle de **Build**, rien de fiable. Aucune source ne les porte : ni la
  description de #tech, qui ne les liste pas, ni l'assignee Linear, qui désigne
  le relecteur. C'est exactement pourquoi la question se pose au lieu de se
  déduire ;
- pour le **moment**, la position dans le cycle (`list_cycles`) : les deux
  derniers jours ou après la clôture → fin de cycle, ailleurs → point d'étape.

Les autres pistes — la vue *Project by People*, les leads posés sur le cycle —
ne concordent pas toujours entre elles, et le projet Run ne désigne pas son
titulaire : ses issues sont réparties sur toute l'équipe. Quand deux sources
divergent, le dire dans la question plutôt que choisir.

Le projet se déduit ensuite du rôle sans rien demander de plus, sauf pour un rôle
de Build, où il fait partie de la même question.

### 2. La période, qui en découle

**Le cycle est le cadre, toujours.** `list_cycles` en donne les bornes : la
période part du **début du cycle visé** et s'arrête à aujourd'hui pour un point
d'étape, à sa clôture pour un update de fin de cycle. Ça vaut pour les deux
formes et les deux moments.

Le **dernier update ne fait que remonter le départ**, jamais l'inverse
(`get_status_updates`, le plus récent) :

- posté **pendant le cycle** — un point d'étape précédent — la période reprend là
  où il s'est arrêté, pour ne pas redire ce qui est déjà dit ;
- **antérieur au cycle**, il ne sert qu'à mesurer le trou. On ne remonte pas
  jusqu'à lui.

**Le trou se nomme en une ligne, il ne se comble pas en silence.** Remonter à un
update vieux d'un mois ferait raconter trois cycles et le travail de plusieurs
personnes. C'est vrai des deux côtés : un relevé de rôle borné par le dernier
update ferait rendre compte du **prédécesseur** — le cas s'est présenté sur
`[Run] Tech Value` —, et un project update qui déborde du cycle mélange des
staffings successifs. Regarder aussi **qui l'a écrit** : un update posté par le
produit sur une recette peut être le plus récent sans rien dire de la livraison
qui l'a précédée.

### 3. Rassembler

Sur la période et pour la personne. Les sources sont indépendantes : les lancer
**en parallèle**, et via des sous-agents pour que les résultats bruts ne
remplissent pas la session.

**Un point d'étape ne prend que les deux premières.** Il couvre quelques jours,
il n'a pas de passation à préparer, et il doit rester à trois minutes : GitHub et
#daily suffisent à dire ce qui a avancé. Les quatre sources sont pour la fin de
cycle — et si des points d'étape couvrent déjà le début du mandat, la collecte ne
porte que sur ce qu'ils ne disent pas.

| Source | Ce qu'on y prend |
| --- | --- |
| GitHub | Les PR mergées **dont la personne est l'auteur** — c'est ça, le travail produit — et le **nombre de reviews** faites sur celles des autres |
| #daily | Ses posts — la **seule** source du travail qui n'a jamais eu de ticket |
| Linear | Issues fermées ou déplacées, milestones franchis, changements de statut du projet |
| #tech, #urgences-tech, #métier, releases, Sentry | Incidents pris, releases et hotfixes portés, opérations de prod, alertes traitées |

**L'assignee Linear ne désigne pas l'auteur.** Dans cette équipe, l'assignee de
la PR GitHub est renseigné avec le **relecteur**, et c'est lui qui pilote
l'assignee Linear. Les issues qu'une personne porte au cycle sont donc, le plus
souvent, celles qu'elle a **relues**. L'auteur se lit sur GitHub et dans #daily,
jamais dans Linear. Un skill qui l'ignore écrit l'update de quelqu'un d'autre :
sur les trois cas éprouvés, l'erreur était systématique.

**La review est un poste de charge, pas un à-côté** — jusqu'à 28 PR sur un
cycle, et elle n'existe dans aucun des deux outils de suivi. Elle se compte et
elle se dit.

#### Établir qui a fait quoi — deux passes

**D'abord GitHub.** Sur un **relevé de rôle**, par auteur — `gh pr list -R
slash-interim/slash-interim --author <login> --state all` sur la période. Sur un
**project update**, par les tickets du projet, quel qu'en soit l'auteur : le
cadre est le projet, et les reviews faites ailleurs n'y ont pas leur place.
Prendre l'état `all` et pas `merged` : une PR ouverte en fin de période est une
information, souvent la plus utile.

Dans les deux cas, c'est la liste du travail produit, et elle est la seule
fiable. Une issue peut être assignée à quelqu'un
d'autre pendant que la personne en a écrit la PR — c'est arrivé sur les cinq
livraisons d'un cycle, créditées à trois autres personnes dans Linear.

**Ensuite Linear, pour vérifier.** Pour chaque issue attribuée à la personne sur
la période, résoudre sa PR (`gh pr list --search "SLI-XXXX"`) et lire son
`author.login` :

- auteur ≠ la personne → c'est une **review**. Elle se compte, elle ne se
  raconte pas comme une livraison ;
- auteur = la personne → c'est son travail, même si Linear l'attribue ailleurs ;
- **aucune PR** → du travail sans code : opération de prod, incident traité dans
  Slack, qualification. Ça se croise avec #daily et les fils d'incident.

**Le login GitHub ne se déduit pas du nom Linear ou Slack**, et aucune table ne
les relie. Le résoudre une fois sur l'historique des PR de la période, et le
faire confirmer au moindre doute plutôt que de parier : se tromper de login vide
la collecte sans rien signaler.

### 4. Rédiger le brouillon, complet

Dans la forme du rôle, et en **confrontant le réalisé aux attendus** de la fiche
plutôt qu'en énumérant. Un relevé qui dit « 3 sur 4, la passe Dependabot n'est
pas passée » vaut dix fois un relevé qui liste.

Un attendu non tenu **se dit**, sans être adouci ni transformé en échec : la
fiche du dev Plateforme le pose elle-même — un cycle où la prod a brûlé et où les
objectifs ne sont pas atteints n'est pas un échec, mais ça se dit explicitement
en fin de cycle.

Certains attendus **se vérifient mécaniquement** sur la collecte. « Aucun
incident qui disparaît dans le fil Slack » se contrôle en listant les incidents
trouvés dans #tech, #urgences-tech et #métier qui n'ont pas de ticket Linear en
face. La réponse sort d'elle-même — sur un cas éprouvé, quatre incidents sur six.

**Les pièges de la fiche se confrontent comme les attendus.** Ils nomment les
façons dont le rôle se rate, et un relevé ne vaut que s'il dit quand c'est
arrivé — un dev Customer value a porté trois jours durant un incident de
downtime qui revenait au dev Plateforme, absent. C'est exactement le piège que sa
fiche décrit, et c'est ce qui se réarbitre au cycle suivant.

### 5. Le brouillon, puis poster

Afficher le brouillon entier, et poser **une seule** question : *qu'est-ce que
j'ai raté ?* C'est la plus rentable — la personne corrige au lieu de composer. Le
vécu du rôle se demande là, ouvert, avec le droit de n'avoir rien à dire.

Puis `save_status_update`, **sur go explicite**. Un update notifie les abonnés :
il part une fois.

## Ce que porte chaque forme

**Relevé de rôle** (Run, Idle time) :

- **La santé** — `On track` / `At risk` / `Off track`, adossée aux **attendus du
  rôle**. Sur un projet Run, ce à quoi on s'attendait est écrit : c'est la fiche.
  Un cycle à 1 attendu sur 4 est une déviation, et la porter dans le champ la
  rend lisible dans les vues Linear sans ouvrir le texte ;
- **Ce qui a été fait** — trois puces au plus, les points saillants, review
  comprise ;
- **Les attendus** — en **projection** sur un point d'étape : ce qui n'est pas
  encore engagé, tant qu'il est temps de corriger. En **bilan** en fin de cycle :
  tenus ou non, avec ce qui a pris leur place. C'est la meilleure raison de faire
  un point d'étape sur un rôle de Run — « le runbook n'est pas engagé » à
  mi-parcours est un signal, en fin de cycle c'est un constat ;
- **Les arbitrages et alertes**, s'il y en a — et c'est sur un point d'étape
  qu'ils servent encore ;
- **Ce qui attend le suivant** — *fin de cycle seulement*. Rédigé **contre la
  checklist de prise de poste**
  de sa fiche. Elle pose les questions ; cette section y répond. C'est ce qui
  sert l'objectif de passation, et c'est ce qui manquait aux updates existants,
  où l'information était noyée dans le « ce que j'ai fait » ;
- **Le vécu du rôle** — *fin de cycle seulement*. Trois puces au plus, et ce
  qu'on peut améliorer.

**Project update** (Build) :

- **La santé** — `On track` / `At risk` / `Off track` ;
- **Le réalisé** depuis le dernier update ;
- **Les arbitrages et alertes**, s'il y en a ;
- **Le jalon** — *fin de cycle seulement*. Mergé pour un projet standard, sujet
  clôturé ou débordement arbitré pour un commando. Sur un point d'étape, ce qui
  compte est plutôt le **débordement qui se voit venir** : annoncé à mi-parcours
  il se replanifie, annoncé le dernier jour il désorganise le cycle suivant.

Les trois premières sections sont **celles que le produit attend**, dans cet
ordre, sur les deux formes. Ce qui s'y ajoute leur est propre : le jalon vient
des attendus des fiches, la passation et le vécu du rôle viennent de la demande
de passation.

**Un arbitrage ne se range pas dans la passation.** « Ce qui t'attend » dit au
suivant ce qu'il hérite ; un arbitrage demande une décision à quelqu'un d'autre
que lui. Confondre les deux enterre la décision — un essai d'outil à trancher et
un incident porté par le mauvais rôle sont des arbitrages, pas des consignes de
reprise.

## Garde-fous

- **La santé ne se déduit jamais.** La proposer avec son motif et, quand elle
  n'est pas tranchable, **nommer l'autre lecture** plutôt que choisir — un
  commando dont le code est livré mais la recette pas commencée se lit `On track`
  ou `At risk` selon ce qu'on appelle clôture. C'est un jugement, pas une
  métrique. Sur un relevé de rôle, elle se lit contre les attendus de la fiche —
  pas contre un plan, que le run n'a pas.
- **Rien ne s'invente.** Une source muette donne une section vide et un « je n'ai
  rien trouvé sur X », jamais une phrase de remplissage. Un update qui brode est
  pire qu'un update absent.
- **Rien n'est posté sans validation explicite** — la règle vaut pour tout
  `save_*` sur Linear.
- **Le texte part sur Linear**, donc `slash:writing` s'applique : un paragraphe
  s'écrit sur une seule ligne, aussi longue qu'il le faut, et c'est le rendu qui
  décide où couper.
- **Un cycle sans rien à signaler existe.** Le dire en deux lignes est un update
  valable ; le gonfler pour faire nombre ne l'est pas. Et sur un point d'étape,
  ne rien avoir à dire est une raison de ne pas en poster.
- **Le point d'étape doit se payer lui-même.** S'il ne fait pas baisser le coût
  de l'update de fin de cycle, il n'a pas de raison d'exister : doubler la
  fréquence d'un rituel qui tient déjà mal est le meilleur moyen de le tuer. Ça
  se mesure après deux cycles, et ça se dit à l'équipe.
