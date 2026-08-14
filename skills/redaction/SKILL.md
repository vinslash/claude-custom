---
name: redaction
description: >
  Cadre de rédaction des écrits destinés à un relecteur humain : descriptions de
  pull request, commentaires de code review, messages de commit. Impose une
  description courte, en prose, qui dit le POURQUOI que le diff ne dit pas, et
  qui bannit les tableaux de recette exhaustifs, les snippets recopiés du diff et
  les détails d'outillage sans conséquence pour le relecteur.
  Use when about to run `gh pr create`, `gh pr edit --body`, `gh pr review`,
  `gh pr comment`, or `git commit`; when the user says « ouvre une PR », « fais
  la PR », « rédige la description », « décris la PR », « commente la review »,
  « relis cette PR », « message de commit », « rédige le commit »; and whenever
  producing text a human teammate will read on GitHub. À charger AVANT d'écrire
  le texte, pas après. Ne PAS utiliser pour la rédaction destinée à l'utilisateur
  dans le chat, ni pour la documentation technique de fond (README, ADR).
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

## Exemples

Avant de rédiger, lis `references/exemples.md` : des paires avant/après tirées de
vraies PR, annotées. Elles portent plus que les règles ci-dessus.

Quand tu produis une description qui se fait retoquer par Vince, **ajoute la paire
à ce fichier**. C'est comme ça que ce skill s'affine.
