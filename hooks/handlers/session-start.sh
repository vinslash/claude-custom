#!/usr/bin/env bash
# `SessionStart` : trois choses, à l'ouverture de chaque session.
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
# 3. Prévenir l'utilisateur quand le profil Chrome de ce worktree va naître d'un
#    modèle dont les sessions sont mortes ou sur le point de l'être.
#
# Silencieux et sans effet hors slash-interim — ce hook tourne dans toutes les
# sessions.

set -u
# shellcheck source=./common.sh
. "$(dirname "${BASH_SOURCE[0]}")/common.sh"

payload=$(python3 -c '
import json, sys
try:
    d = json.load(sys.stdin)
except Exception:
    d = {}
print("%s\t%s" % (d.get("session_id", ""), d.get("session_start_reason", "")))
' 2>/dev/null) || payload=""
IFS=$'\t' read -r sid reason <<< "${payload:-}"

ctx=""
gap=$'\n\n'
append() { if [ -n "$ctx" ]; then ctx="$ctx$gap$1"; else ctx="$1"; fi; }

# -------------------------------------------------------------- ticket SLI --
root=$(git rev-parse --show-toplevel 2>/dev/null) || root=""
if [ -n "$root" ]; then
  branch=$(git -C "$root" rev-parse --abbrev-ref HEAD 2>/dev/null) || branch=""
  num=$(printf '%s' "$branch" | grep -oiE 'sli-?[0-9]{3,}' | head -1 | grep -oE '[0-9]{3,}')
  if [ -n "${num:-}" ]; then
    append "Cette session est ouverte dans le worktree du ticket **SLI-${num}**
(branche \`${branch}\`, racine \`${root}\`).

L'identifiant du ticket se lit dans la branche : ne pas le redemander."
  fi
fi

# ----------------------------------------------- reprise d'une vieille session --
# Le seul cas que `FileChanged` ne couvre pas. Une session reprise avec
# `--resume` rejoue son transcript : la copie des instructions permanentes qu'il
# contient est celle du jour de l'ouverture, et rien ne la relit. On compare donc
# l'empreinte du disque à celle enregistrée au dernier passage, et on ne
# réinjecte que si elle a bougé — sinon on paierait des tokens à chaque reprise.
if [ -n "${sid:-}" ]; then
  current=$(instructions_fingerprint 2>/dev/null)
  previous=$(cat "$SESSIONS/$sid.fingerprint" 2>/dev/null || printf '')
  if [ "${reason:-}" = "resume" ] && [ -n "$previous" ] && [ "$current" != "$previous" ]; then
    while IFS= read -r f; do
      [ -f "$f" ] || continue
      append "--- $f ---
$(cat "$f")"
    done < <(permanent_instructions)
    ctx="Les instructions permanentes de la configuration \`slash\` ont changé pendant que cette session était fermée. La version ci-dessous fait foi et remplace celle que le transcript rejoué contient.

$ctx"
  fi
  printf '%s' "$current" > "$SESSIONS/$sid.fingerprint" 2>/dev/null
fi

# ------------------------------------------------- profil Chrome modèle périmé --
# Le profil du worktree naît d'un clone du modèle, sessions GitHub et Dashlane
# comprises. Mais elles ne durent que 14 jours, et le modèle, qu'on n'ouvre
# jamais, ne les prolonge pas : passé ce délai, chaque profil neuf hérite de
# sessions mortes, et il faut tout ressaisir sans que rien ne dise pourquoi.
#
# On ne prévient donc que là où ça se paie : un worktree dont le profil n'est
# pas encore né, et un modèle à moins de trois jours de l'échéance. L'échéance se
# lit sur le cookie `user_session` de GitHub ; celle de Dashlane n'est lisible
# nulle part, mais les deux connexions se font dans le même passage de
# `chrome-template.sh`, donc elles tombent ensemble.
notice=""
chrome_base="$HOME/.cache/chrome-mcp"
profile="$chrome_base/$(basename "${root:-$PWD}")"
if [ -d "$chrome_base/_modele" ] && [ ! -d "$profile" ]; then
  expiry=""
  for cookies in "$chrome_base/_modele/Default/Cookies" "$chrome_base/_modele/Default/Network/Cookies"; do
    [ -f "$cookies" ] || continue
    expiry=$(sqlite3 "file:$cookies?immutable=1" \
      "select max(expires_utc/1000000 - 11644473600) from cookies
       where host_key = 'github.com' and name = 'user_session';" 2>/dev/null) || expiry=""
    [ -n "$expiry" ] && break
  done
  now=$(date +%s)
  case "$expiry" in ''|*[!0-9]*) expiry=0 ;; esac
  if [ "$expiry" -le "$now" ]; then
    when="sont expirées"
    [ "$expiry" -gt 0 ] && when="ont expiré le $(date -r "$expiry" '+%d/%m')"
  elif [ "$expiry" -le $((now + 3 * 86400)) ]; then
    when="expirent le $(date -r "$expiry" '+%d/%m')"
  else
    when=""
  fi
  if [ -n "$when" ]; then
    notice="Profil Chrome modèle : ses sessions GitHub et Dashlane $when. Ce worktree en héritera, et il faudra s'y reconnecter. Pour rafraîchir le modèle : quitter Chrome (Cmd+Q), puis bash ~/.claude/skills/slash/bin/chrome-template.sh."
  fi
fi

# Balayage de l'état laissé par les sessions mortes. Sans ça, `sessions/` grossit
# d'un fichier par session et par jour, pour toujours.
find "$SESSIONS" -type f -mtime +7 -delete 2>/dev/null

CC_PATHS="$(permanent_instructions; wiring)" CC_NOTICE="$notice" python3 - "$ctx" <<'PY'
import json, os, sys
ctx = sys.argv[1] if len(sys.argv) > 1 else ""
paths = [p for p in os.environ.get("CC_PATHS", "").split("\n") if p.strip()]
out = {"hookEventName": "SessionStart", "watchPaths": paths}
if ctx.strip():
    out["additionalContext"] = ctx
result = {"hookSpecificOutput": out}
# `systemMessage` s'affiche à l'utilisateur, pas au modèle : c'est lui qui
# devra rouvrir le modèle, pas la session.
notice = os.environ.get("CC_NOTICE", "")
if notice:
    result["systemMessage"] = notice
print(json.dumps(result))
PY
