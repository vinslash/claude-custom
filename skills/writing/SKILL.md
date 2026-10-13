---
name: writing
description: >
  Cadre de rédaction des écrits destinés à un relecteur humain : descriptions de
  PR, commentaires de review, messages de commit, issues et tickets Linear, et
  livrables longs — plan, handoff, analyse. Sur une PR, impose la pyramide de
  slash-interim — ligne de tête, Description de soixante mots qui dit le
  POURQUOI, Schéma SVG, Preuve de test avant/après, Impact, « Pour la review »
  replié —, plus « Comment tester » hors slash-interim ; là où le dépôt a son
  skill de PR ou de commit, celui-ci fait foi pour la structure. Sur une issue,
  impose l'encart Problème, Valeur, Risque, Taille. Sur un livrable long,
  impose une passe d'élagage avant de rendre.
  Use when about to run `gh pr create`, `gh pr edit --body`, `gh pr review`,
  `gh pr comment`, `gh issue create`, `Linear:save_issue`, or `git commit`;
  before drafting a GitHub issue or a Linear ticket; before handing over any long written
  deliverable a human will review, including a plan submitted through
  `ExitPlanMode`; when the user says « ouvre une PR », « fais la PR », « rédige
  la description », « décris la PR », « commente la review », « relis cette PR »,
  « message de commit », « rédige le commit », « rédige le plan », « fais-moi un
  document », « prépare le handoff », « c'est illisible », « trop de texte »; and
  whenever producing text a human teammate will read on GitHub or in Linear. À
  charger AVANT d'écrire le texte, pas après l'avoir écrit. Ne PAS utiliser pour
  la rédaction destinée à l'utilisateur dans le chat — le rapport d'étape de
  trois à cinq lignes —, ni pour la documentation technique de fond (README, ADR).
---

# Rédaction pour un relecteur humain

## Le principe qui commande tout le reste

**Le relecteur a trente secondes et il a déjà le diff.** Le diff lui dit *quoi* a
changé. Il ne lui dit pas pourquoi c'était cassé, pourquoi cette approche-là, ni
où poser son attention. C'est ça, et seulement ça, que ton texte doit apporter.

Tout ce que le relecteur pourrait reconstituer en lisant le diff est du bruit qui
dilue le peu qui compte. Une description longue n'est pas plus rigoureuse : elle
est moins lue.

## Description de pull request

### Qui tient la structure

| Dépôt | Structure et mécanique | Ce skill |
| --- | --- | --- |
| **slash-interim** | `slash-create-pr`, son template et le hook `pr-body-budget.sh`, qui refuse tout titre en plus | la façon d'écrire, rien d'autre — aucune section ajoutée, pas de « Comment tester » |
| **wtkit** | son `.github/pull_request_template.md` et son skill `create-pr` | la façon d'écrire |
| **ailleurs** (slash-web, claude-custom…) | la pyramide ci-dessous | tout |

Partout, c'est la même pyramide : celle de slash-interim, qui a fait ses preuves,
plus une section « Comment tester » là où aucun sous-ticket de tests ne porte la
recette.

```markdown
Close [SLI-XXXX](lien Linear) · 🟢 **Risque faible** · **Commencer par** `chemin/du/fichier`

## 📝 Description
**Bug** · le problème, puis ce que la PR change. Soixante mots au plus.

## 🗺️ Schéma
<div align="center">

![Ce que la PR modifie](schema.svg)

</div>

## ✅ Preuve de test
| Avant | Après |
| :---: | :---: |
| ![Avant](avant.png) | ![Après](apres.png) |

<sub>**Non testé** : ce qui n'a pas été vérifié, ou « rien ».</sub>

## 🧪 Comment tester
1. L'étape → l'attendu. Cinq étapes au plus.

## 🎯 Impact
- **Ce qui peut casser** — en mots, soixante au plus.

<details>
<summary><b>Pour la review</b></summary>

Ce qu'un relecteur doit savoir et qu'il ne déduira pas du diff.

</details>
```

**La ligne de tête**, seule avant la Description : le lien qui referme le ticket
(`Close`, ou `Part of` / `Ref` quand la PR ne le referme pas seule ; `Closes #N`
pour une issue GitHub, mot-clé anglais obligatoire), le risque en couleur — 🟢
faible, 🟠 moyen, 🔴 élevé —, et le fichier par lequel le relecteur commence.

