# Les bornes

Chaque borne existe parce qu'elle a une **conséquence** : ce qui arrive au-delà.
Une limite sans conséquence n'est qu'un ornement, et se fait contourner.

Le domicile unique de tous les chiffres annoncés par cet atelier : chacun doit
être traçable jusqu'au skill qui le porte.

## Ce qu'on écrit

| Écrit | Borne | Au-delà |
| --- | --- | --- |
| Description de PR | **150 à 250 mots de prose**, 4 sections ni plus ni moins — contexte, problème, correctif, comment tester — plus les screenshots quand l'UI bouge, 2 à 3 phrases pour le contexte et 2 à 4 pour le problème et le correctif | Ce n'est plus une description mais un rapport. Le relecteur a trente secondes et il a déjà le diff. |
| Section « Comment tester » d'une PR | **obligatoire**, et **une seule** : un script de **cinq étapes au plus** avec l'attendu à chacune — déroulé, ou annoncé comme non joué avec son empêchement —, ou la phrase qui dit pourquoi rien n'est à recetter | Le relecteur recette avant de relire le code. Sans script, il saute l'étape — et personne ne vérifie que la PR fait ce qu'elle annonce. Au-delà de cinq étapes, c'est la PR qui fait trop de choses. |
| Section « Screenshots » d'une PR | **obligatoire dès que le diff touche quelque chose de visible** — écran, composant, mail, PDF, export mis en forme —, en avant/après cadré sur la zone qui change | Le diff ne montre ni un libellé tronqué ni une couleur, et le script de recettage suppose qu'on sait à quoi ressemble le bon résultat. Surtout : l'« avant » n'est plus capturable une fois le correctif en place. |
| Preuve de ce qui a été testé, dans la description | **rien** — le script dit quoi faire, pas ce qui a été fait | Un tableau de recette est une preuve adressée au demandeur, pas au relecteur. |
| Rapport d'étape dans le chat | **3 à 5 lignes** en prose | S'il ne tient pas en cinq lignes, il contient autre chose qu'un rapport. |
| Ce qui est hors périmètre | **une ligne**, puis on continue | Le ticket, et rien que le ticket ; c'est à l'utilisateur d'en faire un autre. Son détail va dans l'autre ticket, jamais dans celui-ci. |
| Livrable écrit long — plan, handoff, analyse, dossier de décision | **200 lignes**, après une passe d'élagage obligatoire | Ce n'est plus un plan mais un dossier : le relecteur le survole au lieu de l'arbitrer, et son accord ne vaut plus rien. |
| Commentaire de détail technique (Linear ou PR) | **250 mots**, un seul, jamais une série | Ce n'est plus un commentaire mais un document : soit un fichier dans le dépôt, soit c'était à supprimer. |
| Renvoi vers ce commentaire depuis le livrable | **une ligne**, jamais un résumé | La pollution qu'on venait de sortir revient par la fenêtre. |
| La forme du code retenue, dans le plan (ticket qui touche `backend/src/`) | **trois à cinq lignes** : arbo plate ou SDDD, use-case ou application service, ports, entité ou value-object, et le fichier existant imité | La forme se décide dans le plan ou elle se subit en review : à l'implémentation elle est déjà écrite, et la remarque coûte un aller-retour. |
| Le POURQUOI d'un ticket | **cinq lignes**, avec les mots de l'utilisateur | C'est la matière première de la description de PR, pas une analyse. |
| Message de commit (slash-interim) | **titre seul, sans corps** | Convention du dépôt, portée par `slash-commit`. |

Les 150 à 250 mots se comptent hors script de recettage, et ne montent pas avec
le diff : une PR qui livre une fonctionnalité entière se décrit dans les mêmes
250 mots qu'un correctif, parce qu'elle doit dire le POURQUOI et non l'inventaire. Ils
n'ont pas monté quand la section « Contexte » s'est ajoutée aux trois autres :
ce qui situait le lecteur était déjà écrit, il a seulement changé de section.

## La taille d'une pull request

**Il n'y en a plus.** L'équipe a arbitré qu'une PR livre une fonctionnalité ou un
correctif entier, et que c'est la **review** qu'on découpe en blocs — découper la
livraison coûtait des rebases en cascade pour un bénéfice que la review par blocs
donne sans eux.

Ce qui remplace la borne n'est pas un chiffre mais un critère, porté par
**`slash:pr-scope`** : une PR livre quelque chose de **constatable**, qu'on peut
mettre devant quelqu'un. Il se tranche à l'analyse, et ne se mesure pas.

Reste le seuil de **`slash-commit`**, dans le dépôt slash-interim : 500 lignes ou
10 fichiers, qui découpe en **commits** et non en PR. Il n'a pas bougé, et c'est
lui qui rend une grosse PR relisible bloc par bloc.

## Les contrôles mécaniques

Une règle qu'on peut appeler ne se retient pas. Dans slash-interim, les règles
SDDD mécanisées ont **zéro** violation ; les mêmes laissées en prose en comptent
de **14 à 27** chacune.

| Contrôle | Borne | Au-delà |
| --- | --- | --- |
| `process-ticket` → `scripts/red-flags-sddd.py`, à l'étape 3 | **zéro signalement** sur les fichiers back touchés par la branche | Un red flag SDDD non traité part en review. La remarque y porte sur une décision de conception — ports, mapper, entité ou value-object — donc sur du code déjà écrit : un aller-retour. |

## Les portes anti-overkill

Un skill qui impose quinze minutes de cérémonie sur un libellé mal orthographié
se fait contourner, et un skill contourné ne sert plus à rien. Deux d'entre eux
calibrent donc leur profondeur avant de s'engager :

| Skill | Porte |
| --- | --- |
| `observe` | **Trois questions** : y a-t-il quelque chose d'observable, l'utilisateur connaît-il déjà la zone, un challenge est-il probable. Rien d'observable — refactor, renommage — c'est trois lignes et rendre la main. |
| `case-dataset` | **Trois questions**, et dès qu'une réponse coupe, on s'arrête. Un jeu de données ne prouve rien sans **au moins deux lignes qui divergent** sur la dimension testée. |

Le coût en tokens est lui aussi borné — voir [`contribuer.md`](contribuer.md).
