#!/usr/bin/env bash
#
# Installe ce dépôt comme plugin Claude Code, par lien symbolique.
#
# Le dépôt EST le plugin : un seul lien, `~/.claude/skills/slash`, suffit à
# activer les skills, les hooks et le serveur MCP. Rien n'est copié — on édite
# dans le dépôt, c'est actif à la session suivante, et il n'existe jamais d'état
# « modifié ici mais pas là ».
#
# Idempotent : relançable sans risque. Ne supprime jamais un fichier sans
# l'avoir sauvegardé d'abord.
#
# Usage : ./install.sh

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
LINK="$SKILLS_DIR/slash"
STAMP="$(date +%Y%m%d-%H%M%S)"

ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '  \033[31mx\033[0m %s\n' "$1" >&2; exit 1; }
step() { printf '\n\033[1m%s\033[0m\n' "$1"; }

[ -f "$REPO/.claude-plugin/plugin.json" ] || die "$REPO ne ressemble pas à ce dépôt (pas de .claude-plugin/plugin.json)."
mkdir -p "$SKILLS_DIR"

backup() { # $1 = fichier à sauvegarder ; renvoie le chemin de la sauvegarde
  local src="$1" dst="$1.bak-$STAMP"
  cp -p "$src" "$dst"
  printf '%s' "$dst"
}

# Propose de verser une sauvegarde à la fin du fichier correspondant du dépôt.
# Toujours facultatif, et toujours posé APRÈS que le montage soit en place : le
# script ne laisse jamais la machine à moitié installée en attendant une réponse.
# Non interactif : ne verse rien, sauf CLAUDE_CUSTOM_RECOVER=o.
offer_recovery() { # $1 = sauvegarde, $2 = fichier du dépôt, $3 = étiquette
  local b="$1" repo_file="$2" label="$3" answer=""
  printf '\n'
  diff -u "$repo_file" "$b" | sed 's/^/    /' || true
  printf '\n  Verser le contenu sauvegardé dans %s ? [o/N] ' "$label"
  if [ -t 0 ]; then
    read -r answer
  else
    answer="${CLAUDE_CUSTOM_RECOVER:-n}"
    printf '%s (non interactif)\n' "$answer"
  fi
  case "$answer" in
    o|O|y|Y)
      {
        printf '\n<!-- Récupéré de %s le %s — à relire et nettoyer. -->\n' "$b" "$STAMP"
        cat "$b"
      } >> "$repo_file"
      ok "versé dans $label — à relire : rien n'a été dédupliqué." ;;
    *)
      ok "rien versé ; la sauvegarde reste disponible." ;;
  esac
}

# ---------------------------------------------------------------- CLAUDE.md --
# Le vrai fichier vit dans le dépôt ; ~/.claude/CLAUDE.md n'en est que le lien.
#
# Attention, vérifié à la dure : une référence `@` en chemin RELATIF résout
# depuis le répertoire courant de la session, pas depuis le CLAUDE.md ni depuis
# ~/.claude. Dans un CLAUDE.md global, elle échoue donc partout sauf par
# hasard — et elle échoue en SILENCE. D'où la forme `@~/.claude/skills/slash/...`
# dans le fichier versionné : ancrée sur le home, correcte depuis n'importe quel
# projet, et portable puisqu'elle ne code pas le nom d'utilisateur en dur.
step "CLAUDE.md"
target="$CLAUDE_DIR/CLAUDE.md"

if [ -L "$target" ] && [ "$(readlink "$target")" = "$REPO/CLAUDE.md" ]; then
  ok "déjà lié au dépôt."
elif [ -L "$target" ]; then
  warn "lien existant vers $(readlink "$target") — remplacé."
  rm "$target"; ln -s "$REPO/CLAUDE.md" "$target"; ok "lien posé."
elif [ -f "$target" ]; then
  b="$(backup "$target")"
  if [ ! -f "$REPO/CLAUDE.md" ]; then
    mv "$target" "$REPO/CLAUDE.md"
    ln -s "$REPO/CLAUDE.md" "$target"
    ok "contenu existant versé dans le dépôt (sauvegarde : $b)."
  else
    same=0; diff -q "$target" "$REPO/CLAUDE.md" >/dev/null 2>&1 && same=1
    rm "$target"; ln -s "$REPO/CLAUDE.md" "$target"
    if [ "$same" = 1 ]; then
      ok "identique à celui du dépôt ; lien posé (sauvegarde : $b)."
    else
      warn "un CLAUDE.md local différent existait : sauvegardé ($b), lien du dépôt posé."
      offer_recovery "$b" "$REPO/CLAUDE.md" "le CLAUDE.md du dépôt"
    fi
  fi
else
  ln -s "$REPO/CLAUDE.md" "$target"; ok "lien posé."
fi