**La Description** s'ouvre sur la nature en gras — `**Hotfix**`, `**Bug**`,
`**Feature**`, `**Tech**`, ou `**Doc**` pour un diff de documentation seule —,
puis dit le problème et ce que la PR change, en prose. **Soixante mots** : ce
que le ticket et le diff ne disent pas déjà, et rien d'autre. Une PR qui livre
une fonctionnalité entière tient dans les mêmes soixante mots qu'un correctif,
parce que ce qu'elle doit dire est le POURQUOI, pas l'inventaire.

**Le Schéma** est une image SVG de ce que la PR modifie — un avant/après, un
flux dont le trajet modifié est en couleur, une règle de décision —, jamais un
inventaire de fichiers, **jamais du Mermaid**. Pour une interface, une capture
ou un GIF le remplace. La charte est dans `references/schema.md`.

**La Preuve de test** montre un état, pas un déroulé : l'avant et l'après, en
images dès que possible — capture d'écran pour une UI, test rouge sur la base et
vert sur HEAD pour un bug, requête et réponse pour une API. Sans image possible,
une phrase à la place du tableau, quarante mots au plus. La ligne **Non testé**
est obligatoire. Une PR `Doc` n'a pas de Preuve de test.

**Comment tester**, hors slash-interim seulement, est le script que le relecteur
déroule avant d'ouvrir le diff. Dans slash-interim, la recette vit dans le
sous-ticket de tests (`slash-create-test-scenarios`), et le template n'a pas de
place pour elle.

**L'Impact** dit, en mots, ce que la PR peut casser et pourquoi ça ne se
produit pas : jamais de code, de chemin ni de nom de symbole. Sur slash-interim,
une puce par label posé, puis les labels écartés.

**Pour la review**, replié, reçoit ce qui aide le relecteur sans tenir dans les
budgets : le détail technique, les décisions discutables, ce qui a été laissé
de côté et pourquoi. Replier n'est pas une dispense d'élagage.

Aucun autre titre, à aucun niveau.

### Ne pas écraser ce qui est déjà là

Une description se régénère souvent sur une PR déjà ouverte. Avant tout
`gh pr edit --body`, relire le corps en place et reporter dans le nouveau :

- la **ligne de liaison** en tête ;
- ce que l'auteur a **écrit à la main** et que le diff ne redonne pas : captures
  d'écran, lien de déploiement, note de rollout.

Une description régénérée qui perd la capture de l'auteur est une régression,
pas une amélioration.

### Avant de rédiger, lire la référence

`references/pull-request.md` porte ce qui ne tient pas ici : la pose des images,
et les deux formes de « Comment tester » avec leurs exemples. **À lire avant
d'écrire le texte**, comme `livrables-longs.md` avant de rendre un plan.

Trois règles ne se délèguent pas à une lecture, et valent même si la référence
n'a pas été ouverte :

- **Hors slash-interim, « Comment tester » est toujours présente**, sous l'une
  de ses deux formes — le script, ou la phrase qui dit pourquoi il n'y en a pas.
  Jamais un « N/A ». Et **une seule** section, jamais un découpage « Tests
  automatisés » / « Recette manuelle » : le bloc « automatisé » est une cachette,
  où le script manuel devient la garniture facultative.
- **Dès que le diff touche quelque chose de visible** — un écran, un composant,
  un mail, un PDF, un export mis en forme —, la Preuve de test porte une capture
  avant/après. Un changement de CSS compte ; un renommage de variable non.
- **Les images se posent, elles ne se demandent pas.** `gh` les joint avec
  `--attach` depuis sa version 2.99 ; `slash:github-screenshots` reste le repli
  quand `gh` ne le peut pas. Rendre la main avec des chemins de scratchpad n'est
  pas une option.

## Un paragraphe, une seule ligne

GitHub et Linear rendent **chaque retour à la ligne comme un `<br>`**. Une prose
pré-wrappée à 80 colonnes impose donc sa mise en page au lecteur : dès qu'il
rétrécit sa fenêtre, ouvre la PR sur son téléphone ou déplie la barre latérale,
chacune de ces lignes se re-wrappe pour son compte et le paragraphe tombe en
escalier de moignons — « relevés de », « que la », « 8202 → ». Le défaut ne se
voit pas depuis la fenêtre large où on a rédigé : il ne se constate que chez
celui qui lit.

Donc, dans tout texte publié sur GitHub ou Linear : **un paragraphe s'écrit sur
une seule ligne**, aussi longue qu'il le faut, et c'est le rendu qui décide où
couper. Une ligne vide entre les paragraphes. Une puce, une étape de « Comment
tester », une cellule de tableau : une ligne chacune, continuation comprise.

