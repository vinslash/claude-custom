#!/usr/bin/env bash
# `SessionStart` : deux choses, à l'ouverture de chaque session.
#
# 1. Déclarer les `watchPaths` — les chemins absolus que Claude Code doit
#    surveiller pour déclencher `FileChanged`. C'est ce qui abonne la session aux
#    mises à jour de configuration, dès sa première milliseconde. Déclaré ici
#    plutôt que dans `settings.json` : la liste se déduit des imports de
#    `CLAUDE.md`, donc elle se corrige toute seule, et elle reste versionnée.
#
# 2. Injecter le contexte du ticket quand la session s'ouvre dans un worktree
#    SLI. L'identifiant se lit dans le nom de la branche : le faire ici plutôt
#    que de le laisser déduire par le modèle, c'est déterministe, ça ne coûte
#    rien, et ça évite qu'un parcours démarre sur un ticket mal identifié.
#
# Silencieux et sans effet hors slash-interim — ce hook tourne dans toutes les
# sessions.

set -u
# shellcheck source=./commun.sh
. "$(dirname "${BASH_SOURCE[0]}")/commun.sh"

lu=$(python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
print("%s\t%s" % (d.get("session_id", ""), d.get("session_start_reason", "")))
' 2>/dev/null) || lu=""
IFS=$'\t' read -r sid raison <<< "${lu:-}"

ctx=""
saut=$'\n\n'
ajoute() { if [ -n "$ctx" ]; then ctx="$ctx$saut$1"; else ctx="$1"; fi; }

# -------------------------------------------------------------- ticket SLI --
root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
if [ -n "$root" ]; then
  branche=$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null) || branche=""
  num=$(printf '%s' "$branche" | grep -oiE 'sli-?[0-9]{3,}' | head -1 | grep -oE '[0-9]{3,}')
  if [ -n "${num:-}" ]; then
    ajoute "Cette session est ouverte dans le worktree du ticket **SLI-${num}**
(branche \`${branche}\`, racine \`${root}\`).

L'identifiant du ticket se lit dans la branche : ne pas le redemander.
Le parcours de traitement de bout en bout est le skill \`slash:process-ticket\`."
  fi
fi

# ----------------------------------------------- reprise d'une vieille session --
# Le seul cas que `FileChanged` ne couvre pas. Une session reprise avec
# `--resume` rejoue son transcript : la copie des instructions permanentes qu'il
# contient est celle du jour de l'ouverture, et rien ne la relit. On compare donc
# l'empreinte du disque à celle enregistrée au dernier passage, et on ne
# réinjecte que si elle a bougé — sinon on paierait des tokens à chaque reprise.
if [ -n "${sid:-}" ]; then
  actuelle=$(empreinte_instructions 2>/dev/null)
  precedente=$(cat "$SESSIONS/$sid.empreinte" 2>/dev/null || printf '')
  if [ "${raison:-}" = "resume" ] && [ -n "$precedente" ] && [ "$actuelle" != "$precedente" ]; then
    while IFS= read -r f; do
      [ -f "$f" ] || continue
      ajoute "--- $f ---
$(cat "$f")"
    done < <(instructions_permanentes)
    ctx="Les instructions permanentes de la configuration \`slash\` ont changé pendant que cette session était fermée. La version ci-dessous fait foi et remplace celle que le transcript rejoué contient.

$ctx"
  fi
  printf '%s' "$actuelle" > "$SESSIONS/$sid.empreinte" 2>/dev/null
fi

# Balayage de l'état laissé par les sessions mortes. Sans ça, `sessions/` grossit
# d'un fichier par session et par jour, pour toujours.
find "$SESSIONS" -type f -mtime +7 -delete 2>/dev/null

CC_PATHS="$(instructions_permanentes; cablage)" python3 - "$ctx" <<'PY'
import json, os, sys
ctx = sys.argv[1] if len(sys.argv) > 1 else ""
paths = [p for p in os.environ.get("CC_PATHS", "").split("\n") if p.strip()]
sortie = {"hookEventName": "SessionStart", "watchPaths": paths}
if ctx.strip():
    sortie["additionalContext"] = ctx
print(json.dumps({"hookSpecificOutput": sortie}))
PY
