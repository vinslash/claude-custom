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

## Les skills

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

## Installation

```bash
git clone git@github.com:vinslash/claude-custom.git ~/Development/claude-custom
cd ~/Development/claude-custom && ./install.sh
```

`install.sh` est idempotent et ne supprime jamais un fichier sans l'avoir
sauvegardé. Le détail de ce qu'il pose et de ce qu'il vérifie est dans
[`docs/montage.md`](docs/montage.md).

Le clone installé ne doit **jamais** être édité. Un seul fichier modifié dedans et
le `merge --ff-only` échoue : les mises à jour s'arrêteraient, et en silence.
C'est pour ça que `bin/mise-a-jour.sh` le vérifie à chaque passage et le notifie à
l'écran — c'est la seule panne du montage qu'on ne verrait pas venir.

## La doc

| Fichier | Pour répondre à |
| --- | --- |
| [`docs/montage.md`](docs/montage.md) | Où vit quoi, ce que pose `install.sh`, et les deux pièges qui ont coûté cher |
| [`docs/propagation.md`](docs/propagation.md) | Quand un changement prend effet — ce qui se recharge à chaud, ce qui exige `/reload-plugins` |
| [`docs/bornes.md`](docs/bornes.md) | Quelle borne s'applique : ce qu'on écrit, la taille d'une PR, les portes anti-overkill |
| [`docs/contribuer.md`](docs/contribuer.md) | Ajouter un skill, vérifier son coût, et tenir cette doc à jour |

## Ne pas versionner ici

`.credentials.json`, `settings.local.json`, et plus généralement tout ce qui porte
un jeton ou une URL interne. Le dépôt est sur GitHub.

`drafts/` est également ignoré : brouillons et handoffs de session, propres à la
machine et sans intérêt pour quelqu'un qui clone.