L'exception est le **message de commit**, lu dans un terminal qui ne re-wrappe
rien : sujet et corps restent wrappés à 72 colonnes.

## Ce qui ne va pas dans une PR

À bannir, sans exception :

- **la preuve de test exhaustive** — valeurs testées, tours de recette,
  historique de CI, compteurs de tests que la CI affiche déjà. La Preuve de test
  montre un état, l'avant et l'après ; le reste est ton rapport à celui qui t'a
  demandé le travail, pas la PR ;
- **le snippet recopié du diff** — le relecteur a le diff, en mieux et en couleur ;
- **la liste des fichiers touchés** — GitHub l'affiche déjà ;
- **les détails d'outillage sans conséquence** — `msgfmt`, la commande docker, le
  nom du conteneur. Si ça ne change rien pour le relecteur, ça dégage ;
- **les valeurs de test énumérées** — les trois IDs d'agence, les slugs des
  fixtures. Sauf celles dont le relecteur a besoin pour atteindre le cas : là,
  elles sont le prérequis du script ;
- **les sections vides** remplies pour respecter un gabarit — « Comment
  tester » comprise : une section sans attendu ne vaut pas mieux qu'une section absente ;
- **le Mermaid**, nulle part dans une PR : GitHub en calcule la mise en page, et
  aucune charte ne s'y applique. Le Schéma est un SVG ;
- **l'auto-satisfaction** — « correctif propre et robuste », « refactoring
  élégant ». Le relecteur jugera.

Un détail technique ne se garde que s'il change quelque chose pour le relecteur :
sa décision de merger, ce qu'il ira regarder, ou ce qu'il devra surveiller après
déploiement. Sinon il tombe.

## Le détail technique qu'il serait dommage de perdre

Ce qui tombe d'une description ou d'un plan est le plus souvent à **supprimer**.
Mais il existe un cas où ce serait une perte : une analyse coûteuse à refaire —
investigation de cause racine, mesure, exploration de données, hypothèse
éliminée. Elle ne change aucune décision du relecteur, et quelqu'un la
rechercherait pourtant dans six mois.

Celle-là va dans un **commentaire**, jamais dans le corps du livrable :

| Ça explique… | Commentaire sur… |
| --- | --- |
| le problème — cause racine, données observées, analyse d'origine du ticket | le **ticket Linear** : ça survit à la PR, et c'est là qu'on le cherchera |
| la solution — pourquoi cette approche, ce qui a été écarté | le bloc **« Pour la review »** de la PR, ou un commentaire de la PR s'il dépasse ce qu'un relecteur lira |

**250 mots, un seul commentaire, jamais une série.** Au-delà, ce n'est plus un
commentaire mais un document : s'il le mérite, c'est un fichier dans le dépôt ;
sinon, c'est qu'il fallait le supprimer.

Ouvrir sur une ligne qui dit ce que c'est et qu'on peut ne pas le lire —
« Analyse à l'origine du ticket, gardée ici ; sans effet sur la relecture. » Un
commentaire non lu ne coûte rien, une description non lue est un échec.

Dans le livrable, **au plus une ligne de renvoi**, jamais un résumé du
commentaire : sinon la pollution revient par la fenêtre.

Ce n'est pas un commentaire de code review — celui-là s'adresse à l'auteur sur
un défaut. Celui-ci ne s'adresse à personne en particulier, il dépose.

Et le hors-périmètre n'entre pas dans ce couloir : son détail va dans l'autre
ticket s'il existe, et sinon nulle part — pas en commentaire de celui-ci.

## Commentaires de code review

Une remarque utile tient en trois temps : **le problème, sa conséquence, ce que tu
proposes**. Sans la conséquence, l'auteur ne sait pas s'il doit corriger ; sans la
proposition, il ne sait pas par quoi remplacer.

Qualifie systématiquement le poids de la remarque — bloquant, suggestion, ou nit —
sinon l'auteur traite tout au même niveau et perd son temps sur des broutilles.

Ne commente jamais pour paraphraser le code. Si tu n'as rien à redire, ne dis rien.

## Issues GitHub et tickets Linear

Le lecteur d'une issue n'est pas celui qui la traitera : c'est celui qui décide
si elle vaut d'être prise. Deux encarts, dans cet ordre :

```markdown
**Problème** — ce que l'utilisateur subit, pas la cause technique.
**Valeur** — qui y gagne quoi.
**Risque** — de le faire, et de ne pas le faire.
**Taille** — S, M ou L.

<details><summary>🤖 Notes pour l'agent</summary>

Causes, fichiers, pistes, mesures.

</details>
```

