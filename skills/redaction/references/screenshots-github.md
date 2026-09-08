# Poser les captures sur GitHub

À lire quand une PR a une section « Screenshots » à remplir. `SKILL.md` porte la
règle — quand la section existe et ce qu'elle contient ; ce fichier porte le
geste, parce qu'il n'est pas évident : `gh` ne sait pas uploader d'image, et
GitHub n'expose aucune API pour les pièces jointes de commentaire. Le seul
chemin passe par le navigateur.

Il est à notre portée : le serveur MCP `chrome` en fournit un, et
`mcp__chrome__upload_file` accepte l'`uid` d'un input fichier **ou d'un élément
qui ouvre le sélecteur**. Charger `slash:chrome-ancrage` avant la première
action, comme pour n'importe quel pilotage.

## La connexion GitHub, une fois pour toutes

Le profil d'un worktree est cloné depuis `~/.cache/chrome-mcp/_modele` à sa
**naissance**. Une session GitHub ouverte dans le modèle est donc héritée par
tous les worktrees créés ensuite — c'est déjà comme ça que Dashlane arrive.

Le bon geste, une seule fois : `bin/chrome-modele.sh`, se connecter à GitHub,
fermer. Les worktrees déjà nés n'en profitent pas — le clonage a eu lieu —, il
faut s'y connecter une fois chacun.

Si la page de la PR affiche un écran de connexion, la session héritée a expiré :
point d'arrêt, comme la première fois.

**C'est un geste d'utilisateur, et c'est un point d'arrêt.** Rendre la fenêtre
et demander la connexion. Ne pas saisir d'identifiant, ne pas toucher à
Dashlane, ne pas contourner une 2FA. Une fois connecté, les uploads suivants sur
cette PR ne redemandent rien.

## Le geste

Le principe qui évite toute la classe de bugs « qui possède la description » :
**le navigateur ne sert qu'à héberger les images**, et `gh` reste le seul à
écrire le corps de la PR.

1. Pousser le corps avec `gh pr edit --body-file`, section « Screenshots »
   comprise mais **sans** les images.
2. Ouvrir la page de la PR. Vérifier l'URL **et le numéro de PR** avant de
   toucher à quoi que ce soit : une capture posée sur la PR d'un autre worktree
   est irrattrapable.
3. Dans la **zone de nouveau commentaire** — jamais l'éditeur de la description
   —, `upload_file` sur la zone de dépôt, avec les chemins des captures du
   scratchpad. Ils doivent être locaux à la machine du navigateur, ce qui est
   le cas ici.
4. Lire le contenu de la zone de commentaire (`evaluate_script`) : GitHub y a
   inséré un `![nom](https://github.com/user-attachments/assets/<uuid>)` par
   fichier. Récolter les URL.
5. **Vider la zone de commentaire sans la soumettre.** L'upload a eu lieu, les
   URL vivent, le commentaire n'a aucune raison d'exister.
6. Réécrire le fichier de corps avec les URL récoltées, et le pousser :
   `gh pr edit --body-file`.

La zone de commentaire plutôt que l'éditeur de description, parce qu'un éditeur
de description ouvert dans le navigateur pendant qu'on pousse par `gh` finit par
écraser l'un des deux états, au hasard.

## Là où ça coincera probablement

L'étape 4. La zone de commentaire de GitHub n'est pas garantie être un
`<textarea>` : selon l'éditeur servi, lire `.value` peut renvoyer vide alors que
le markdown est bien là. Prendre un `take_snapshot` avant de conclure à un échec
d'upload, et lire le contenu réellement rendu plutôt que le champ supposé. Un
upload réussi dont on n'arrive pas à récolter l'URL n'est pas un upload raté :
l'image existe sur GitHub, il n'y a qu'à retrouver son adresse.

Quand ce point sera tranché sur un cas réel, écrire ici ce qui a marché — ce
fichier a été rédigé sur la mécanique, pas encore sur l'épreuve.

## Vérifier, parce que ce coup-ci le silence est possible

Recharger la page de la PR et **regarder les deux images se rendre**. C'est le
seul contrôle qui vaille : une URL récoltée dans la mauvaise zone de texte, un
upload refusé pour la taille, un `uuid` tronqué — tout ça produit une
description qui a l'air juste et deux icônes cassées.

Si le rendu est cassé, le dire plutôt que réessayer en boucle : les captures
sont dans le scratchpad, l'utilisateur les colle en dix secondes depuis
l'interface web. Ce chemin manuel reste le repli, il n'a jamais cessé d'exister.

## Ce qui reste interdit

Un `![](…)` mort dans une description poussée, et une PR illustrée annoncée
sans que les images se rendent. Une capture qui a l'air d'une preuve est pire
qu'une absence de capture — c'est déjà la règle de `slash:chrome-ancrage`, elle
vaut aussi une fois l'image sur GitHub.
