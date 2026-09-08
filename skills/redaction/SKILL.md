---
name: redaction
description: >
  Cadre de rédaction des écrits destinés à un relecteur humain : descriptions de
  pull request, commentaires de code review, messages de commit, et livrables
  écrits longs — document de plan, handoff, analyse, dossier de décision. Impose
  une description courte, en prose et en quatre sections — contexte, problème,
  correctif, comment tester —, qui dit le POURQUOI que le diff ne dit pas.
  Impose sur toute PR une section « Comment tester » — le script que le relecteur
  déroule avant de lire le code, ou la raison qu'il n'y en ait pas —, une
  section « Screenshots » en avant/après dès que l'UI bouge, et bannit
  les preuves de test exhaustives, les snippets recopiés du diff et les détails
  d'outillage sans conséquence pour le relecteur. Sur les livrables
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

Vise **150 à 250 mots**. Quatre sections rédigées — ni plus, ni moins —, une
cinquième dès que l'UI bouge, et sur slash-interim les deux pièces du gabarit
qui se cochent au lieu de s'écrire :

```markdown
Close [SLI-XXXX](lien Linear)

- [ ] Hotfix                 ← slash-interim : la liste du gabarit, entière,
- [x] Bug                       avec la ou les cases qui s'appliquent cochées
- [ ] Feature
- [ ] Refacto / Tech

## 🗺️ Contexte
2 à 3 phrases, jamais de puces. Où on est : quel module, quel écran, quel
flux. Le relecteur ne connaît pas forcément la zone, et sans ce point d'appui
tout ce qui suit flotte.

## 🐛 Le problème
2 à 4 phrases. Ce qui ne marchait pas, et la cause réelle — pas les symptômes.
Un lien vers un exemple reproductible si tu en as un. Sur une feature, c'est
« ## ✨ Le besoin », et il dit ce qui manque, jamais la solution.

## 🔧 Le correctif
2 à 4 phrases. L'approche retenue et pourquoi elle est la bonne. Si elle
s'appuie sur un helper ou un pattern déjà en place ailleurs, dis-le : ça
rassure plus que n'importe quelle preuve.

## 📸 Screenshot
Seulement si l'UI bouge — et alors obligatoire. Un avant/après cadré sur la
zone qui change.

## 🧪 Comment tester
Les étapes que le relecteur déroule avant d'ouvrir le diff, avec l'attendu à
chacune. Ou la phrase qui dit pourquoi il n'y en a pas.

## ✅ Checklist              ← slash-interim : celle du gabarit, entière aussi
```

Tous les titres au même niveau, `##`, et un emoji par section — celui du
problème suit la nature de la PR, 🐛 ou ✨.

Écris en **prose**. Des phrases, pas une avalanche de puces. Trois paragraphes
courts se lisent plus vite qu'une liste de douze items.

Des puces dans « Le correctif » seulement quand les changements sont
**réellement disjoints** — trois chantiers indépendants dans une même PR,
chacun sa puce. Un raisonnement continu débité en puces perd ses liens
logiques, qui étaient précisément tout ce qu'il restait à apporter.

Ces 150 à 250 mots comptent les trois sections de prose, contexte compris : le
plafond ne monte pas parce qu'une section s'ajoute. Une partie de ce qu'on
écrivait sous « Le problème » servait à situer le lecteur, et remonte
simplement d'un cran. Le script de recettage se compte à part, en étapes : cinq
au plus.

Ces bornes valent **par PR**. Si le diff dépasse 400 lignes ou 15 fichiers
porteurs de logique, le problème n'est plus la description : charger
`slash:decoupage-pr` avant de rédiger, parce qu'il y a peut-être trois PR à
écrire et non une.

### Ne pas écraser ce qui est déjà là

Une description se régénère souvent sur une PR déjà ouverte. Avant tout
`gh pr edit --body`, relire le corps en place et reporter dans le nouveau :

- la **ligne de liaison Linear** en tête — `Close`, `Ref` ou `Part of` selon le
  cas, et `slash:decoupage-pr` tranche lequel sur une pile ;
- ce que l'auteur a **écrit à la main** et que le diff ne redonne pas : captures
  d'écran, lien de déploiement, note de rollout. Sous son titre d'origine.

Une description régénérée qui perd la capture de l'auteur est une régression,
pas une amélioration.

### Avant de rédiger, lire la référence

`references/pull-request.md` porte ce qui ne tient pas ici : ce qu'on garde du
gabarit de slash-interim et ce qu'on en retire, la mécanique des captures —
cadrage, avant/après, pose sur GitHub par le navigateur —, et les deux formes de
« Comment tester » avec leurs exemples. **À lire avant d'écrire le texte**,
comme `livrables-longs.md` avant de rendre un plan.

Trois règles ne se délèguent pas à une lecture, et valent même si la référence
n'a pas été ouverte :

- **« Comment tester » est toujours présente**, sous l'une de ses deux formes —
  le script, ou la phrase qui dit pourquoi il n'y en a pas. Jamais absente,
  jamais un « N/A ». Et **une seule** section, jamais un découpage « Tests
  automatisés » / « Recette manuelle » : le bloc « automatisé » est une cachette,
  où le script manuel devient la garniture facultative.
- **« Screenshot » existe dès que le diff touche quelque chose de visible** — un
  écran, un composant, un mail, un PDF, un export mis en forme. Un changement de
  CSS compte ; un renommage de variable non.
- **Le gabarit du dépôt ne s'épouse pas** : on garde sa substance — la case de
  nature, les captures, les tests, la checklist — et nos titres, tous au niveau
  `##`. Ses deux étiquettes sans contenu propre, `# 🎯 Description` et
  `### Explication`, disparaissent.
## Ce qui ne va pas dans une PR

À bannir, sans exception :

- **la preuve de test exhaustive** — valeurs testées, avant/après ligne à ligne,
  IDs des fixtures. Ça, c'est ton rapport à celui qui t'a demandé le travail, pas
  la PR. Le « Comment tester » dit au relecteur **ce qu'il a à faire**, il ne lui
  prouve pas que tu l'as fait ;
- **le snippet recopié du diff** — le relecteur a le diff, en mieux et en couleur ;
- **la liste des fichiers touchés** — GitHub l'affiche déjà ;
- **les détails d'outillage sans conséquence** — `msgfmt`, la commande docker, le
  nom du conteneur. Si ça ne change rien pour le relecteur, ça dégage ;
- **les valeurs de test énumérées** — les trois IDs d'agence, les slugs des
  fixtures. Sauf celles dont le relecteur a besoin pour atteindre le cas : là,
  elles sont le prérequis du script ;
- **les sections vides** remplies pour respecter un gabarit — « Comment
  tester » comprise : une section sans attendu ne vaut pas mieux qu'une section absente ;
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
