# Rédiger une description de pull request

À lire **avant** de rédiger, pas après. `SKILL.md` porte le format et les règles
qui ne se délèguent pas ; ce fichier porte ce qui ne tenait pas dedans — ce
qu'on garde du gabarit du dépôt, la mécanique des captures, et les deux formes
de « Comment tester ».

## Ce qu'on garde du gabarit du dépôt

Sur **slash-web**, aucun gabarit : le format du `SKILL.md` tel quel, sans la case de
nature ni la checklist.

Sur **slash-interim**, `.github/pull_request_template.md` en fournit un, et on
ne s'y plie pas : on garde sa **substance**, pas sa mise en page.

| Du gabarit | Ce qu'on en fait |
| --- | --- |
| La ligne de liaison Linear | Gardée, en tête |
| La liste `Hotfix` / `Bug` / `Feature` / `Refacto / Tech` | Gardée **entière**, nue sous la ligne Linear, avec la ou les cases qui s'appliquent cochées. Ne garder que la ligne cochée n'est plus une liste de cases, et prive le relecteur de ce qui a été écarté. Elle porte la nature de la PR : ne la redis pas en prose |
| `# 🎯 Description`, `### Explication` | **Retirés.** Deux étiquettes qui n'annoncent rien qu'on ne sache déjà — les sections qu'elles contiennent *sont* la description et l'explication — et deux crans d'imbrication en trop |
| `# 📸 Screenshot` | Gardé, au singulier du gabarit, en `## 📸 Screenshot`. Retiré quand l'UI ne bouge pas, son propre commentaire le donnant pour conditionnel |
| `# 🧭 Tests` | Devient **`## 🧪 Comment tester`** : même section, un titre qui dit au relecteur ce qu'on attend de lui au lieu de ce qu'on a fait |
| `# ✅ Checklist` | Gardée, cases comprises, en `## ✅ Checklist` |

Rien de ce qu'un relecteur y cherche ne disparaît — nature de la PR,
explication, captures, tests, checklist. Ce qui change est le balisage — nos titres, tous en `##` — plus la
section « Contexte » que le gabarit n'avait pas.

Le renommage de `# 🧭 Tests` répare précisément ce que son commentaire cassait :
« décrire comment tu as testé la PR » désigne le mauvais lecteur, et c'est ce qui
produit la version « avant » de la PR #942 dans `exemples.md`. Le
titre porte maintenant la bonne consigne.

**En contrepartie, tes PR ne ressemblent plus tout à fait à celles de
l'équipe**, qui repère `# 🎯 Description` et `# 🧭 Tests`. C'est un arbitrage
assumé, pas un oubli : si un relecteur s'en plaint, c'est le gabarit qu'il faut
faire évoluer, pas la description qu'il faut replier dedans.

## « Screenshot » : dès que l'UI bouge

Un relecteur qui a vu l'écran sait ce qu'il cherche avant de recetter. Et la
capture est le seul endroit où un libellé tronqué, une couleur ou un décalage
se voient : le diff ne les montre pas, et le script de recettage suppose déjà
qu'on sait à quoi ressemble le bon résultat.

La section existe **dès que le diff touche quelque chose de visible** — un
écran, un composant, un mail, un PDF, un export mis en forme. Un changement de
CSS compte ; un renommage de variable non.

**Un avant/après**, cadré sur la zone qui change et non sur la fenêtre entière,
où le relecteur devra chercher ce qui a bougé. Côte à côte plutôt qu'empilées :
la comparaison est le but.

```markdown
## 📸 Screenshot

| Avant | Après |
|---|---|
| ![](…) | ![](…) |
```

**L'« avant » ne se rattrape pas.** Le correctif en place, l'écran fautif
n'existe plus : la capture se prend au constat mode « avant », ou elle est
perdue. Une PR d'UI sans « avant » est presque toujours une PR dont la capture
a été oubliée au seul moment où elle était possible.

Sur slash-interim, le gabarit livre la section et son commentaire la donne
lui-même pour conditionnelle : si l'UI ne bouge pas, la **retirer** plutôt que
d'y écrire « N/A ».

**L'upload, c'est nous.** `gh` ne sait pas poser d'image sur GitHub et il
n'existe aucune API pour ça, mais le navigateur du serveur MCP `chrome` sait le
faire — la marche à suivre est dans `screenshots-github.md`, à lire
dès qu'il y a des captures à poser. Un seul point d'arrêt : la connexion GitHub
dans ce navigateur, qui est un geste d'utilisateur. Le repli, si ça résiste,
reste les captures dans le scratchpad et l'utilisateur qui les colle.

Ce qui reste interdit dans tous les cas : pousser un `![](…)` mort, et annoncer
une PR illustrée dont les images ne se rendent pas.

## « Comment tester » : la section qui ne se supprime pas

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

Prérequis : une annonce dont le champ `localisation` est renseigné mais dont le
géocodage n'a pas abouti.

1. Ouvrir sa page de détail → la pastille affiche la ville et le code postal, au
   lieu de l'icône seule.
2. Ouvrir une annonce géocodée → affichage inchangé, au format près :
   `Ville (73460)` et non `Ville ( 73460 )`.
3. Ouvrir une annonce sans aucune localisation → « Localisation non précisée ».
```

Ce script ne s'invente pas au moment de la PR : c'est celui de `slash:constat`
mode « après », déroulé à la validation de la résolution. Le recopier, pas le
refaire.

**Variante — le script écrit, non joué.** Même script, mêmes attendus, une ligne
de préambule qui dit qu'il n'a pas été déroulé et pourquoi :

> ⚠️ Recette manuelle non jouée — à faire en review : `ats_command_candidate` est
> vide en local et je n'ai pas de session interne authentifiée.

Le relecteur sait alors qu'il essuie les plâtres. La raison est obligatoire et
porte sur un empêchement : « la table est vide et le flag est off partout » en est
une, « pas eu le temps » n'en est pas une. Sans le préambule c'est un mensonge ;
sans la raison, c'est la dérobade de la forme 2.

**Forme 2 — rien à recetter à la main.** Une phrase, avec sa raison et ce qui
couvre à la place :

> Aucun recettage manuel nécessaire : extraction d'un helper à comportement
> constant, couverte par les tests existants de `job-location.spec.ts`.

Ce qui tranche entre les deux formes : **si la PR change quoi que ce soit qu'un
utilisateur peut percevoir** — un écran, une réponse d'API, un mail, un export,
un délai —, il y a un script. « C'est couvert par les tests » n'est une raison
valable que si rien de perceptible n'a bougé ; sinon c'est une dérobade, et le
relecteur la verra comme telle.

À la suite du script, s'il y a lieu, ce que le relecteur ne peut pas deviner et
qui peut le surprendre en prod :

- un effet de bord assumé (un changement visuel, un format qui bouge) ;
- une décision discutable, énoncée comme telle ;
- ce que tu as volontairement laissé de côté, et pourquoi.

Ces trois-là restent facultatifs. Le script, lui, ne l'est pas.

Ils peuvent se plier dans un `<details><summary>Points de vigilance pour la
review</summary>`. Replier n'est pas une dispense d'élagage : le contenu du bloc
obéit aux mêmes règles que le reste de la description, et le hors-périmètre y
reste interdit — il va dans l'autre ticket.
