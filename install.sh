#!/usr/bin/env bash
#
# Installe ce dépôt comme plugin Claude Code, en deux dépôts.
#
# Le dépôt de développement (celui-ci) n'est plus monté dans `~/.claude`. Ce que
# lisent les sessions est un CLONE, à `~/.claude/skills/slash`, mis à jour par
# `git pull` — toutes les deux minutes, par un agent launchd.
#
# Pourquoi pas un lien symbolique, comme avant : parce qu'alors le brouillon EST
# la production. Chaque sauvegarde partait instantanément dans toutes les sessions
# ouvertes, y compris un skill à moitié réécrit. Avec un clone, publier devient un
# geste — commit puis push — et il existe enfin une notion de version.
#
# Et parce qu'un agent launchd ne peut pas tirer dans le worktree où l'on est en
# train d'écrire : il n'y a pas de mise à jour automatique sans cette séparation.
#
# Idempotent : relançable sans risque. Ne supprime jamais un fichier sans l'avoir
# sauvegardé d'abord.
#
# Usage : ./install.sh

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
CLONE="$SKILLS_DIR/slash"
ETAT="$CLAUDE_DIR/slash-etat"
LABEL="com.slash.claude-custom.maj"
PLIST="$HOME/Library/LaunchAgents/$LABEL.plist"
IMPORT="@~/.claude/skills/slash/CLAUDE.md"
STAMP="$(date +%Y%m%d-%H%M%S)"

ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
die()  { printf '  \033[31mx\033[0m %s\n' "$1" >&2; exit 1; }
step() { printf '\n\033[1m%s\033[0m\n' "$1"; }

[ -f "$REPO/.claude-plugin/plugin.json" ] || die "$REPO ne ressemble pas à ce dépôt (pas de .claude-plugin/plugin.json)."
mkdir -p "$SKILLS_DIR" "$ETAT"

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

# ------------------------------------------------------------ dépôt installé --
step "Dépôt installé"
branche="$(git -C "$REPO" symbolic-ref --quiet --short HEAD)" || die "le dépôt de dev est sur une HEAD détachée."
url="$(git -C "$REPO" remote get-url origin 2>/dev/null || true)"

if [ -L "$CLONE" ]; then
  ancien="$(readlink "$CLONE")"
  rm "$CLONE"
  ok "ancien lien symbolique retiré (pointait sur $ancien)."
fi

if [ -d "$CLONE/.git" ]; then
  ok "déjà un clone git."
elif [ -e "$CLONE" ]; then
  die "$CLONE existe et n'est ni un lien ni un clone git — je n'y touche pas."
else
  # --no-hardlinks : sans ça, git partage les fichiers d'objets entre les deux
  # dépôts. Un `gc` dans le dépôt de dev pourrait alors casser le clone installé.
  git clone --quiet --no-hardlinks --branch "$branche" "$REPO" "$CLONE"
  ok "cloné depuis le dépôt de dev (branche $branche)."
fi

# L'origine du clone doit être GitHub, pas le dépôt de dev : c'est ce qui fait
# marcher la propagation entre machines, et ce qui rend `--depuis-dev` explicite.
if [ -n "$url" ]; then
  git -C "$CLONE" remote set-url origin "$url"
  if git -C "$CLONE" fetch --quiet origin "$branche" 2>/dev/null; then
    git -C "$CLONE" branch --quiet --set-upstream-to="origin/$branche" "$branche" 2>/dev/null || true
    ok "origine : $url (branche suivie : $branche)."
  else
    warn "origine posée sur $url mais injoignable — la mise à jour retentera d'elle-même."
  fi
else
  warn "le dépôt de dev n'a pas d'origine : le clone ne pourra être mis à jour qu'avec --depuis-dev."
fi

sale="$(git -C "$CLONE" status --porcelain)"
[ -z "$sale" ] || warn "le clone installé contient des modifications — elles gèleront les mises à jour :"$'\n'"$sale"

# ---------------------------------------------------------------- CLAUDE.md --
# Un fichier ordinaire d'une seule ligne, et non plus un lien vers le dépôt.
#
# Deux raisons, la seconde étant la plus dure : Claude Code écrit lui-même dans ce
# fichier (`/memory`, « ajoute ça à CLAUDE.md »). Avec un lien, ces écritures
# partaient dans le dépôt de dev ; avec le montage par clone, elles saliraient le
# clone et bloqueraient le `merge --ff-only` — donc toutes les mises à jour, en
# silence. Ici, les ajouts personnels restent locaux, et le contenu versionné
# arrive par l'import.
#
# Vérifié à la dure : une référence `@` en chemin RELATIF résout depuis le
# répertoire courant de la session, pas depuis le CLAUDE.md. Dans un CLAUDE.md
# global elle échoue donc partout sauf par hasard, et elle échoue en SILENCE.
# D'où la forme ancrée sur le home, qui reste correcte depuis n'importe quel
# projet sans coder le nom d'utilisateur en dur.
step "CLAUDE.md"
target="$CLAUDE_DIR/CLAUDE.md"

if [ -L "$target" ]; then
  ancien="$(readlink "$target")"
  rm "$target"
  printf '%s\n' "$IMPORT" > "$target"
  ok "lien vers $ancien remplacé par l'import (le contenu vit toujours dans le dépôt)."
