---
name: captures-github
description: >
  Pose des images — captures avant/après, schéma, trace d'exécution — sur un
  écrit GitHub : description de pull request, commentaire de PR ou de ticket,
  commentaire de code review. `gh` ne sait pas uploader d'image et GitHub
  n'expose aucune API pour les pièces jointes ; le seul chemin passe par le
  navigateur du serveur MCP `chrome`, qui dépose les fichiers dans une zone de
  commentaire pour n'en récolter que les URL. Le texte, lui, reste écrit par
  `gh` dans tous les cas. Un seul point d'arrêt : la connexion GitHub, qui est
  un geste d'utilisateur.
  Use when about to publish anything on GitHub that contains an image — before
  `gh pr create`, `gh pr edit --body`, `gh pr comment`, `gh pr review`,
  `gh issue comment` — and whenever a PR description has a « Screenshots »
  section to fill. Also when the user says « mets les captures », « ajoute les
  screenshots », « illustre la PR », « colle l'image dans le commentaire »,
  « sers-toi du champ de commentaire pour les URL ».
  Ne PAS utiliser pour décider s'il faut des captures ni pour les cadrer
  (→ `slash:redaction`), ni pour les prendre (→ `slash:chrome-ancrage`).
---

# Poser des images sur un écrit GitHub

## Le principe qui commande tout le reste

**Le navigateur ne sert qu'à héberger les images ; `gh` écrit le texte.**

C'est ce partage qui évite toute une classe de dégâts. Un éditeur GitHub ouvert
dans le navigateur pendant qu'on pousse le même texte par `gh` finit par écraser
l'un des deux états, au hasard — et c'est le genre de perte qu'on ne remarque
qu'une fois la PR relue. Le navigateur ne soumet donc jamais rien : il dépose des
fichiers, on récolte les URL, on repart.

La règle vaut pour **toutes** les surfaces, description comme commentaire. Il n'y
a qu'un geste à retenir.

## La connexion GitHub, une fois pour toutes

Le profil d'un worktree est cloné depuis `~/.cache/chrome-mcp/_modele` à sa
**naissance**. Une session GitHub ouverte dans le modèle est donc héritée par
tous les worktrees créés ensuite — c'est déjà comme ça que Dashlane arrive.

Le bon geste, une seule fois : `bin/chrome-modele.sh`, se connecter à GitHub,
fermer le navigateur pour que les cookies s'écrivent. Les worktrees déjà nés
n'en profitent pas — le clonage a eu lieu —, il faut s'y connecter une fois
chacun. C'est aussi le cas quand la session héritée a expiré.

**Une page de connexion est un point d'arrêt, pas un obstacle à contourner.**
Rendre la fenêtre et demander la connexion. Ne pas saisir d'identifiant, ne pas
piloter Dashlane, ne pas toucher à une 2FA. Une fois connecté, les dépôts
suivants dans ce worktree ne redemandent rien.

## Le geste

Charger `slash:chrome-ancrage` avant la première action navigateur, comme pour
n'importe quel pilotage. `mcp__chrome__upload_file` accepte l'`uid` d'un input
fichier **ou d'un élément qui ouvre le sélecteur**, ce qui suffit ici.

1. **Écrire le texte sans les images** et le pousser par `gh` — `pr edit
   --body-file`, `pr comment --body-file`, ce qu'il faut selon la surface. La
   section « Screenshots » existe déjà, vide.
2. **Ouvrir la page cible.** Vérifier l'URL **et le numéro de PR ou de ticket**
   avant de toucher à quoi que ce soit : un commentaire parti sur la PR d'un
   autre worktree est irrattrapable.
3. **Déposer les fichiers dans la zone de nouveau commentaire** — jamais dans un
   éditeur de description, jamais dans un champ de review ouvert. `upload_file`
   avec les chemins des captures du scratchpad, qui sont bien locaux à la machine
   du navigateur.
4. **Récolter les URL.** GitHub insère dans la zone un
   `![nom](https://github.com/user-attachments/assets/<uuid>)` par fichier.
5. **Vider la zone sans la soumettre.** Le dépôt a eu lieu, les URL vivent, le
   commentaire n'a aucune raison d'exister.
6. **Réécrire le fichier de corps avec les URL** et le repousser par `gh`.

## Selon la surface

Le geste ne change pas ; seules les étapes 1 et 6 changent de commande.

| Ce qu'on publie | Étapes 1 et 6 | Où déposer, étape 3 |
| --- | --- | --- |
| Description de PR | `gh pr edit --body-file` (ou `gh pr create --body-file` pour la première) | La zone de commentaire de cette PR |
| Commentaire de PR ou de ticket | `gh pr comment --body-file` / `gh issue comment --body-file` | La zone de commentaire de cette même page |
| Commentaire de code review, global ou sur une ligne | `gh pr review --body-file`, ou `gh api` pour un commentaire ancré à une ligne | La zone de commentaire de la PR, **pas** le champ de review |

Une review se rédige et se soumet d'un bloc : si on y dépose les images en même
temps qu'on écrit, on n'a plus de moyen de récolter les URL sans soumettre. D'où
le passage obligé par la zone de commentaire ordinaire, qu'on vide ensuite.

## Là où ça coincera probablement

L'étape 4. La zone de commentaire de GitHub n'est pas garantie être un
`<textarea>` : selon l'éditeur servi, lire `.value` peut renvoyer vide alors que
le markdown est bien là. Prendre un `take_snapshot` avant de conclure à un échec
de dépôt, et lire le contenu réellement rendu plutôt que le champ supposé.

Un dépôt réussi dont on n'arrive pas à récolter l'URL n'est pas un dépôt raté :
l'image existe sur GitHub, il n'y a qu'à retrouver son adresse.

Quand ce point sera tranché sur un cas réel, écrire ici ce qui a marché — ce
fichier a été rédigé sur la mécanique, pas encore sur l'épreuve.

## Vérifier, parce que ce coup-ci le silence est possible

Recharger la page et **regarder les images se rendre**. C'est le seul contrôle
qui vaille : une URL récoltée dans la mauvaise zone de texte, un fichier refusé
pour sa taille, un `uuid` tronqué — tout ça produit un texte qui a l'air juste
et des icônes cassées.

## Le repli, qui n'a jamais cessé d'exister

Si le rendu est cassé, le dire plutôt que réessayer en boucle. Les captures sont
dans le scratchpad : l'utilisateur les colle en dix secondes depuis l'interface
web, et c'est une issue acceptable.

Ce qui ne l'est pas : pousser un `![](…)` mort, et annoncer un écrit illustré
dont les images ne se rendent pas. Une capture qui a l'air d'une preuve est pire
qu'une absence de capture — c'est la règle de `slash:chrome-ancrage`, elle vaut
aussi une fois l'image sur GitHub.
