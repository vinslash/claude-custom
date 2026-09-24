# Rédiger l'update

Ce que porte le texte, dans quel ordre, et ses bornes. Lu à l'étape 4, aux deux
moments.

## La règle qui commande les autres

**Rien qui double ce que Linear affiche déjà.** Badge de santé, pourcentage
d'avancement, jalons, liste des issues : tout est à l'écran, à côté de l'update.
Le répéter ne dit rien de neuf — même principe que « le relecteur a déjà le
diff ». Un update ne consigne que ce qui a une **valeur ajoutée** par rapport à
l'outil.

Donc ni liste, ni compte, ni pourcentage : « 9 livrés, 2 doublons », « le jalon
est à 100 % » ne disent rien à qui n'ouvre pas le tracker, et rien du tout à qui
l'ouvre. Ce qui parle, ce sont les **fonctionnalités** — ce qu'un utilisateur
peut faire maintenant et ne pouvait pas avant. Un identifiant SLI ne se cite que
si le lecteur doit aller voir **celui-là précisément**.

## Les blocs, dans cet ordre

- **La ligne de santé** — un one-liner qui **justifie** le statut sans le
  nommer : le badge est déjà affiché au-dessus. C'est un **jugement humain**, pas
  un calcul — des congés, une difficulté avec un tiers, une complexité imprévue
  pèsent autant que l'avancement. Quand elle n'est pas tranchable, l'autre
  lecture descend dans les décisions ;
- **Ce qui est en production depuis le dernier update**, avec sa **disponibilité
  réelle** quand elle compte : flag fermé, bêta sur quelques comptes, ouvert à
  tous. « En prod » seul ne dit rien à qui est extérieur à la cuisine tech, et
  cette disponibilité **se contrôle avant de se demander** (voir plus bas) ;
- **Ce qui est prêt pour la prochaine mise en production** ;
- **Ce qu'il reste à faire** ;
- **Décisions & arbitrages**, puis **Alertes** — deux sections, pas une, et
  **omises quand il n'y a rien**. La barre est haute : une décision **prise** sur
  le périmètre du projet, un risque **pour le projet**. Une question
  d'intendance, un sujet de staffing, ou la redite de ce que le réalisé vient de
  dire n'y ont pas leur place. Le tri garde une part de subjectif, et c'est
  assumé.

Sur un **relevé de rôle**, les trois blocs du milieu laissent place aux
**attendus en projection** : ce qui n'est pas encore engagé, tant qu'il est temps
de corriger. « Le runbook n'est pas engagé » à mi-parcours est un signal ; en fin
de cycle, c'est un constat.

Les blocs portent leurs propres intitulés : à l'intérieur, de la prose. Le modèle
est ce que le produit écrit sur ses projets — « l'axe de découpage change »,
« next step : Julien explore la spec ».

## Les bornes

Le **récit** tient en **120 mots** pour un point d'étape, **250** pour une fin de
cycle. Les décisions et les alertes tiennent **une ligne chacune, sans plafond**,
et la passation n'a pas de borne : on coupe le récit, jamais une décision à
prendre ni ce dont le suivant a besoin.

C'est un **plafond, pas une cible**. Les updates de référence du produit vont de
40 à 450 mots : ce qui est constant n'est pas la longueur, mais qu'il n'y figure
rien d'inutile.

## La disponibilité se contrôle, elle ne se demande pas d'abord

Un flag est une ligne de la table `feature` — `name` + `isDisabled` — déclarée
par une migration. L'enum `feature_name_enum` de la migration la plus récente qui
le redéclare donne la liste à jour.

Le contrôle porte sur **les fichiers livrés sur la période**, ceux des PR de la
collecte : une garde — `useFeature`, `FeatureName.`, `isFeatureEnabled` —
existe-t-elle dans leur module ?

- **aucune garde** → « en production » veut dire **disponible**. Ne rien demander.
- **une garde** → demander, en pré-remplissant avec la valeur initiale de la
  migration (`isDisabled: true` = fermé) et toute trace d'ouverture dans Slack.
  L'**état réel en production est une ligne de base de données** qu'aucune source
  du dépôt ne donne : c'est là, et seulement là, que le lead sait ce que personne
  d'autre ne sait.
