# La couche de fin de cycle

Ce que l'update de fin de cycle ajoute au point d'étape. À lire avant de rédiger,
et seulement dans ce cas — un point d'étape n'en a pas besoin.

**250 mots sur la santé et le réalisé.** Les arbitrages tiennent une ligne
chacun, sans plafond, et la passation n'a pas de borne : son lecteur est le
suivant, il a deux minutes et non dix secondes, et c'est la seule section qu'on
ne coupe pas. On coupe le récit, jamais une décision à prendre.

## Les sections, dans l'ordre

**Relevé de rôle** (Run, Idle time) :

1. **La santé**, adossée aux attendus du rôle ;
2. **Ce qui a été fait** — trois puces au plus, review comprise ;
3. **Les attendus**, en bilan ;
4. **Les arbitrages et alertes** ;
5. **Ce qui attend le suivant** ;
6. **Le vécu du rôle** — trois puces au plus.

**Project update** (Build) : la santé, le réalisé, les arbitrages et alertes, puis
**le jalon** — au moins un jalon mergé pour un projet standard, sujet clôturé ou
débordement arbitré pour un commando.

## Les attendus, en bilan

Confronter le réalisé aux attendus de la fiche plutôt qu'énumérer. « 3 sur 4, la
passe Dependabot n'est pas passée » vaut dix fois une liste de réalisations.

**Rien ne se dit deux fois.** La confrontation porte tout ce qu'elle couvre ;
« ce que j'ai fait » ne garde que ce qui tombe **en dehors** des attendus — et
c'est souvent l'essentiel du cycle, puisque c'est l'imprévu. Un relevé qui
annonce la passe Dependabot en puce puis la recoche en attendu paie deux fois la
même information.

Un attendu non tenu **se dit**, sans être adouci ni transformé en échec : la
fiche du dev Plateforme le pose elle-même — un cycle où la prod a brûlé et où les
objectifs ne sont pas atteints n'est pas un échec, mais ça se dit explicitement.

Certains se vérifient **mécaniquement** sur la collecte. « Aucun incident qui
disparaît dans le fil Slack » se contrôle en listant les incidents trouvés dans
#tech, #urgences-tech et #métier sans ticket Linear en face. Sur un cas éprouvé :
quatre sur six.

**Les pièges de la fiche se confrontent comme les attendus.** Ils nomment les
façons dont le rôle se rate, et un relevé ne vaut que s'il dit quand c'est
arrivé — un dev Customer value a porté trois jours un incident de downtime qui
revenait au dev Plateforme, absent. C'est le piège que sa fiche décrit, et c'est
ce qui se réarbitre au cycle suivant.

## Ce qui attend le suivant

Rédigé **contre la checklist de prise de poste** de la fiche. Elle pose les
questions — « j'ai récupéré de mon prédécesseur les sujets de prod en cours ou
sous surveillance » —, cette section y répond point par point.

C'est ce qui sert l'objectif de passation, et ce qui manquait aux updates
existants, où l'information était noyée dans le « ce que j'ai fait ».

**Un arbitrage ne s'y range pas.** « Ce qui t'attend » dit au suivant ce qu'il
hérite ; un arbitrage demande une décision à quelqu'un d'autre que lui.
Confondre les deux enterre la décision — un essai d'outil à trancher et un
incident porté par le mauvais rôle sont des arbitrages, pas des consignes de
reprise.

## Le vécu du rôle

Trois puces au plus, sur comment le rôle a été vécu et ce qu'on peut améliorer.
**Aucune source ne le produit.** Il se demande en même temps que « qu'est-ce que
j'ai raté ? », ouvert, avec le droit de n'avoir rien à dire — et il reste vide
plutôt que d'être inventé. Sur un update préparé pour quelqu'un d'autre, il reste
vide dans tous les cas.

## S'appuyer sur les points d'étape

S'il en existe sur le mandat — repérables à leur marqueur de première ligne —,
le réalisé devient une **synthèse**, pas une répétition, et la collecte ne porte
que sur ce qu'ils ne couvrent pas. S'il n'y en a aucun, collecte entière.
