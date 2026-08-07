# slash-redaction

Cadre de rédaction des écrits destinés à un relecteur humain : descriptions de
pull request, commentaires de code review, messages de commit.

Un principe : **le relecteur a trente secondes et il a déjà le diff.**

## Contenu

| Fichier | Rôle |
|---|---|
| `SKILL.md` | Les règles. Chargé à la demande par Claude Code. |
| `references/exemples.md` | Paires avant/après tirées de vraies PR, annotées. |
| `AMORCE.md` | Trois lignes à importer dans `CLAUDE.md` pour garantir le déclenchement. |

## Installation

1. Copier ce dossier dans `~/.claude/skills/slash-redaction/` (portée
   personnelle, tous projets) **ou** dans `<dépôt>/.claude/skills/` (portée
   dépôt, versionné avec le code).

2. Ajouter l'import de l'amorce dans son `CLAUDE.md`, à côté des autres :

   ```
   @skills/slash-redaction/AMORCE.md
   ```

   L'étape 2 n'est pas cosmétique. Sans elle, le skill ne se déclenche que si le
   modèle pense spontanément à aller le chercher — or le moment d'écrire une
   description de PR arrive en fin de tâche, quand il est occupé ailleurs.
   L'amorce coûte une trentaine de tokens par session et rend le déclenchement
   fiable.

## Faire évoluer le cadre

Quand une rédaction se fait retoquer, ajouter la paire avant/après à
`references/exemples.md` avec ce qui clochait. Les exemples portent plus que les
règles — c'est le mécanisme d'affinage prévu, pas un pense-bête.

Garder `SKILL.md` court : un skill dilué ne change rien au comportement.
