#!/bin/sh
# Supprime les profils Chrome dont le worktree a disparu.
#
#   chrome-sweep.sh [--dry-run]
#
# Un profil pèse 250 à 750 Mo, et rien ne le retirait : au 24/11/2026, 223 des
# 226 dossiers de `~/.cache/chrome-mcp/` n'avaient plus de worktree. Le balayage
# ne s'accroche pas à la suppression du worktree, parce qu'elle passe par trop
# de chemins — `wt rm`, `git worktree remove` des skills de review, un simple
# `rm -rf` — et qu'aucun n'a de crochet commun. Il constate après coup :
# `chrome-mcp.sh` le lance en arrière-plan à chaque démarrage de serveur, donc à
# chaque session.
#
# Le nom du profil ne suffit pas à retrouver son worktree : c'est un basename.
# Le lanceur inscrit donc dans `<profil>/.worktree` le chemin de chaque dossier
# qui l'a ouvert, et un profil n'est supprimé que si AUCUN de ces chemins
# n'existe plus. Deux worktrees homonymes dans deux dépôts partagent un profil ;
# l'un supprimé, l'autre le garde.
#
# Un profil sans `.worktree` n'est jamais touché : on ne sait pas d'où il vient.
# `_modele` non plus, ni un profil qu'un Chrome ou un serveur tient encore.
set -eu

dry_run=
[ "${1:-}" = --dry-run ] && dry_run=1

base_dir="${HOME}/.cache/chrome-mcp"
log_dir="${HOME}/Library/Logs/chrome-mcp"
journal="${log_dir}/_menage.log"
[ -d "$base_dir" ] || exit 0
mkdir -p "$log_dir"

# Deux sessions qui démarrent ensemble lanceraient deux balayages. Le second
# s'efface ; un verrou de plus d'une heure est celui d'un balayage tué.
lock="${log_dir}/.menage.lock"
if ! mkdir "$lock" 2>/dev/null; then
  [ -n "$(find "$lock" -maxdepth 0 -mmin +60 2>/dev/null)" ] || exit 0
  rm -rf "$lock"; mkdir "$lock" 2>/dev/null || exit 0
fi
trap 'rmdir "$lock" 2>/dev/null' EXIT

note() {
  printf '%s %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$journal"
  [ -z "$dry_run" ] || echo "$*"
}

for profile in "$base_dir"/*/; do
  profile=${profile%/}
  name=$(basename "$profile")
  case "$name" in _modele|*.workdir.*) continue ;; esac
  [ -f "$profile/.worktree" ] || continue

  alive=
  while IFS= read -r path; do
    [ -n "$path" ] && [ -d "$path" ] && { alive=1; break; }
  done < "$profile/.worktree"
  [ -z "$alive" ] || continue

  # Chrome (`--user-data-dir`) ou serveur MCP (`--userDataDir`) encore dessus :
  # une session ouverte dans un worktree qu'on vient de supprimer. Supprimer
  # maintenant, c'est laisser son Chrome recréer un profil vide.
  if pgrep -f -- "(user-data-dir|userDataDir)=${profile}( |\$)" >/dev/null 2>&1; then
    note "gardé, encore ouvert : $name"
    continue
  fi

  origin=$(head -1 "$profile/.worktree")
  if [ -n "$dry_run" ]; then
    echo "à supprimer : $name ($origin)"
    continue
  fi
  rm -rf "${profile:?}"
  rm -f "$log_dir/$name.log" "$log_dir/$name.log.1"
  note "supprimé : $name — worktree disparu ($origin)"
done
