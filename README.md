# claude-custom

Ma customisation Claude Code, versionnée. **Le dépôt est un plugin** nommé
`slash`, monté par un unique lien symbolique.

`~/.claude` mélange de la config écrite à la main et de l'état runtime (sessions,
historique, `.credentials.json`) : le dossier entier n'est pas versionnable. Ce
dépôt ne contient que le premier, et `~/.claude` pointe dessus.

## Contenu

| Chemin | Rôle |
| --- | --- |
| `skills/constat/` | Fait constater un ticket à Vince lui-même — phase didactique avant implémentation, vérification de la résolution après. |
| `skills/decoupage-pr/` | Garde-fou sur la taille des PR, et mécanique d'ouverture de plusieurs PR pour un ticket — en parallèle ou empilées. Surcharge `slash-create-pr`. |
| `skills/process-ticket/` | Parcours complet d'un ticket Linear, du worktree déjà créé jusqu'à la PR ouverte. Orchestre les autres. |
| `skills/recette-dataset/` | Jeu de données de recette scopé à un ticket SLI, pour constater un bug avant correction puis prouver sa résolution. |
| `skills/redaction/` | Cadre de rédaction des écrits lus par un humain : descriptions de PR, commentaires de review, messages de commit. |
| `skills/chrome-ancrage/` | Règles de pilotage du navigateur quand plusieurs sessions tournent en parallèle. |
| `hooks/` | `SessionStart` : injecte le ticket lu dans le nom de branche quand la session s'ouvre dans un worktree SLI. |
| `.mcp.json` | Serveur MCP `chrome` : lance son propre navigateur, avec un profil par worktree. |
| `hooks-retires/` | Hooks retirés de `settings.json`, conservés pour pouvoir les recoller. |
| `settings.snippet.json` | Le peu qui doit vivre dans `settings.json`, et pourquoi. |

Les skills s'invoquent **`/slash:<nom>`** : le nom du plugin sert de namespace,
c'est pourquoi les dossiers ne portent plus le préfixe `slash-`.

## Installation

```bash
git clone git@github.com:vinslash/claude-custom.git ~/Development/claude-custom
cd ~/Development/claude-custom && ./install.sh
```

`install.sh` est idempotent et ne supprime jamais un fichier sans l'avoir
sauvegardé. Il pose `~/.claude/skills/slash → <dépôt>`, verse `CLAUDE.md` et
`RTK.md` dans le dépôt (en proposant de récupérer un contenu local existant),
retire les anciens liens par skill, neutralise le serveur MCP `chrome-devtools`
de slash-interim, et vérifie que les imports `@` résolvent.

Un seul lien suffit : un dossier de `~/.claude/skills/` qui contient un
`.claude-plugin/plugin.json` est chargé comme plugin complet — skills, hooks,
serveur MCP — sans marketplace ni installation. Rien n'est copié : on édite dans
le dépôt, c'est actif à la session suivante.

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
