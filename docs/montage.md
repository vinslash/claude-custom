# Le montage, fichier par fichier

Où vit quoi, et les deux pièges qui ont coûté cher. Pour *installer*, c'est
[`installation.md`](installation.md) ; pour savoir *quand* un changement prend
effet, [`propagation.md`](propagation.md).

## Le montage

| Chemin | Rôle |
| --- | --- |
| `skills/*/AMORCE.md` | Quelques lignes importées par `CLAUDE.md` pour garantir le déclenchement d'un skill que sa seule description ne suffit pas à faire partir à coup sûr. |
| `CLAUDE.md` | Les instructions globales, lues à chaque session, tous projets confondus. Ne contient que des imports `@`, et n'est lui-même atteint que par l'import posé dans `~/.claude/CLAUDE.md`. |
| `RTK.md` | Référence du proxy CLI `rtk`, importée par `CLAUDE.md`. |
| `.claude-plugin/plugin.json` | Le manifeste. C'est sa seule présence qui fait charger le dossier comme plugin. |
| `hooks/hooks.json` | Le câblage, et rien d'autre : un script par événement. Volontairement famélique — voir [`propagation.md`](propagation.md). |
| `hooks/handlers/session-start.sh` | Déclare les `watchPaths` à surveiller, injecte le ticket lu dans le nom de branche quand la session s'ouvre dans un worktree SLI, et prévient l'utilisateur quand les sessions GitHub et Dashlane du profil Chrome modèle — donc de tous les worktrees — arrivent à échéance. |
| `hooks/handlers/file-changed.sh` | `FileChanged` : se déclenche seul quand un fichier de config bouge sur disque, prévient à l'écran, pose un marqueur. |
| `hooks/handlers/user-prompt-submit.sh` | Consomme le marqueur au message suivant et réinjecte les instructions permanentes modifiées. |
| `hooks/handlers/common.sh` | Les deux ensembles de fichiers qui fondent tout le rattrapage : instructions permanentes contre câblage. |
| `bin/update.sh` | Le `git pull --ff-only` du clone installé. Tiré par launchd, et par `/slash:force-update`. Hors de Claude Code, donc gratuit. |
| `.mcp.json` | Déclare le serveur MCP `chrome`, et rien d'autre : il ne nomme qu'un script. Même sobriété que `hooks/hooks.json`, même raison — voir [`propagation.md`](propagation.md). |
| `bin/chrome-mcp.sh` | Le lancement du navigateur : profil dérivé du worktree, cloné du profil modèle à sa naissance, extension de repère préparée dans le worktree — son worker nommé d'après son contenu, seul moyen que Chrome relise une nouvelle version —, et deux arguments retirés de ceux que Puppeteer pose par défaut — `--disable-extensions`, qui empêcherait les extensions de démarrer, et `--use-mock-keychain`, qui les ferait effacer du profil au premier lancement. |
| `bin/extension-marker/` | L'extension qui range les onglets d'une fenêtre dans un groupe au nom du ticket, et ceux d'un second compte ouvert sur `127.0.0.1` dans un second groupe au nom de ce compte. Le lanceur en dépose une copie étiquetée dans `<worktree>/.chrome-marker` — dans le worktree, seul endroit que `install_extension` accepte. |
| `bin/chrome-marker-proxy.py` | Relais MCP qui repose l'extension au premier appel d'outil, retente à chaque appel tant qu'elle n'a pas pris, et la repose dès que le serveur signale un redémarrage du navigateur — elle ne lui survit pas. Cache aussi les outils d'extension à la session, et trace sur stderr une installation refusée. |
| `bin/chrome-template.sh` | Ouvre `~/.cache/chrome-mcp/_modele` pour y installer Dashlane **et s'y connecter à GitHub**, puis rafraîchir ces sessions avant leur échéance. Le seul lancement de Chrome à la main qui soit permis. Refuse de partir si le Chrome personnel tourne — ceux des sessions Claude ne gênent pas —, contrôle les deux sessions à la sortie, puis appelle `chrome-propagate.sh`. |
| `bin/chrome-propagate.sh` | Recopie les sessions Dashlane (stockage de l'extension) et GitHub (cookies `github.com`) du modèle dans les profils de worktree déjà nés, sans toucher au reste du profil. Saute et nomme ceux dont le Chrome tourne : le relancer seul une fois leur session fermée. `--dry-run` pour compter, des noms de profil pour cibler. |
| `bin/statusline.sh` | La status line : modèle, remplissage du contexte, coût en euros, tokens consommés sur la session sous-agents compris, durée, dossier et branche. `settings.json` vise ce fichier dans le clone, donc elle suit les mises à jour. Écrit son seul cache — le taux USD→EUR du jour — dans `~/.claude/cache/`, jamais dans le clone. |
| `install.sh` | Pose le clone installé, l'import `CLAUDE.md`, l'agent launchd, et neutralise ce qui entre en conflit. Idempotent. |
| `hooks-retired/` | Hooks retirés de `settings.json`, conservés pour pouvoir les recoller. |
| `settings.snippet.json` | Le peu qui doit vivre dans `settings.json`, et pourquoi. |
| `claude-custom.code-workspace` | Espace de travail VS Code, versionné volontairement — le `.gitignore` l'exclut de l'exclusion des éditeurs. |
| `.wtkit/config` | Profil wtkit : `wt open claude-custom` pose un onglet `claude` à côté du shell. Les onglets ne sont créés qu'à la naissance de la session tmux — la modifier n'a d'effet qu'après un `tmux kill-session`. |

## Ce que fait `install.sh`

Son inventaire cas par cas est dans [`installation.md`](installation.md), avec
les prérequis, la vérification et la désinstallation.

## Deux pièges vérifiés à la dure

**Les imports `@` en chemin relatif résolvent depuis le répertoire courant de la
session**, pas depuis le `CLAUDE.md` ni depuis `~/.claude`. Dans un `CLAUDE.md`
global ils échouent donc presque partout — **et en silence**. D'où la forme
`@~/.claude/skills/slash/...`, ancrée sur le home et correcte depuis n'importe
quel projet. `install.sh` le vérifie ; ne pas revenir à un chemin relatif.

**Ce que Claude Code réécrit lui-même ne doit pas être un lien.** `settings.json`
d'abord : il le réécrit (thème, plugins activés, `/config`), et une réécriture
atomique remplacerait le lien par un fichier ordinaire sans prévenir. Il n'est donc
pas versionné, et le peu qui doit y vivre — la neutralisation d'un serveur MCP et
la status line — est documenté dans `settings.snippet.json`.

`~/.claude/CLAUDE.md` ensuite, pour la même raison poussée d'un cran : Claude Code
y écrit aussi (`/memory`, « ajoute ça à CLAUDE.md »). Quand c'était un lien vers le
dépôt, ces écritures y atterrissaient — ce qui était l'intention. Avec le montage
par clone, elles saliraient le clone et gèleraient toutes les mises à jour. D'où le
fichier d'une ligne : les ajouts personnels restent locaux, le contenu versionné
arrive par l'import.