elif [ -f "$target" ]; then
  if grep -qxF "$IMPORT" "$target"; then
    ok "import déjà en place."
  else
    b="$(backup "$target")"
    { printf '%s\n\n' "$IMPORT"; cat "$b"; } > "$target"
    warn "import ajouté au-dessus du contenu local existant (sauvegarde : $b)."
  fi
else
  printf '%s\n' "$IMPORT" > "$target"
  ok "posé."
fi

# ------------------------------------------------------------------- RTK.md --
# Importé depuis le dépôt via CLAUDE.md, donc la copie dans ~/.claude n'est plus
# lue par personne. On la retire — après sauvegarde, toujours.
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

# ------------------------------------------------------ anciens liens skills --
# Un lien par skill, remplacé par le montage unique du plugin. On ne retire que
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

# ------------------------------------------------------------- settings.json --
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

# --------------------------------------------------------- mise à jour auto --
# L'agent pointe sur la copie du script DANS le clone, pas dans le dépôt de dev :
# le script se met donc à jour lui-même, et launchd relit le fichier à chaque
# exécution.
#
# stdout part au néant : le script dit « déjà à jour » à chaque tick, soit 720
# lignes par jour. Ce qui compte est journalisé par le script lui-même, avec
# rotation, dans slash-etat/mise-a-jour.log.
step "Mise à jour automatique (launchd)"
mkdir -p "$(dirname "$PLIST")"
cat > "$PLIST" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>              <string>$LABEL</string>
  <key>ProgramArguments</key>
  <array>
    <string>/bin/bash</string>
    <string>$CLONE/bin/mise-a-jour.sh</string>
  </array>
  <key>StartInterval</key>      <integer>120</integer>
  <key>RunAtLoad</key>          <true/>
  <key>ProcessType</key>        <string>Background</string>
  <key>LowPriorityIO</key>      <true/>
  <key>Nice</key>               <integer>5</integer>
  <key>StandardOutPath</key>    <string>/dev/null</string>
  <key>StandardErrorPath</key>  <string>$ETAT/launchd-erreurs.log</string>
  <key>EnvironmentVariables</key>
  <dict>
    <key>HOME</key>             <string>$HOME</string>
  </dict>
</dict>
</plist>
EOF
ok "agent écrit : $PLIST (toutes les 120 s)."

domaine="gui/$(id -u)"
launchctl bootout "$domaine/$LABEL" >/dev/null 2>&1 || true
if launchctl bootstrap "$domaine" "$PLIST" >/dev/null 2>&1; then
  ok "agent chargé."
elif launchctl load -w "$PLIST" >/dev/null 2>&1; then
  ok "agent chargé (ancienne syntaxe launchctl)."
else
  warn "chargement de l'agent refusé — le lancer à la main : launchctl bootstrap $domaine $PLIST"
fi

# ------------------------------------------------------------- vérifications --
step "Vérifications"
claude plugin validate "$REPO" >/dev/null 2>&1 && ok "manifeste de plugin valide." \
  || warn "\`claude plugin validate\` a signalé quelque chose — relance-le à la main."

grep -qxF "$IMPORT" "$target" && ok "~/.claude/CLAUDE.md importe le dépôt installé." \
  || warn "~/.claude/CLAUDE.md n'importe pas $IMPORT — rien du dépôt ne sera chargé."

# Une référence `@` qui ne résout pas est silencieuse : c'est le pire mode de
# panne du montage. On la vérifie explicitement, sur le clone.
missing=0
while IFS= read -r ref; do
  path="${ref#@}"
  case "$path" in
    "~/"*) resolved="$HOME/${path#\~/}" ;;
    /*)    resolved="$path" ;;
    *)     resolved="$CLONE/$path" ;;
  esac
  if [ -e "$resolved" ]; then ok "référence résolue : $ref"
  else warn "référence NON résolue : $ref → $resolved"; missing=1; fi
done < <(grep -oE '^@[^[:space:]]+' "$CLONE/CLAUDE.md" 2>/dev/null || true)
[ "$missing" = 0 ] || warn "corrige les références ci-dessus : elles échouent en silence."

# Le tick launchd vient d'être chargé (`RunAtLoad`) et tient peut-être le verrou :
# on retente, plutôt que de conclure sur une exécution qui n'a rien fait.
essais=0
while :; do
  sortie="$(bash "$CLONE/bin/mise-a-jour.sh" 2>&1)" && { ok "mise à jour opérationnelle : $sortie"; break; }
  code=$?
  if [ "$code" = 3 ] && [ "$essais" -lt 5 ]; then
    essais=$((essais + 1)); sleep 2; continue
  fi
  warn "la mise à jour a signalé : $sortie"
  break
done

launchctl print "$domaine/$LABEL" >/dev/null 2>&1 && ok "agent actif dans $domaine." \
  || warn "agent absent de $domaine — vérifier avec : launchctl print $domaine/$LABEL"

step "Inventaire et coût"
claude plugin details slash@skills-dir 2>/dev/null || warn "plugin pas encore chargé — il le sera à la prochaine session."

printf '\n\033[1mTerminé.\033[0m Les skills se nomment \033[1m/slash:<nom>\033[0m.\n'
printf 'Publier désormais : \033[1mcommit puis push\033[0m ici ; le clone installé suit tout seul.\n'
printf 'Les sessions déjà ouvertes ont besoin d'\''un \033[1m/reload-plugins\033[0m une fois, pour ce câblage-ci.\n\n'
