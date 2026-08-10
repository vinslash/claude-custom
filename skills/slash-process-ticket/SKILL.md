---
name: slash-process-ticket
description: >
  Parcours complet de traitement d'un ticket Linear SLI dans un worktree
  slash-interim ou slash-web, du worktree déjà créé jusqu'à la PR ouverte. Impose
  l'ordre qui compte : analyser le ticket, CONSTATER le problème dans le
  navigateur avant d'écrire une ligne, faire arbitrer le plan, implémenter,
  faire constater la résolution, puis committer. Deux points d'arrêt bloquants
  où Vince valide explicitement — la validation du plan et la validation de la
  résolution. Délègue le jeu de données à `slash-recette-dataset` et la rédaction
  des écrits GitHub à `slash-redaction`.
  Use when the user says « mission : traiter ce ticket », « traite le ticket »,
  « on attaque SLI-XXXX », « je viens de créer le worktree », or
  `/slash-process-ticket SLI-XXXX`; and at the start of any session whose cwd is
  un worktree `sli-XXXX-*`. Ne PAS utiliser pour reprendre une PR déjà ouverte
  (→ `slash-redaction`), pour une review, ni pour un travail sans ticket
  Linear — exploration, question, correctif ponctuel demandé dans le chat.
---

# Traitement d'un ticket Linear, du worktree à la PR

## Pourquoi ce skill existe

Le réflexe naturel, sur un ticket, est de lire la description et de se mettre à
coder. Ça produit deux échecs classiques : on corrige quelque chose que personne
n'a vu casser, et on n'a rien pour prouver que c'est réparé.

Le parcours ci-dessous existe pour empêcher ça. Il tient sur un ordre —
**constater avant d'implémenter, faire constater avant de committer** — et sur
deux points d'arrêt où Vince arbitre. Tout le reste est de l'intendance.

## Préconditions

Le worktree existe et sa branche porte le ticket : `sli-8298-ats-bloc-fiche-...`
donne le ticket **SLI-8298**. L'identifiant se lit dans le nom de branche, il n'y
a pas à le demander.

Le ticket se récupère via le MCP Linear (`get_issue`), pas via une recherche
approximative. Le constat se fait sur le dev local du worktree.

Si l'une de ces conditions manque — pas de worktree, branche sans identifiant,
ticket introuvable — le dire et s'arrêter. Ne pas improviser un périmètre.

## Ce que « rapport » veut dire ici

À chaque étape, un rapport de **trois à cinq lignes en prose**, qui dit trois
choses : ce que j'ai constaté, ce que je propose, ce qui bloque ou me manque.

Pas de tableau, pas de recopie du diff, pas de liste de fichiers touchés, pas de
récapitulatif de ce que je viens de faire étape par étape. Si le rapport ne tient
pas en cinq lignes, c'est qu'il contient autre chose qu'un rapport.

Ne pas charger `slash-redaction` pour ces rapports : ce skill couvre les écrits
que lit un relecteur sur GitHub, et il exclut explicitement la rédaction destinée
au chat. Il intervient à l'étape 6, pas avant.

## Rester dans le périmètre

Le ticket, et rien que le ticket. Pas de refactor opportuniste, pas de correction
d'un bug adjacent croisé en route, pas de nettoyage de code qu'on trouve laid.

Ce qui est hors périmètre tient en **une ligne** dans le rapport de l'étape en
cours — et on continue. Vince décidera s'il en fait un ticket.

## Étape 1 — Analyse du ticket

Lire le ticket **une seule fois, mais à fond** : la description, les commentaires,
et les liens fournis — Sentry, PR précédente, capture, document. Les ouvrir
vraiment, ne pas les survoler.

Localiser le code concerné, et surtout : déterminer **comment le problème sera
observable**. Le plus souvent une URL et un parcours dans le navigateur. Quand ce
n'est pas observable en navigateur — flux XML, job, cron, endpoint d'API, mail —
dire par quoi on le remplace : une requête, un log, un appel direct, un test
ciblé. C'est le point qui conditionne tout le reste du parcours ; ne pas le
laisser implicite.

