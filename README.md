# claude-custom

Mon atelier Claude Code : l'endroit où j'éprouve des skills et des configs avant
de les proposer à l'équipe.

**Un bac à sable, parce qu'un skill ne se juge pas sur le papier.** Il faut le
faire tourner sur de vrais tickets, plusieurs jours, et le corriger à chaud. Tant
qu'il n'est pas stabilisé, il n'a rien à faire dans un dépôt d'équipe : ici je
casse et je reprends sans conséquence pour personne.

**Un chemin vers l'équipe, ensuite.** Ce qui a fait ses preuves est destiné à
migrer vers `slash-interim/.claude/`. C'est pour ça que chaque skill est écrit
pour rester lisible hors de son contexte d'origine, et que les surcharges d'un
skill du dépôt vivent ici en attendant. `skills/decoupage-pr/` en est l'exemple
courant : il surcharge `slash-create-pr` sans y toucher, le temps de vérifier que
ses règles tiennent.

**Tout versionné, d'où le montage.** `~/.claude` mélange la config écrite à la
main et l'état runtime — sessions, historique, `.credentials.json` : le dossier
entier n'est pas versionnable. D'où un dépôt séparé. Et le format **plugin**
plutôt qu'un lien par skill, parce qu'un seul point de montage suffit alors,
hooks et serveur MCP compris.

**Deux dépôts, et non plus un lien symbolique.** Ce que lisent les sessions est un
**clone**, à `~/.claude/skills/slash`, que personne n'édite. On développe ici, on
publie en poussant, et le clone suit tout seul : un agent launchd tire toutes les
deux minutes.

Tant que `~/.claude/skills/slash` était un lien vers ce worktree, le brouillon
*était* la production — chaque sauvegarde partait à l'instant dans toutes les
sessions ouvertes, y compris un skill à moitié réécrit. Et un agent launchd ne
peut pas tirer dans le worktree où l'on est en train d'écrire. Cette séparation
est donc à la fois ce qui rend la mise à jour automatique possible, et ce qui fait
enfin exister une notion de version.

```
  claude-custom/              ← ici : on écrit, on commit, on pousse
        │  git push
        ▼
     GitHub
        │  git pull --ff-only, toutes les 2 min (agent launchd)
        ▼
  ~/.claude/skills/slash/     ← le clone installé, édité par personne
        │
        ├── skills/, hooks/, .mcp.json    le plugin « slash »
        └── CLAUDE.md ◀─── importé par ─── ~/.claude/CLAUDE.md
                                           (fichier d'une ligne, pas un lien)

                    ▼  ce qui a fait ses preuves
              slash-interim/.claude/skills/
```

## Contenu

### Les skills

| Chemin | Invocation | Rôle |
| --- | --- | --- |
| `skills/constat/` | `/slash:constat` | Fait constater le problème par la personne qui traite le ticket, plutôt que de lui rapporter un constat — phase didactique avant implémentation, vérification de la résolution après. |
| `skills/decoupage-pr/` | `/slash:decoupage-pr` | Garde-fou sur la taille des PR, et mécanique d'ouverture de plusieurs PR pour un ticket — en parallèle ou empilées. Surcharge `slash-create-pr`. |
| `skills/process-ticket/` | `/slash:process-ticket` | Parcours complet d'un ticket Linear, du worktree déjà créé jusqu'à la PR ouverte — sept étapes suivies en task list, pour retrouver où on en est en revenant sur un ticket. Orchestre les autres. |
| `skills/recette-dataset/` | `/slash:recette-dataset` | Jeu de données de recette scopé à un ticket SLI, pour constater un bug avant correction puis prouver sa résolution. |
| `skills/redaction/` | `/slash:redaction` | Cadre de rédaction des écrits lus par un humain : descriptions de PR, commentaires de review, messages de commit, et livrables écrits longs — plan, handoff, analyse. Porte la passe d'élagage. |
| `skills/chrome-ancrage/` | `/slash:chrome-ancrage` | Règles de pilotage du navigateur quand plusieurs sessions tournent en parallèle. |
| `skills/maj/` | `/slash:maj` | Le seul qui ne parle pas de tickets : force la mise à jour du clone installé sans attendre le tick de launchd, et depuis ce dépôt-ci plutôt que GitHub avec `--depuis-dev`, pour éprouver un skill committé sans le pousser. |

Le nom du plugin sert de **namespace** : c'est pourquoi les dossiers ne portent
plus le préfixe `slash-`, qui ferait doublon. Attention à ne pas les confondre
avec les skills du dépôt slash-interim (`slash-commit`, `slash-create-pr`), qui
gardent le leur.

