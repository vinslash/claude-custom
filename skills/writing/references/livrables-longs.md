# Livrables longs : la passe d'élagage

À lire avant de rendre un document de plan, un handoff, une analyse ou un
dossier de décision. Le `SKILL.md` porte les bornes ; ce fichier porte le geste.

## La passe

Relire chaque affirmation du document avec **une seule question** :

> Quelle décision du lecteur ceci change-t-il ?

Trois issues, et une seule est le maintien :

| Le bloc… | Va… |
| --- | --- |
| change une décision du lecteur **maintenant** | reste dans le livrable |
| ne change aucune décision, et personne ne le redemandera | **supprimé** |
| ne change aucune décision, mais serait **coûteux à reproduire** et quelqu'un le rechercherait | commentaire, dans les 250 mots — voir `SKILL.md` |

La troisième issue est un couloir étroit, pas une poubelle. « Coûteux à
reproduire » veut dire : une investigation de cause racine, une mesure, une
exploration de données, une hypothèse éliminée avec ce qui l'a éliminée. Un
raisonnement qu'on refait en cinq minutes n'y a pas droit — il est supprimé.

**Si la passe déplace autant qu'elle supprime, elle n'a pas été faite.** C'est
le seul contrôle qui vaille : sans lui, « je ne supprime pas, je déplace en
commentaire » vide l'élagage de son effet et déporte simplement le pavé.

Et si elle ne retire rien du tout, elle n'a pas eu lieu. L'ordre de grandeur
attendu est connu — voir plus bas.

## Les quatre défauts, et à quoi on les reconnaît

### L'accumulation sans élagage

Tout sujet exploré en cours de route laisse une trace dans le livrable, même une
fois éteint. Le symptôme est une ligne qui **répond à une question que personne
ne pose plus** : « Bornage temporel : aucun », sur un point abandonné à
mi-parcours. Le lecteur, qui n'a pas suivi la route, la lit comme une décision
et cherche à comprendre pourquoi elle est là.

Un tableau de décisions est le premier endroit à relire : il attire les lignes
mortes, parce qu'une case vide y a l'air d'un oubli.

### La plaidoirie au lieu de l'énoncé

Chaque décision est défendue comme si elle était contestée : pourquoi un offset
est mauvais, pourquoi pas de transaction globale, pourquoi deux value objects.
Le symptôme est le « car », le « en effet », le « ce qui permet de » derrière
une décision que personne n'a discutée.

Énoncer, et renvoyer à la règle du dépôt quand elle existe : **c'est la règle
qui justifie, pas le document.** Un lint, une path-rule, un ADR, un skill —
nommer la source coûte une demi-ligne et vaut trois paragraphes.

Le seul cas où le pourquoi reste : quand l'ignorer conduirait à **défaire** la
décision. Un futur lecteur qui ne voit pas la contrainte la supprime.

### Le hors-périmètre conservé

Un sujet qui relève d'un autre ticket, gardé avec tout son détail. Le détail est
le vrai défaut, plus encore que la mention : il donne à un non-sujet le poids
d'un sujet.

Une ligne de renvoi dans le livrable, et le détail va dans **l'autre ticket** —
pas en commentaire de celui-ci. Ne pas confondre avec l'exutoire du `SKILL.md`,
qui sert au détail *dans* le périmètre.

### Le méta-commentaire sur la conversation

« Remarque de X retenue », « correction de ce que j'avais avancé plus haut »,
« les deux questions de Y ». Le lecteur n'était pas là et n'a pas à l'être.

**Un document décrit l'état du monde, pas l'historique de sa rédaction.** Ce qui
a été corrigé en route n'existe plus ; ce qui reste se lit comme si ça avait
toujours été écrit ainsi.

## Convertir plutôt que couper

Certaines coupes ne coûtent rien parce que ce n'est pas une coupe : la même
information change de forme, et gagne sur les deux tableaux à la fois.

| Ce qu'on a | Ce que ça devient |
| --- | --- |
| Deux blocs de code qu'il faut diffuser mentalement l'un contre l'autre | Un tableau à colonnes — `Lu` / `Décidé` |
| Une liste numérotée de lecteurs et d'écrivains, en prose | Un tableau `Lit` / `Écrit` / `Ignore` |
| Un enchaînement d'acteurs, d'étapes ou de flux | Un schéma mermaid |

Sur le cas fondateur, la première conversion a retiré 22 lignes **et** rendu
l'asymétrie visible d'un coup d'œil : ce qu'aucune des deux versions en prose ne
montrait, faute de pouvoir les regarder ensemble.

C'est le premier réflexe à avoir devant un passage long, avant même de songer à
le raccourcir.

## Le cas fondateur

Un plan d'implémentation pour un ticket Linear, relu par un développeur backend
senior qui connaissait le domaine. Six allers-retours :

**841 → 777 → 425 → 373 → 197 lignes, à information constante.** Quatre lignes
sur cinq du premier jet étaient du remplissage, et aucune réduction n'est venue
d'une perte de contenu.

Le verbatim, qui porte plus que tout ce qui précède :

> « Trop de texte, un schéma peut être plus logique »

> « Trop de justification, claude aime bien tout expliquer et justifier alors que
> parfois il faut juste dire comme c'est, point. Ex le premier tableau
> "décisions", il parle de bornage temporel qu'on a jamais évoqué »

> « La question de supprimer la table c'est un autre ticket donc ça n'a aucun
> sens de l'avoir dans ce plan (et encore moins son détail...) »

Au cinquième aller-retour, à 373 lignes, il le trouvait encore « illisible
humainement ».

## Enrichir ce fichier

Comme `exemples.md` : quand un livrable long se fait retoquer, ajouter ici le
symptôme et ce qui l'a corrigé. Les exemples portent plus que les règles.
