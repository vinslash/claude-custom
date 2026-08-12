#!/usr/bin/env bash
# Injecte le contexte du ticket quand la session s'ouvre dans un worktree SLI.
#
# L'identifiant se lit dans le nom de la branche. Le faire ici plutôt que de le
# laisser déduire par le modèle : c'est déterministe, ça ne coûte rien, et ça
# évite qu'un parcours démarre sur un ticket mal identifié.
#
# Silencieux et sans effet partout ailleurs — ce hook tourne dans toutes les
# sessions, y compris hors slash-interim.

set -u

root=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
branch=$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null) || exit 0

num=$(printf '%s' "$branch" | grep -oiE 'sli-?[0-9]{3,}' | head -1 | grep -oE '[0-9]{3,}')
[ -n "${num:-}" ] || exit 0

read -r -d '' ctx <<EOF || true
Cette session est ouverte dans le worktree du ticket **SLI-${num}**
(branche \`${branch}\`, racine \`${root}\`).

L'identifiant du ticket se lit dans la branche : ne pas le redemander.
Le parcours de traitement de bout en bout est le skill \`slash:process-ticket\`.
EOF

printf '%s' "$ctx" | python3 -c '
import json, sys
print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "SessionStart",
        "additionalContext": sys.stdin.read(),
    }
}))
'