Taper la commande reste l'exception : un skill part surtout **de lui-même**, sur
sa description. `redaction` et `chrome-ancrage` s'appuient en plus sur une amorce
dans `CLAUDE.md`, parce que leur déclenchement ne peut pas dépendre du hasard.

### Le montage

| Chemin | Rôle |
| --- | --- |
| `skills/*/AMORCE.md` | Quelques lignes importées par `CLAUDE.md` pour garantir le déclenchement d'un skill que sa seule description ne suffit pas à faire partir à coup sûr. |
| `CLAUDE.md` | Les instructions globales, lues à chaque session, tous projets confondus. Ne contient que des imports `@`, et n'est lui-même atteint que par l'import posé dans `~/.claude/CLAUDE.md`. |
| `RTK.md` | Référence du proxy CLI `rtk`, importée par `CLAUDE.md`. |
| `.claude-plugin/plugin.json` | Le manifeste. C'est sa seule présence qui fait charger le dossier comme plugin. |
| `hooks/hooks.json` | Le câblage, et rien d'autre : un script par événement. Volontairement famélique — voir « Ce qui se propage tout seul ». |
| `hooks/handlers/session-start.sh` | Déclare les `watchPaths` à surveiller, et injecte le ticket lu dans le nom de branche quand la session s'ouvre dans un worktree SLI. |
| `hooks/handlers/file-changed.sh` | `FileChanged` : se déclenche seul quand un fichier de config bouge sur disque, prévient à l'écran, pose un marqueur. |
| `hooks/handlers/user-prompt-submit.sh` | Consomme le marqueur au message suivant et réinjecte les instructions permanentes modifiées. |
| `hooks/handlers/commun.sh` | Les deux ensembles de fichiers qui fondent tout le rattrapage : instructions permanentes contre câblage. |
| `bin/mise-a-jour.sh` | Le `git pull --ff-only` du clone installé. Tiré par launchd, et par `/slash:maj`. Hors de Claude Code, donc gratuit. |
| `.mcp.json` | Serveur MCP `chrome` : lance son propre navigateur, avec un profil par worktree. |
| `install.sh` | Pose le clone installé, l'import `CLAUDE.md`, l'agent launchd, et neutralise ce qui entre en conflit. Idempotent. |
| `hooks-retires/` | Hooks retirés de `settings.json`, conservés pour pouvoir les recoller. |
| `settings.snippet.json` | Le peu qui doit vivre dans `settings.json`, et pourquoi. |
| `claude-custom.code-workspace` | Espace de travail VS Code, versionné volontairement — le `.gitignore` l'exclut de l'exclusion des éditeurs. |
| `.wtkit/config` | Profil wtkit : `wt open claude-custom` pose un onglet `claude` à côté du shell. Les onglets ne sont créés qu'à la naissance de la session tmux — la modifier n'a d'effet qu'après un `tmux kill-session`. |

## Les limites posées

Chaque borne existe parce qu'elle a une **conséquence** : ce qui arrive au-delà.
Une limite sans conséquence n'est qu'un ornement, et se fait contourner.

### Ce qu'on écrit

| Écrit | Borne | Au-delà |
| --- | --- | --- |
| Description de PR | **150 à 250 mots**, 3 sections au plus, 2 à 4 phrases pour le problème et pour le correctif | Ce n'est plus une description mais un rapport. Le relecteur a trente secondes et il a déjà le diff. |
| Couverture de test dans la description | **une phrase** | Un tableau de recette est une preuve adressée au demandeur, pas au relecteur. |
| Rapport d'étape dans le chat | **3 à 5 lignes** en prose | S'il ne tient pas en cinq lignes, il contient autre chose qu'un rapport. |
| Ce qui est hors périmètre | **une ligne**, puis on continue | Le ticket, et rien que le ticket ; c'est à l'utilisateur d'en faire un autre. Son détail va dans l'autre ticket, jamais dans celui-ci. |
| Livrable écrit long — plan, handoff, analyse, dossier de décision | **200 lignes**, après une passe d'élagage obligatoire | Ce n'est plus un plan mais un dossier : le relecteur le survole au lieu de l'arbitrer, et son accord ne vaut plus rien. |
| Commentaire de détail technique (Linear ou PR) | **250 mots**, un seul, jamais une série | Ce n'est plus un commentaire mais un document : soit un fichier dans le dépôt, soit c'était à supprimer. |
| Renvoi vers ce commentaire depuis le livrable | **une ligne**, jamais un résumé | La pollution qu'on venait de sortir revient par la fenêtre. |
| Le POURQUOI d'un ticket | **cinq lignes**, avec les mots de l'utilisateur | C'est la matière première de la description de PR, pas une analyse. |
| Message de commit (slash-interim) | **titre seul, sans corps** | Convention du dépôt, portée par `slash-commit`. |

