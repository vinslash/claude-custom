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
entier n'est pas versionnable. D'où un dépôt séparé, et des liens symboliques pour
que `~/.claude` pointe dessus. Et le format **plugin** plutôt qu'un lien par
skill, parce qu'un seul point de montage suffit alors, hooks et serveur MCP
compris.

```
  ~/.claude/                             claude-custom/  ← le plugin « slash »
  │                                      │
  ├── settings.json   (non versionné)    │
  ├── sessions/, …    (état runtime)     │
  │                                      │
  ├── CLAUDE.md ───────── lien ──────────▶ CLAUDE.md
  │                                      │
  └── skills/slash/ ───── lien ──────────▶ .  ← skills/, hooks/, .mcp.json
                                         │
                                         ▼  ce qui a fait ses preuves
                           slash-interim/.claude/skills/
```

## Contenu

### Les skills

| Chemin | Invocation | Rôle |
| --- | --- | --- |
| `skills/constat/` | `/slash:constat` | Fait constater le problème par la personne qui traite le ticket, plutôt que de lui rapporter un constat — phase didactique avant implémentation, vérification de la résolution après. |
| `skills/decoupage-pr/` | `/slash:decoupage-pr` | Garde-fou sur la taille des PR, et mécanique d'ouverture de plusieurs PR pour un ticket — en parallèle ou empilées. Surcharge `slash-create-pr`. |
| `skills/process-ticket/` | `/slash:process-ticket` | Parcours complet d'un ticket Linear, du worktree déjà créé jusqu'à la PR ouverte. Orchestre les autres. |
| `skills/recette-dataset/` | `/slash:recette-dataset` | Jeu de données de recette scopé à un ticket SLI, pour constater un bug avant correction puis prouver sa résolution. |
| `skills/redaction/` | `/slash:redaction` | Cadre de rédaction des écrits lus par un humain : descriptions de PR, commentaires de review, messages de commit. |
| `skills/chrome-ancrage/` | `/slash:chrome-ancrage` | Règles de pilotage du navigateur quand plusieurs sessions tournent en parallèle. |

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
| `CLAUDE.md` | Les instructions globales, lues à chaque session, tous projets confondus. Ne contient que des imports `@`. |
| `RTK.md` | Référence du proxy CLI `rtk`, importée par `CLAUDE.md`. |
| `.claude-plugin/plugin.json` | Le manifeste. C'est sa seule présence qui fait charger le dossier comme plugin. |
| `hooks/` | `SessionStart` : injecte le ticket lu dans le nom de branche quand la session s'ouvre dans un worktree SLI. |
| `.mcp.json` | Serveur MCP `chrome` : lance son propre navigateur, avec un profil par worktree. |
| `install.sh` | Pose les deux liens et neutralise ce qui entre en conflit. Idempotent. |
| `hooks-retires/` | Hooks retirés de `settings.json`, conservés pour pouvoir les recoller. |
| `settings.snippet.json` | Le peu qui doit vivre dans `settings.json`, et pourquoi. |
| `claude-custom.code-workspace` | Espace de travail VS Code, versionné volontairement — le `.gitignore` l'exclut de l'exclusion des éditeurs. |

## Les limites posées

Chaque borne existe parce qu'elle a une **conséquence** : ce qui arrive au-delà.
Une limite sans conséquence n'est qu'un ornement, et se fait contourner.

### Ce qu'on écrit

| Écrit | Borne | Au-delà |
| --- | --- | --- |
| Description de PR | **150 à 250 mots**, 3 sections au plus, 2 à 4 phrases pour le problème et pour le correctif | Ce n'est plus une description mais un rapport. Le relecteur a trente secondes et il a déjà le diff. |
| Couverture de test dans la description | **une phrase** | Un tableau de recette est une preuve adressée au demandeur, pas au relecteur. |
| Rapport d'étape dans le chat | **3 à 5 lignes** en prose | S'il ne tient pas en cinq lignes, il contient autre chose qu'un rapport. |
| Ce qui est hors périmètre | **une ligne**, puis on continue | Le ticket, et rien que le ticket ; c'est à l'utilisateur d'en faire un autre. |
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
sauvegardé. Il pose les deux liens (`~/.claude/skills/slash → <dépôt>` et
`~/.claude/CLAUDE.md`), verse un `CLAUDE.md` ou un `RTK.md` local dans le dépôt
en proposant d'en récupérer le contenu, retire les anciens liens par skill,
neutralise le serveur MCP `chrome-devtools` de slash-interim, valide le
manifeste, vérifie que les imports `@` résolvent, et termine sur l'inventaire des
composants et leur coût en tokens.

Un lien suffit pour le plugin : un dossier de `~/.claude/skills/` qui contient un
`.claude-plugin/plugin.json` est chargé comme plugin complet — skills, hooks,
serveur MCP — sans marketplace ni installation. Rien n'est copié : on édite dans
le dépôt, c'est actif à la session suivante.

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

**`settings.json` n'est pas versionné et ne doit pas être symlinké** : Claude Code
le réécrit lui-même (thème, plugins activés, `/config`), et une réécriture
atomique remplacerait le lien par un fichier ordinaire sans prévenir. Tout ce qui
peut vivre dans le plugin y vit ; le reste est documenté dans
`settings.snippet.json`.

## Ajouter un skill

Le créer **dans ce dépôt**, sous `skills/<nom>/SKILL.md` — jamais directement dans
`~/.claude/skills/`, ce qui l'exclurait du versionnement sans prévenir. Il est
visible à la session suivante, sans rien réinstaller.

Vérifier son coût avant de le laisser vivre :

```bash
claude plugin details slash@skills-dir
```

La colonne *always-on* est payée par **toutes** les sessions de **tous** les
projets — c'est la description du frontmatter. La colonne *on-invoke* est payée à
chaque déclenchement : au-delà de quelques milliers de tokens, sortir le détail
en `references/`, lu seulement quand la question se pose.

## Ne pas versionner ici

`.credentials.json`, `settings.local.json`, et plus généralement tout ce qui porte
un jeton ou une URL interne. Le dépôt est sur GitHub.

`drafts/` est également ignoré : brouillons et handoffs de session, propres à la
machine et sans intérêt pour quelqu'un qui clone.