# ------------------------------------------------------------------- RTK.md --
# Désormais importé depuis le dépôt via CLAUDE.md, donc la copie dans ~/.claude
# n'est plus lue par personne. On la retire — après sauvegarde, toujours.
step "RTK.md"
rtk="$CLAUDE_DIR/RTK.md"
if [ ! -e "$rtk" ]; then
  ok "rien à faire."
elif [ ! -f "$REPO/RTK.md" ]; then
  mv "$rtk" "$REPO/RTK.md"; ok "versé dans le dépôt."
elif diff -q "$rtk" "$REPO/RTK.md" >/dev/null 2>&1; then
  rm "$rtk"; ok "copie redondante retirée de ~/.claude (le dépôt fait foi)."
else
  b="$(backup "$rtk")"
  rm "$rtk"
  warn "~/.claude/RTK.md différait et n'était plus lu : sauvegardé ($b) et retiré."
  offer_recovery "$b" "$REPO/RTK.md" "le RTK.md du dépôt"
fi

# ------------------------------------------------------- anciens liens skills --
# Un lien par skill, remplacé par le lien unique du plugin. On ne retire que
# ceux qui pointent vers CE dépôt.
step "Anciens liens par skill"
found=0
for l in "$SKILLS_DIR"/slash-*; do
  [ -L "$l" ] || continue
  found=1
  dest="$(readlink "$l")"
  case "$dest" in
    "$REPO"/*) rm "$l"; ok "retiré : $(basename "$l")" ;;
    *)         warn "laissé : $(basename "$l") pointe hors du dépôt ($dest)" ;;
  esac
done
[ "$found" = 1 ] || ok "aucun."

# ------------------------------------------------------------ lien du plugin --
step "Lien du plugin"
if [ -L "$LINK" ] && [ "$(readlink "$LINK")" = "$REPO" ]; then
  ok "déjà en place."
else
  [ -e "$LINK" ] && [ ! -L "$LINK" ] && die "$LINK existe et n'est pas un lien — je n'y touche pas."
  rm -f "$LINK"
  ln -s "$REPO" "$LINK"
  ok "$LINK → $REPO"
fi

# --------------------------------------------------------------- settings.json --
# Une seule entrée doit y vivre : la neutralisation du serveur `chrome-devtools`
# déclaré par le .mcp.json de slash-interim, taillé pour le devcontainer et
# inutilisable sur l'hôte. Le reste (hooks, MCP) est porté par le plugin.
step "settings.json"
settings="$CLAUDE_DIR/settings.json"
if [ -f "$settings" ]; then
  # Sauvegarde seulement si on modifie vraiment — sinon chaque exécution laisse
  # un .bak de plus dans ~/.claude, et le bruit finit par cacher les vraies.
  python3 - "$settings" "$STAMP" <<'PY'
import json, shutil, sys
p, stamp = sys.argv[1], sys.argv[2]
with open(p) as f:
    cfg = json.load(f)
disabled = cfg.get("disabledMcpjsonServers") or []
if "chrome-devtools" in disabled:
    print("  \033[32m✔\033[0m chrome-devtools déjà neutralisé.")
else:
    shutil.copy2(p, f"{p}.bak-{stamp}")
    disabled.append("chrome-devtools")
    cfg["disabledMcpjsonServers"] = disabled
    with open(p, "w") as f:
        json.dump(cfg, f, indent=2, ensure_ascii=False)
        f.write("\n")
    print("  \033[32m✔\033[0m chrome-devtools neutralisé (entrée .mcp.json de slash-interim).")
PY
else
  warn "pas de settings.json — voir settings.snippet.json pour ce qu'il doit contenir."
fi

# ------------------------------------------------------------- vérifications --
# Une référence `@` qui ne résout pas est silencieuse : c'est le pire mode de
# panne du montage. On la vérifie explicitement, depuis ~/.claude.
step "Vérifications"
claude plugin validate "$REPO" >/dev/null 2>&1 && ok "manifeste de plugin valide." \
  || warn "\`claude plugin validate\` a signalé quelque chose — relance-le à la main."

missing=0
while IFS= read -r ref; do
  path="${ref#@}"
  case "$path" in
    "~/"*) resolved="$HOME/${path#\~/}" ;;
    /*)    resolved="$path" ;;
    *)     resolved="$CLAUDE_DIR/$path" ;;
  esac
  if [ -e "$resolved" ]; then ok "référence résolue : $ref"
  else warn "référence NON résolue : $ref → $resolved"; missing=1; fi
done < <(grep -oE '^@[^[:space:]]+' "$REPO/CLAUDE.md" || true)
[ "$missing" = 0 ] || warn "corrige les références ci-dessus : elles échouent en silence."

step "Inventaire et coût"
claude plugin details slash@skills-dir 2>/dev/null || warn "plugin pas encore chargé — il le sera à la prochaine session."

printf '\n\033[1mTermine.\033[0m Les skills se nomment desormais \033[1m/slash:<nom>\033[0m.\n\n'