Les 150 à 250 mots valent **par PR**, jamais par lot : trois PR font trois
descriptions.

### La taille d'une pull request

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

### Les portes anti-overkill

Un skill qui impose quinze minutes de cérémonie sur un libellé mal orthographié
se fait contourner, et un skill contourné ne sert plus à rien. Deux d'entre eux
calibrent donc leur profondeur avant de s'engager :

| Skill | Porte |
| --- | --- |
| `constat` | **Trois questions** : y a-t-il quelque chose d'observable, l'utilisateur connaît-il déjà la zone, un challenge est-il probable. Rien d'observable — refactor, renommage — c'est trois lignes et rendre la main. |
| `recette-dataset` | **Trois questions**, et dès qu'une réponse coupe, on s'arrête. Un jeu de données ne prouve rien sans **au moins deux lignes qui divergent** sur la dimension testée. |

Le coût en tokens est lui aussi borné — voir « Ajouter un skill » plus bas.

## Installation

```bash
git clone git@github.com:vinslash/claude-custom.git ~/Development/claude-custom
cd ~/Development/claude-custom && ./install.sh
```

`install.sh` est idempotent et ne supprime jamais un fichier sans l'avoir
sauvegardé. Il clone le dépôt vers `~/.claude/skills/slash` et fait pointer
son origine sur GitHub, remplace `~/.claude/CLAUDE.md` par le fichier d'une ligne
qui importe celui du clone, verse un `CLAUDE.md` ou un `RTK.md` local dans le
dépôt en proposant d'en récupérer le contenu, retire les anciens liens par skill,
neutralise le serveur MCP `chrome-devtools` de slash-interim, pose l'agent
launchd, puis vérifie : manifeste valide, imports `@` qui résolvent, mise à jour
opérationnelle, agent chargé, et l'inventaire des composants avec leur coût en
tokens.

Rien à déclarer côté marketplace : un dossier de `~/.claude/skills/` qui contient
un `.claude-plugin/plugin.json` est chargé comme plugin complet — skills, hooks,
serveur MCP.

Le clone installé ne doit **jamais** être édité. Un seul fichier modifié dedans et
le `merge --ff-only` échoue : les mises à jour s'arrêteraient, et en silence.
C'est pour ça que `bin/mise-a-jour.sh` le vérifie à chaque passage et le notifie à
l'écran — c'est la seule panne du montage qu'on ne verrait pas venir.

## Ce qui se propage tout seul

Une session ouverte depuis trois jours doit bénéficier d'un correctif sans qu'on
la redémarre. Ce qui se recharge à chaud et ce qui ne se recharge pas n'est pas
affaire de goût : c'est ce que Claude Code sait faire, vérifié.

| Ce qui change | Propagation |
| --- | --- |
| Corps d'un `SKILL.md`, sa description, ajout, suppression, renommage | Surveillant natif, dans la session en cours |
| Corps d'un handler de hook | Relu à chaque déclenchement — `hooks.json` ne nomme qu'un script |
| `~/.claude/settings.json` | Surveillant natif |
| `CLAUDE.md` et ses imports `@` — `RTK.md`, les `AMORCE.md` | **Rien ne les relit.** Réinjectés par `user-prompt-submit.sh` |
| `hooks/hooks.json`, `.mcp.json`, `agents/`, `output-styles/` | `/reload-plugins` — le seul geste manuel qui reste |

Les instructions permanentes sont le trou réel, et le plus sournois : une session
de trois jours obéit aux amorces d'il y a trois jours, et rien ne le montre. D'où
la chaîne, qui ne demande aucun geste —

launchd tire → les fichiers changent sur disque → `FileChanged` part **seul**,
sans prompt, dans toutes les sessions ouvertes à la fois → les skills sont déjà
rechargés → un message dit ce qui a bougé → et au message suivant, le contenu
frais des instructions permanentes est réinjecté dans le contexte.

Rattraper au message suivant plutôt qu'à l'instant du changement n'est pas un
pis-aller : c'est l'instant juste avant que ces instructions puissent compter. Une
session au repos n'a besoin de rien.

