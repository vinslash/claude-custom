#!/usr/bin/env bash
# Garde-fou du skill slash:recette-dataset.
#
# Refuse de laisser écrire en base si on n'est pas dans un worktree à stack
# Docker isolée (base Postgres copiée). Sans ce contrôle, le skill mute la base
# locale du développeur — celle qui sert de source de clone à tous les futurs
# worktrees — ou la base d'un AUTRE worktree tournant en parallèle.
#
# Usage : bash scripts/check-worktree-isolation.sh
# Sortie 0 = isolé, cibles résolues affichées. Sortie != 0 = NE RIEN ÉCRIRE.

set -euo pipefail

fail() {
  echo "ABANDON — $1" >&2
  echo "Ne rien écrire en base. Voir Phase -1 du skill." >&2
  exit 1
}

command -v docker >/dev/null 2>&1 || fail "docker introuvable."
command -v python3 >/dev/null 2>&1 || fail "python3 introuvable."

# 1. Worktree git lié ? Dans le checkout principal, les deux chemins sont égaux.
git_dir=$(git rev-parse --git-dir 2>/dev/null) || fail "pas un dépôt git."
git_common=$(git rev-parse --git-common-dir 2>/dev/null)
if [ "$git_dir" = "$git_common" ]; then
  fail "checkout PRINCIPAL détecté (git-dir == git-common-dir).
  La base de ce checkout est la source clonée par tous les worktrees :
  y écrire contamine tous les worktrees futurs. Créer un worktree (wt)."
fi

repo_root=$(git rev-parse --show-toplevel)
cd "$repo_root"

# 2. Stack isolée générée par wt (ports décalés + projet Compose dédié).
[ -f docker-compose.override.yml ] \
  || fail "docker-compose.override.yml absent : stack non isolée (ports et
  base partagés avec le checkout principal)."

# 3. Projet Compose, port et volume de la base — résolus par Compose lui-même,
#    jamais devinés à l'œil dans 'docker ps'.
eval "$(docker compose config --format json 2>/dev/null | python3 -c '
import json, os, shlex, sys

try:
    cfg = json.load(sys.stdin)
except Exception:
    sys.exit("PARSE_ERROR")

svc = cfg.get("services", {}).get("db.backend")
if svc is None:
    sys.exit("NO_DB_SERVICE")

ports = svc.get("ports") or []
published = str(ports[0].get("published")) if ports else ""

binds = [
    v.get("source", "")
    for v in (svc.get("volumes") or [])
    if v.get("target") == "/var/lib/postgresql/data"
]

def emit(key, value):
    print(f"{key}={shlex.quote(str(value))}")

emit("PROJECT", cfg.get("name", ""))
emit("DB_PORT", published)
emit("DB_SOURCE", binds[0] if binds else "")
emit("DB_IS_BIND", "1" if binds and os.path.isabs(binds[0]) else "0")

back = cfg.get("services", {}).get("backend", {})
back_ports = back.get("ports") or []
emit("BACKEND_PORT", str(back_ports[0].get("published")) if back_ports else "")
')" || fail "lecture de la configuration Compose impossible."

[ -n "${PROJECT:-}" ] || fail "projet Compose non résolu."

worktree_name=$(basename "$repo_root")
case "$PROJECT" in
  *"$worktree_name") : ;;
  *) fail "le projet Compose ('$PROJECT') ne correspond pas au worktree
  courant ('$worktree_name'). Risque d'écrire dans la stack d'un autre
  ticket." ;;
esac

# 4. La base doit être une COPIE propre au worktree, pas le stockage partagé.
[ "${DB_IS_BIND:-0}" = "1" ] \
  || fail "la donnée Postgres n'est pas un bind mount : volume probablement
  partagé avec un autre projet Compose."

case "$DB_SOURCE" in
  "$repo_root"/*) : ;;
  *) fail "les données Postgres vivent HORS du worktree ($DB_SOURCE) :
  base partagée, écriture destructive pour les autres stacks." ;;
esac

[ -n "${DB_PORT:-}" ] && [ "$DB_PORT" != "5432" ] \
  || fail "la base est publiée sur le port 5432 (défaut du checkout
  principal) : décalage de ports absent."

[ -n "${BACKEND_PORT:-}" ] || fail "port du backend non résolu."

cat <<INFO
Isolation vérifiée — écriture autorisée sur cette stack.

  Projet Compose : $PROJECT
  Données PG     : $DB_SOURCE (copie locale au worktree)
  PG exposé      : localhost:$DB_PORT
  Backend        : http://localhost:$BACKEND_PORT

Toujours cibler la stack via Compose depuis $repo_root :
  docker compose exec db.backend psql -U postgres -d postgres -c '...'
  docker compose exec backend yarn migration:run
Jamais 'docker exec <nom-de-conteneur>' (nom stale = mauvaise stack),
jamais un hostname .slash-interim.local (celui du checkout principal).
INFO
