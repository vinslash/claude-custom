---
name: redaction
description: >
  Cadre de rédaction des écrits destinés à un relecteur humain : descriptions de
  pull request, commentaires de code review, messages de commit, et livrables
  écrits longs — document de plan, handoff, analyse, dossier de décision. Impose
  une description courte, en prose, qui dit le POURQUOI que le diff ne dit pas,
  et bannit les tableaux de recette exhaustifs, les snippets recopiés du diff et
  les détails d'outillage sans conséquence pour le relecteur. Sur les livrables
  longs, impose une passe d'élagage avant de rendre — plaidoirie, hors-périmètre
  et méta-commentaire dehors — et donne un exutoire borné au détail technique
  coûteux à reproduire : un commentaire Linear ou PR.
  Use when about to run `gh pr create`, `gh pr edit --body`, `gh pr review`,
  `gh pr comment`, or `git commit`; before handing over any long written
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

Vise **150 à 250 mots**. Trois sections, jamais plus :

```markdown
Closes [SLI-XXXX](lien Linear)

## Le problème
2 à 4 phrases. Ce qui ne marchait pas, et la cause réelle — pas les symptômes.
Un lien vers un exemple reproductible si tu en as un.

## Le correctif
2 à 4 phrases. L'approche retenue et pourquoi elle est la bonne. Si elle
s'appuie sur un helper ou un pattern déjà en place ailleurs, dis-le : ça
rassure plus que n'importe quelle preuve.

## À vérifier en recette
Seulement s'il y a vraiment quelque chose. Voir ci-dessous.
```

Écris en **prose**. Des phrases, pas une avalanche de puces. Trois paragraphes
courts se lisent plus vite qu'une liste de douze items.

Ces 150 à 250 mots valent **par PR**. Si le diff dépasse 400 lignes ou 15
fichiers porteurs de logique, le problème n'est plus la description : charger
`slash:decoupage-pr` avant de rédiger, parce qu'il y a peut-être trois PR à
écrire et non une.

### La seule section où le détail est rentable

« À vérifier en recette » sert à ce que le relecteur ne peut pas deviner et qui
peut le surprendre en prod :

- un effet de bord assumé (un changement visuel, un format qui bouge) ;
- une décision discutable, énoncée comme telle ;
- ce que tu as volontairement laissé de côté, et pourquoi.

Pour les tests, **une phrase suffit** : ce qui a été couvert, pas comment. « Testé
en local sur trois cas — annonce géocodée, annonce sans marqueur, annonce sans
localisation » vaut mieux qu'un tableau de trois lignes avec les valeurs exactes.

Si tu n'as rien de tout ça à signaler, supprime la section. Ne la remplis jamais
pour la forme.

## Ce qui ne va pas dans une PR

À bannir, sans exception :

- **le tableau de recette exhaustif** — valeurs testées, avant/après ligne à
  ligne, IDs des fixtures. Ça, c'est ton rapport à celui qui t'a demandé le
  travail, pas la PR ;
- **le snippet recopié du diff** — le relecteur a le diff, en mieux et en couleur ;
- **la liste des fichiers touchés** — GitHub l'affiche déjà ;
- **les détails d'outillage sans conséquence** — `msgfmt`, la commande docker, le
  nom du conteneur. Si ça ne change rien pour le relecteur, ça dégage ;
- **les valeurs de test énumérées** — les trois IDs d'agence, les slugs des
  fixtures ;
- **les sections vides** remplies pour respecter un gabarit ;
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
| la solution — pourquoi cette approche, ce qui a été écarté | la **PR** : le relecteur le lit sur place |

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
ticket, pas en commentaire de celui-ci.

## Commentaires de code review

Une remarque utile tient en trois temps : **le problème, sa conséquence, ce que tu
proposes**. Sans la conséquence, l'auteur ne sait pas s'il doit corriger ; sans la
proposition, il ne sait pas par quoi remplacer.

Qualifie systématiquement le poids de la remarque — bloquant, suggestion, ou nit —
sinon l'auteur traite tout au même niveau et perd son temps sur des broutilles.

Ne commente jamais pour paraphraser le code. Si tu n'as rien à redire, ne dis rien.

## Messages de commit

Reprends la convention du dépôt (dans slash-web : `:emoji: SLI-XXXX: sujet à
l'infinitif`). Le sujet dit *quoi*, le corps dit **pourquoi c'était nécessaire** —
pas comment, le diff s'en charge.

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

## Exemples

Avant de rédiger, lis `references/exemples.md` : des paires avant/après tirées de
vraies PR, annotées. Elles portent plus que les règles ci-dessus.

Quand tu produis une description qui se fait retoquer par l'utilisateur,
**ajoute la paire à ce fichier**. C'est comme ça que ce skill s'affine.
