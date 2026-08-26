# Les bornes

Chaque borne existe parce qu'elle a une **conséquence** : ce qui arrive au-delà.
Une limite sans conséquence n'est qu'un ornement, et se fait contourner.

Le domicile unique de tous les chiffres annoncés par cet atelier : chacun doit
être traçable jusqu'au skill qui le porte.

## Ce qu'on écrit

| Écrit | Borne | Au-delà |
| --- | --- | --- |
| Description de PR | **150 à 250 mots de prose**, 3 sections ni plus ni moins, 2 à 4 phrases pour le problème et pour le correctif | Ce n'est plus une description mais un rapport. Le relecteur a trente secondes et il a déjà le diff. |
| Section « Recettage » d'une PR | **obligatoire** : un script de **cinq étapes au plus** avec l'attendu à chacune, ou la phrase qui dit pourquoi rien n'est à recetter | Le relecteur recette avant de relire le code. Sans script, il saute l'étape — et personne ne vérifie que la PR fait ce qu'elle annonce. Au-delà de cinq étapes, c'est la PR qui fait trop de choses. |
| Preuve de ce qui a été testé, dans la description | **rien** — le script dit quoi faire, pas ce qui a été fait | Un tableau de recette est une preuve adressée au demandeur, pas au relecteur. |
| Rapport d'étape dans le chat | **3 à 5 lignes** en prose | S'il ne tient pas en cinq lignes, il contient autre chose qu'un rapport. |
| Ce qui est hors périmètre | **une ligne**, puis on continue | Le ticket, et rien que le ticket ; c'est à l'utilisateur d'en faire un autre. Son détail va dans l'autre ticket, jamais dans celui-ci. |
| Livrable écrit long — plan, handoff, analyse, dossier de décision | **200 lignes**, après une passe d'élagage obligatoire | Ce n'est plus un plan mais un dossier : le relecteur le survole au lieu de l'arbitrer, et son accord ne vaut plus rien. |
| Commentaire de détail technique (Linear ou PR) | **250 mots**, un seul, jamais une série | Ce n'est plus un commentaire mais un document : soit un fichier dans le dépôt, soit c'était à supprimer. |
| Renvoi vers ce commentaire depuis le livrable | **une ligne**, jamais un résumé | La pollution qu'on venait de sortir revient par la fenêtre. |
| Le POURQUOI d'un ticket | **cinq lignes**, avec les mots de l'utilisateur | C'est la matière première de la description de PR, pas une analyse. |
| Message de commit (slash-interim) | **titre seul, sans corps** | Convention du dépôt, portée par `slash-commit`. |

Les 150 à 250 mots se comptent hors script de recettage, et valent **par PR**,
jamais par lot : trois PR font trois descriptions et trois recettages.

## La taille d'une pull request

| Borne | Mesure | Au-delà |
| --- | --- | --- |
| **400 lignes** ajoutées + supprimées, **ou 15 fichiers** | Hors fichiers générés — lockfiles, migrations, snapshots, i18n, `generated/` | Arbitrage : une PR ou plusieurs. Ni contournement silencieux, ni découpage d'autorité. |
| **3 PR** dans une pile | Nombre d'étages empilés | Le coût d'intendance — un rebase par fusion amont — dépasse le gain de relecture. |

Ces seuils sont un **déclencheur de conversation**, pas une loi : 500 lignes d'un
même pattern répété se relisent mieux que 200 lignes de logique dense.

À ne pas confondre avec le seuil de **`slash-commit`**, dans le dépôt
slash-interim : 500 lignes ou 10 fichiers, qui découpe en **commits** et non en
PR. Les deux se cumulent — des commits bien découpés peuvent très bien partir
dans une PR unique et énorme, ce que la borne ci-dessus existe pour empêcher.

## Les portes anti-overkill

Un skill qui impose quinze minutes de cérémonie sur un libellé mal orthographié
se fait contourner, et un skill contourné ne sert plus à rien. Deux d'entre eux
calibrent donc leur profondeur avant de s'engager :

| Skill | Porte |
| --- | --- |
| `constat` | **Trois questions** : y a-t-il quelque chose d'observable, l'utilisateur connaît-il déjà la zone, un challenge est-il probable. Rien d'observable — refactor, renommage — c'est trois lignes et rendre la main. |
| `recette-dataset` | **Trois questions**, et dès qu'une réponse coupe, on s'arrête. Un jeu de données ne prouve rien sans **au moins deux lignes qui divergent** sur la dimension testée. |

Le coût en tokens est lui aussi borné — voir [`contribuer.md`](contribuer.md).
