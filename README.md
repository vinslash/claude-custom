# claude-custom

Mes fichiers de customisation Claude Code, versionnés.

`~/.claude` mélange de la config écrite à la main et de l'état runtime (sessions,
historique, `.credentials.json`) : le dossier entier n'est pas versionnable. Ce repo
ne contient donc que le premier, et `~/.claude` pointe dessus par symlink.

## Contenu

| Chemin | Rôle |
| --- | --- |
| `skills/slash-process-ticket/` | Parcours de traitement d'un ticket Linear, du worktree déjà créé jusqu'à la PR ouverte. Orchestre les deux skills ci-dessous. |
| `skills/slash-redaction/` | Cadre de rédaction des écrits lus par un humain : descriptions de PR, commentaires de review, messages de commit. |
| `skills/slash-recette-dataset/` | Fabrication d'un jeu de données de recette scopé à un ticket SLI, pour constater un bug avant correction puis prouver sa résolution. |

`skills/slash-redaction/AMORCE.md` est chargé au démarrage de chaque session via un
`@import` dans `~/.claude/CLAUDE.md` — qui, lui, n'est pas versionné ici. Si le
symlink casse, l'import casse avec.

## Installation sur une nouvelle machine

```bash
git clone git@github.com:vinslash/claude-custom.git ~/Development/claude-custom
for skill in ~/Development/claude-custom/skills/*/; do
  ln -s "${skill%/}" ~/.claude/skills/"$(basename "$skill")"
done
```

Les symlinks portent le chemin **en dur** : renommer ou déplacer le clone les casse
tous d'un coup, et un skill dont le lien est cassé disparaît sans erreur — il
n'apparaît simplement plus dans la liste des skills. Après tout déplacement, vérifier :

```bash
ls -L ~/.claude/skills/*/SKILL.md
```

Puis ajouter dans `~/.claude/CLAUDE.md` :

```
@skills/slash-redaction/AMORCE.md
```

## Ajouter un skill

Le créer **dans ce repo**, puis le symlinker — jamais l'inverse : un skill créé
directement dans `~/.claude/skills/` échappe au versionnement sans prévenir.

```bash
ln -s ~/Development/claude-custom/skills/mon-skill ~/.claude/skills/mon-skill
```

## Ne pas versionner ici

`.credentials.json`, `settings.local.json`, et plus généralement tout ce qui porte
un token ou une URL interne. Le repo est sur GitHub.