**Rapport** : ce que demande le ticket, où ça se joue dans le code, comment on va
le constater.

## Étape 2 — Données et constat « avant »

La base du worktree est un clone de la base locale, elle-même clone de staging :
elle manque souvent du cas précis que le ticket adresse. Juger si le cas y est.

S'il manque quelque chose, appeler **`slash-recette-dataset`**. Il fait déjà
l'exploration en lecture seule, le plan de données soumis à validation, la
baseline « avant » constatée en navigateur et le handoff dans le scratchpad — ne
pas refaire son travail à la main, et ne pas relire le ticket une deuxième fois.
Il signale aussi les critères d'acceptation qui dépendent d'un service externe
non mocké : si le constat en dépend, le remonter tout de suite.

Si les données sont là, constater directement.

Le constat se fait avec **`claude-in-chrome`**, dans le Chrome de Vince, **pas en
headless** : l'onglet doit lui rester ouvert pour qu'il constate lui-même. Lui
donner l'URL et les étapes exactes.

**Si le problème ne se reproduit pas, s'arrêter là.** Dire ce qui a été essayé et
ce qu'on observe à la place. Ne jamais implémenter sur la seule foi du ticket : ou
le ticket décrit mal le problème, ou l'environnement ne correspond pas, et dans
les deux cas coder est prématuré.

**Rapport** : le constat — ou la non-reproduction — et l'état des données.

## Étape 3 — Plan et arbitrage (point d'arrêt bloquant)

Proposer un plan : l'approche retenue et pourquoi, les fichiers concernés, les
effets de bord attendus, ce qu'on laisse volontairement de côté. Une alternative
ne se présente que si le choix entre les deux change quelque chose pour Vince ;
sinon, recommander et avancer.

**Ne rien écrire dans le dépôt à ce stade.** Pas de code, pas de fichier
préparatoire, pas de branche annexe.

Vince arbitre. Le plan peut se raffiner à deux. Attendre une **validation
explicite** : un « ok » qui répond à une autre question, une remarque, une
reformulation ou un silence ne valent pas validation. En cas de doute, demander
plutôt que de supposer.

## Étape 4 — Implémentation et vérification

Implémenter le plan validé, rien de plus. Un écart au plan se signale, il ne se
décide pas en cours de route.

Vérifier dans le navigateur, sur le parcours exact de l'étape 2 : le constat doit
avoir disparu. Un test vert ne remplace pas cette vérification.

Lancer les tests et le lint **pertinents** avant de considérer que c'est fini —
ciblés sur ce qui est touché, pas la suite complète si ce n'est pas nécessaire.

Les captures d'écran vont dans le scratchpad de session. `gh` ne sait pas
uploader d'image sur GitHub : elles ne peuvent donc pas atterrir seules dans la
description de PR. Dire où elles sont pour que Vince les colle s'il le souhaite,
ou les attacher au ticket Linear. Ne pas promettre une PR illustrée qu'on ne peut
pas produire.

**Rapport** : ce qui a été fait, ce qui a résisté, les écarts au plan. Puis la
démarche de reproduction pas à pas, et la question : faut-il remettre le jeu de
données en état pour constater la résolution ?

## Étape 5 — Validation de la résolution (point d'arrêt bloquant)

Vince reproduit et constate. Attendre sa validation explicite **avant de
committer** — même règle qu'à l'étape 3 sur ce qui compte comme validation.

## Étape 6 — Finalisation

Découper les commits **par intention** : le correctif d'un côté, un renommage ou
un déplacement de l'autre. Un commit qui mélange les deux est illisible en
`git blame`. Reprendre la convention du dépôt.

Charger **`slash-redaction` avant** d'écrire les messages de commit et la
description de PR — avant, pas après avoir rédigé.

Ne pas committer les artefacts de recette : scripts de seed jetables, captures,
fichiers du scratchpad.

Pousser, ouvrir la PR, et vérifier que le lien Linear y figure bien
(`Closes SLI-XXXX`) — c'est ce qui referme le ticket.