L'encart de tête tient en **120 mots au plus**, une ligne par champ. Si la ligne
**Valeur** ne s'écrit pas — personne ne subit le défaut aujourd'hui —, il n'y a
pas d'issue à ouvrir. Le bloc replié reçoit l'analyse coûteuse à refaire, au lieu
d'encombrer le corps. Les règles plus haut s'y appliquent : un paragraphe par
ligne, ni plaidoirie ni méta-commentaire.

Les quatre marqueurs en gras et la chaîne « 🤖 Notes pour l'agent » s'écrivent
**tels quels** : un hook de wtkit les vérifie à la création de l'issue.

Sur slash-interim, `slash-create-issue` garde la main sur le type, les labels et
la validation. Ce gabarit en est l'encart de tête ; les sections propres au type
viennent dessous, dans le corps, et le bloc replié ferme le ticket.

Rédiger une issue n'autorise pas à l'ouvrir : aucune ne se crée sans une demande
explicite de l'utilisateur pour ce sujet, et on cherche d'abord une issue
existante à compléter.

## Messages de commit

**Dans slash-interim, `slash-create-commit` fait foi** : titre seul, sans corps
ni `Co-Authored-By`. Ce skill n'a rien à y ajouter. **Dans wtkit**, c'est la
section « Commits & PR » de son `CLAUDE.md`.

Ailleurs, reprends la convention du dépôt (dans slash-web : `:emoji: SLI-XXXX:
sujet à l'infinitif`). Le sujet dit *quoi*, le corps dit **pourquoi c'était
nécessaire** — pas comment, le diff s'en charge.

Un corps de commit peut être plus détaillé qu'une description de PR : il est lu
plus tard, par quelqu'un qui fait un `git blame` sans aucun contexte.

## Les livrables longs

Un document de plan, un handoff, une analyse, un dossier de décision : même
lecteur, même principe, autre borne. Il n'a pas trente secondes mais dix
minutes, et il n'a pas le diff — il a une décision à prendre. Ce qui ne change
pas cette décision n'a rien à faire dans le document.

Viser **200 lignes**. Au-delà, ce n'est plus un plan mais un dossier : le
relecteur le survole au lieu de l'arbitrer, et son accord ne vaut plus rien.

Avant de rendre, lire `references/livrables-longs.md` et faire la passe
d'élagage qu'il décrit. Elle n'est pas optionnelle, et **si elle ne retire rien,
elle n'a pas été faite** : sur le cas qui a fondé cette règle, six allers-retours
ont ramené 841 lignes à 197 sans qu'une seule information soit perdue.

Trois choses qui tombent toujours :

- **la plaidoirie.** Énoncer la décision, point. Renvoyer à la règle du dépôt
  quand elle existe : c'est la règle qui justifie, pas le document. Justifier
  seulement quand ignorer le pourquoi conduirait à défaire la décision ;
- **le hors-périmètre.** Une ligne de renvoi, jamais son détail — même
  excellent, surtout excellent. C'est un autre ticket ;
- **le méta-commentaire sur notre conversation** — « remarque de X retenue »,
  « correction de ce que j'avais avancé », « les deux questions de Y ». Un
  document décrit l'état du monde, pas l'historique de sa rédaction.

Et une conversion qui gagne sur les deux tableaux : **la prose qui compare
devient un tableau, la prose qui énumère des acteurs devient un schéma
mermaid.** Plus court et plus clair du même geste, jamais l'un contre l'autre.
Dans un document ou un ticket seulement : dans une PR, le schéma est un SVG.

## Exemples

Avant de rédiger, lis `references/exemples.md` : des paires avant/après tirées de
vraies PR, annotées. Elles portent plus que les règles ci-dessus.

Quand tu produis une description qui se fait retoquer par l'utilisateur,
**ajoute la paire à ce fichier**. C'est comme ça que ce skill s'affine.

**Et écris-la dans `~/Development/claude-custom`, jamais dans le clone
installé.** Le chemin `references/exemples.md` résolu depuis
`~/.claude/skills/slash/` vise le clone, que personne ne doit éditer : un seul
fichier modifié dedans et le `merge --ff-only` de `bin/update.sh` refuse — toutes
les mises à jour s'arrêtent, sans que rien ne l'affiche. C'est arrivé le 22/09,
et ça n'a été vu que par un `/slash:force-update` lancé pour autre chose. Le
fichier à ouvrir est donc
`~/Development/claude-custom/skills/writing/references/exemples.md`.
