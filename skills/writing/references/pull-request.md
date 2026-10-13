# Rédiger une description de pull request

À lire **avant** de rédiger, pas après. `SKILL.md` porte la pyramide et les
règles qui ne se délèguent pas ; ce fichier porte ce qui ne tenait pas dedans —
la pose des images, et les deux formes de « Comment tester ».

## La pyramide vient de slash-interim

Le format d'avant — Contexte, Problème, Correctif, en 150 à 250 mots de prose —
a cédé la place au template de slash-interim, plus court et mieux tenu : une
Description de soixante mots, un schéma qui dit en dix secondes ce que la
prose disait en cent, une preuve qui montre au lieu de raconter, et un bloc
replié qui recueille ce qui débordait. Un hook du dépôt en vérifie les budgets,
ce qu'aucune consigne écrite n'avait obtenu.

Ce qu'on a gardé du format d'avant tient dans les règles de contenu de
`SKILL.md` — le POURQUOI plutôt que l'inventaire, la prose plutôt que les puces,
rien de ce que le diff dit déjà —, et dans la section « Comment tester », qui
survit **hors slash-interim** : là-bas, la recette a son sous-ticket.

## La Preuve de test : l'avant ne se rattrape pas

Un relecteur qui a vu l'écran sait ce qu'il cherche avant de recetter. Et la
capture est le seul endroit où un libellé tronqué, une couleur ou un décalage
se voient : le diff ne les montre pas.

**Un avant/après**, cadré sur la zone qui change et non sur la fenêtre entière,
côte à côte dans le tableau du template, les deux images à la même taille.

**L'« avant » ne se rattrape pas.** Le correctif en place, l'écran fautif
n'existe plus : la capture se prend au constat mode « avant », ou elle est
perdue. Pour un bug sans écran, l'avant est le test rouge sur la base : un
worktree détaché sur `origin/<base>` dans le scratchpad, le test copié dedans,
lancé, puis le worktree supprimé.

**La pose.** `gh` ≥ 2.99 joint les fichiers locaux avec `--attach` sur `gh pr
create`, `gh pr edit`, `gh pr comment` et `gh issue create` : référencer chaque
image par son chemin local, `![Avant](<scratchpad>/avant.png)` — jamais
`<img src>`, que `gh` ne réécrit pas — et `gh` le remplace par l'URL téléversée.

```bash
gh pr create --draft --body-file <scratchpad>/pr-body.md \
  --attach "<scratchpad>/schema.svg#Ce que la PR modifie" \
  --attach "<scratchpad>/avant.png#Avant" --attach "<scratchpad>/apres.png#Après"
```

Un envoi raté laisse la PR créée et sort en non-zéro : vérifier le code de
sortie, puis qu'aucun chemin local ne reste dans le corps publié (`gh pr view
--json body -q .body | grep -c '<scratchpad>'`).

Si `gh` est plus ancien ou si l'envoi résiste — une review ancrée aux lignes,
par exemple —, **`slash:github-screenshots`** pose les images par le navigateur.
Ce qui reste interdit dans tous les cas : pousser un `![](…)` mort, et annoncer
une PR illustrée dont les images ne se rendent pas.

## « Comment tester » : la section qui ne se supprime pas (hors slash-interim)

Chez nous, le relecteur assigné **recette d'abord et relit le code ensuite**. Il
n'a pas constaté le bug, il n'a pas le jeu de données en tête, et il ne sait pas
par où passer : c'est la description qui le lui donne, ou il saute l'étape.

Cette section est donc **toujours présente**, sous l'une des deux formes. Jamais
absente, jamais un « N/A ».

Et **une seule section**, jamais un découpage « Tests automatisés » / « Recette
manuelle » : un bloc « automatisé » est une cachette. Il se remplit de compteurs
de tests que la CI affiche déjà et dont aucune décision de merge ne dépend, et le
script manuel y devient la garniture facultative.

**Forme 1 — le script.** Des étapes numérotées, **cinq au plus**, chacune avec
son attendu — sans l'attendu, le relecteur voit l'écran sans savoir si c'est
bon. Une ligne de prérequis en tête quand le cas demande des données
particulières.

```markdown
## 🧪 Comment tester

Prérequis : une annonce dont le champ `localisation` est renseigné mais dont le géocodage n'a pas abouti.

1. Ouvrir sa page de détail → la pastille affiche la ville et le code postal, au lieu de l'icône seule.
2. Ouvrir une annonce géocodée → affichage inchangé, au format près : `Ville (73460)` et non `Ville ( 73460 )`.
3. Ouvrir une annonce sans aucune localisation → « Localisation non précisée ».
```

Ce script ne s'invente pas au moment de la PR : c'est celui de `slash:observe`
mode « après », déroulé à la validation de la résolution. Le recopier, pas le
refaire.

**Variante — le script écrit, non joué.** Même script, mêmes attendus, une ligne
de préambule qui dit qu'il n'a pas été déroulé et pourquoi :

> ⚠️ Recette manuelle non jouée — à faire en review : `ats_command_candidate` est vide en local et je n'ai pas de session interne authentifiée.

Le relecteur sait alors qu'il essuie les plâtres. La raison est obligatoire et
porte sur un empêchement : « la table est vide et le flag est off partout » en est
une, « pas eu le temps » n'en est pas une. Sans le préambule c'est un mensonge ;
sans la raison, c'est la dérobade de la forme 2.

**Forme 2 — rien à recetter à la main.** Une phrase, avec sa raison et ce qui
couvre à la place :

> Aucun recettage manuel nécessaire : extraction d'un helper à comportement constant, couverte par les tests existants de `job-location.spec.ts`.

Ce qui tranche entre les deux formes : **si la PR change quoi que ce soit qu'un
utilisateur peut percevoir** — un écran, une réponse d'API, un mail, un export,
un délai —, il y a un script. « C'est couvert par les tests » n'est une raison
valable que si rien de perceptible n'a bougé ; sinon c'est une dérobade, et le
relecteur la verra comme telle.

En plus du script, s'il y a lieu, ce que le relecteur ne peut pas deviner et
qui peut le surprendre en prod :

- un effet de bord assumé (un changement visuel, un format qui bouge) ;
- une décision discutable, énoncée comme telle ;
- ce que tu as volontairement laissé de côté, et pourquoi.

Ces trois-là restent facultatifs. Le script, lui, ne l'est pas.

Ils vont dans le bloc replié « Pour la review ». Replier n'est pas une dispense
d'élagage : le contenu du bloc obéit aux mêmes règles que le reste de la
description, et le hors-périmètre y reste interdit — il va dans l'autre ticket.
