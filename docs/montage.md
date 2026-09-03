# Le montage, fichier par fichier

Où vit quoi, ce que l'installateur pose, et les deux pièges qui ont coûté cher.
Pour savoir *quand* un changement prend effet, c'est [`propagation.md`](propagation.md).

## Le montage

| Chemin | Rôle |
| --- | --- |
| `skills/*/AMORCE.md` | Quelques lignes importées par `CLAUDE.md` pour garantir le déclenchement d'un skill que sa seule description ne suffit pas à faire partir à coup sûr. |
| `CLAUDE.md` | Les instructions globales, lues à chaque session, tous projets confondus. Ne contient que des imports `@`, et n'est lui-même atteint que par l'import posé dans `~/.claude/CLAUDE.md`. |
| `RTK.md` | Référence du proxy CLI `rtk`, importée par `CLAUDE.md`. |
| `.claude-plugin/plugin.json` | Le manifeste. C'est sa seule présence qui fait charger le dossier comme plugin. |
| `hooks/hooks.json` | Le câblage, et rien d'autre : un script par événement. Volontairement famélique — voir [`propagation.md`](propagation.md). |
| `hooks/handlers/session-start.sh` | Déclare les `watchPaths` à surveiller, et injecte le ticket lu dans le nom de branche quand la session s'ouvre dans un worktree SLI. |
| `hooks/handlers/file-changed.sh` | `FileChanged` : se déclenche seul quand un fichier de config bouge sur disque, prévient à l'écran, pose un marqueur. |
| `hooks/handlers/user-prompt-submit.sh` | Consomme le marqueur au message suivant et réinjecte les instructions permanentes modifiées. |
| `hooks/handlers/commun.sh` | Les deux ensembles de fichiers qui fondent tout le rattrapage : instructions permanentes contre câblage. |
| `bin/mise-a-jour.sh` | Le `git pull --ff-only` du clone installé. Tiré par launchd, et par `/slash:maj`. Hors de Claude Code, donc gratuit. |
| `.mcp.json` | Déclare le serveur MCP `chrome`, et rien d'autre : il ne nomme qu'un script. Même sobriété que `hooks/hooks.json`, même raison — voir [`propagation.md`](propagation.md). |
| `bin/chrome-mcp.sh` | Le lancement du navigateur : profil dérivé du worktree, cloné du profil modèle à sa naissance, onglet de repère qui affiche le ticket dans la barre d'onglets, et deux arguments retirés de ceux que Puppeteer pose par défaut — `--disable-extensions`, qui empêcherait les extensions de démarrer, et `--use-mock-keychain`, qui les ferait effacer du profil au premier lancement. |
| `bin/chrome-modele.sh` | Ouvre `~/.cache/chrome-mcp/_modele` pour y installer Dashlane une fois pour toutes. Le seul lancement de Chrome à la main qui soit permis. |
| `install.sh` | Pose le clone installé, l'import `CLAUDE.md`, l'agent launchd, et neutralise ce qui entre en conflit. Idempotent. |
| `hooks-retires/` | Hooks retirés de `settings.json`, conservés pour pouvoir les recoller. |
| `settings.snippet.json` | Le peu qui doit vivre dans `settings.json`, et pourquoi. |
| `claude-custom.code-workspace` | Espace de travail VS Code, versionné volontairement — le `.gitignore` l'exclut de l'exclusion des éditeurs. |
| `.wtkit/config` | Profil wtkit : `wt open claude-custom` pose un onglet `claude` à côté du shell. Les onglets ne sont créés qu'à la naissance de la session tmux — la modifier n'a d'effet qu'après un `tmux kill-session`. |

## Ce que fait `install.sh`

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
