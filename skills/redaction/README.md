# slash:redaction

Cadre de rédaction des écrits destinés à un relecteur humain : descriptions de
pull request, commentaires de code review, messages de commit, et livrables
écrits longs — document de plan, handoff, analyse, dossier de décision.

Un principe : **le relecteur a trente secondes et il a déjà le diff.** Sur un
livrable long il en a dix minutes, mais il a une décision à prendre : ce qui ne
change pas cette décision n'a rien à faire dans le document.

## Contenu

| Fichier | Rôle |
|---|---|
| `SKILL.md` | Les règles. Chargé à la demande par Claude Code. |
| `references/exemples.md` | Paires avant/après tirées de vraies PR, annotées. |
| `references/livrables-longs.md` | La passe d'élagage : le geste, les quatre défauts et à quoi on les reconnaît, le levier tableau/mermaid. Lu seulement quand le livrable est long. |
| `AMORCE.md` | Quelques lignes à importer dans `CLAUDE.md` pour garantir le déclenchement. |

## Installation

Rien à faire séparément : ce skill fait partie du plugin `slash`, monté par
`install.sh` à la racine du dépôt. Il s'invoque `/slash:redaction`.

L'import de l'amorce dans `CLAUDE.md` est en revanche essentiel, et
`install.sh` vérifie qu'il résout :

```
@~/.claude/skills/slash/skills/redaction/AMORCE.md
```

Il n'est pas cosmétique. Sans lui, le skill ne se déclenche que si le modèle
pense spontanément à aller le chercher — or le moment d'écrire une description de
PR arrive en fin de tâche, quand il est occupé ailleurs. L'amorce coûte une
trentaine de tokens par session et rend le déclenchement fiable.

Le chemin doit rester **ancré sur `~`** : un import relatif résout depuis le
répertoire courant de la session, donc échoue partout ailleurs, en silence.

## Faire évoluer le cadre

Quand une rédaction se fait retoquer, ajouter la paire avant/après à
`references/exemples.md` — ou, pour un livrable long, le symptôme et son
correctif à `references/livrables-longs.md` — avec ce qui clochait. Les exemples
portent plus que les règles : c'est le mécanisme d'affinage prévu, pas un
pense-bête.

Garder `SKILL.md` court, et le détail dans `references/` : un skill dilué ne
change rien au comportement, et `SKILL.md` est payé à chaque déclenchement.