**`/reload-plugins` est irréductible.** Le câblage du plugin vit dans la mémoire du
process, et `reload_plugins` est une control request réservée au SDK — vérifié dans
le binaire : aucun hook ne peut la déclencher. D'où `hooks.json` réduit à nommer
des scripts : tant qu'on n'y ajoute pas d'événement, il ne bouge plus, et le geste
manuel ne se présente jamais.

L'état des hooks vit dans `~/.claude/slash-etat/` — un marqueur par session, le
journal des mises à jour. Jamais dans le clone, qui doit rester impeccable.

`claude plugin validate` avertit que le `CLAUDE.md` de la racine « n'est pas
chargé comme contexte de projet ». C'est **attendu** : il n'est pas censé l'être,
il est
lu via le lien `~/.claude/CLAUDE.md` en tant qu'instructions globales. Ne pas
chercher à faire taire cet avertissement en déplaçant ou en supprimant le fichier.

## Deux pièges vérifiés à la dure

**Les imports `@` en chemin relatif résolvent depuis le répertoire courant de la
session**, pas depuis le `CLAUDE.md` ni depuis `~/.claude`. Dans un `CLAUDE.md`
global ils échouent donc presque partout — **et en silence**. D'où la forme
`@~/.claude/skills/slash/...`, ancrée sur le home et correcte depuis n'importe
quel projet. `install.sh` le vérifie ; ne pas revenir à un chemin relatif.

**Ce que Claude Code réécrit lui-même ne doit pas être un lien.** `settings.json`
d'abord : il le réécrit (thème, plugins activés, `/config`), et une réécriture
atomique remplacerait le lien par un fichier ordinaire sans prévenir. Il n'est donc
pas versionné, et le peu qui doit y vivre est documenté dans
`settings.snippet.json`.

`~/.claude/CLAUDE.md` ensuite, pour la même raison poussée d'un cran : Claude Code
y écrit aussi (`/memory`, « ajoute ça à CLAUDE.md »). Quand c'était un lien vers le
dépôt, ces écritures y atterrissaient — ce qui était l'intention. Avec le montage
par clone, elles saliraient le clone et gèleraient toutes les mises à jour. D'où le
fichier d'une ligne : les ajouts personnels restent locaux, le contenu versionné
arrive par l'import.

## Ajouter un skill

Le créer **dans ce dépôt**, sous `skills/<nom>/SKILL.md` — jamais directement dans
`~/.claude/skills/slash/`, qui est le clone installé : le travail y serait perdu au
premier `pull`, et hors versionnement en attendant.

Il devient actif quand le clone le reçoit : commit puis push, et le tick suivant
l'apporte — dans les deux minutes, sans redémarrer aucune session. Pour l'éprouver
sans le pousser, `/slash:maj` sait tirer depuis ce dépôt-ci.

Vérifier son coût avant de le laisser vivre :

```bash
claude plugin details slash@skills-dir
```

La colonne *always-on* est payée par **toutes** les sessions de **tous** les
projets — c'est la description du frontmatter. La colonne *on-invoke* est payée à
chaque déclenchement : au-delà de quelques milliers de tokens, sortir le détail
en `references/`, lu seulement quand la question se pose.

Ce seuil se pondère par la **fréquence de déclenchement**. `process-ticket` est à
~5 k et les assume : il ne part qu'une fois par ticket, et tout son contenu sert
dès le début du parcours — l'extraire en référence ajouterait une lecture sans
rien économiser. Un skill qui part plusieurs fois par session n'a pas cette
latitude.

## Tenir ce README à jour

Toute modification du dépôt se termine ici, en **confrontant ce fichier au dépôt**
plutôt qu'en le relisant seul : aucune entrée suivie qui manque à l'inventaire,
les chemins cités qui existent, les comportements décrits conformes à
`install.sh` et aux liens réellement posés, et chaque chiffre annoncé traçable
jusqu'au skill qui le porte.

C'est la porte d'entrée de quelqu'un qui clone cet atelier, et les dérives ne se
voient pas de l'intérieur : une relecture a déjà trouvé un montage annoncé comme
un lien unique alors qu'il en faut deux, et cinq entrées suivies absentes de
l'inventaire.

## Ne pas versionner ici

`.credentials.json`, `settings.local.json`, et plus généralement tout ce qui porte
un jeton ou une URL interne. Le dépôt est sur GitHub.

`drafts/` est également ignoré : brouillons et handoffs de session, propres à la
machine et sans intérêt pour quelqu'un qui clone.
