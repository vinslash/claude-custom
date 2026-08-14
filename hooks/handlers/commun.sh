#!/usr/bin/env bash
# Fonctions partagées par les handlers de hook. Sourcé, jamais exécuté.
#
# Tout le rattrapage de configuration tient dans une distinction entre deux
# ensembles de fichiers, et il vaut la peine de savoir pourquoi elle existe.
#
#   A. Les INSTRUCTIONS PERMANENTES — `CLAUDE.md` et ce qu'il importe : `RTK.md`,
#      les `AMORCE.md`. Claude Code les charge une seule fois, à l'ouverture de
#      la session, et ne les relit plus jamais. C'est le seul trou réel du
#      montage, et le plus sournois : une session ouverte depuis trois jours
#      obéit aux amorces d'il y a trois jours sans qu'on puisse le voir. On les
#      réinjecte donc à la main, au prompt suivant.
#
#   B. Le CÂBLAGE — `hooks/hooks.json` et `.mcp.json`. Il vit dans la mémoire du
#      process Claude Code. Vérifié dans le binaire : aucun hook ne peut le
#      recharger, `reload_plugins` est une control request réservée au SDK. On ne
#      peut donc que le signaler, et laisser `/reload-plugins` à l'utilisateur.
#
# Tout le reste se recharge déjà à chaud, sans nous : le corps des `SKILL.md`,
# leur description, l'ajout, la suppression et le renommage d'un skill, et
# jusqu'au corps de ces handlers — `hooks.json` ne fait que nommer un script, et
# le script est relu à chaque déclenchement. Il ne faut donc surtout pas
# réinjecter ces fichiers : ce serait payer des tokens pour du contenu déjà à
# jour, à chaque mise à jour, dans toutes les sessions.

ETAT="$HOME/.claude/slash-etat"
SESSIONS="$ETAT/sessions"

# L'état ne vit jamais dans le dépôt installé : le moindre fichier écrit dedans
# salit le clone et fait échouer le `merge --ff-only`, ce qui gèlerait les mises
# à jour en silence — exactement la panne qu'on cherche à éviter.
mkdir -p "$SESSIONS" 2>/dev/null

racine() { printf '%s' "${CLAUDE_PLUGIN_ROOT:-$HOME/.claude/skills/slash}"; }

somme() { if command -v md5 >/dev/null 2>&1; then md5 -q; else md5sum | cut -d' ' -f1; fi; }

# Ensemble A. On lit les imports de `CLAUDE.md` au lieu de globber `skills/*/AMORCE.md` :
# ce qui compte n'est pas qu'un fichier existe, c'est qu'il soit importé. Une
# amorce désimportée cesse d'être une instruction permanente le jour même.
instructions_permanentes() {
  local root claudemd ref p
  root="$(racine)"
  claudemd="$root/CLAUDE.md"
  [ -f "$claudemd" ] || return 0
  printf '%s\n' "$claudemd"
  # Un seul saut : aujourd'hui les fichiers importés n'importent rien eux-mêmes.
  # Si ça change un jour, ce parcours devra devenir récursif — Claude Code va
  # jusqu'à quatre sauts.
  grep -oE '^@[^[:space:]]+' "$claudemd" 2>/dev/null | while IFS= read -r ref; do
    p="${ref#@}"
    case "$p" in
      "~/"*) printf '%s\n' "$HOME/${p#\~/}" ;;
      /*)    printf '%s\n' "$p" ;;
      *)     printf '%s\n' "$root/$p" ;;
    esac
  done
}

# Ensemble B.
cablage() {
  local root
  root="$(racine)"
  printf '%s\n%s\n' "$root/hooks/hooks.json" "$root/.mcp.json"
}

# Empreinte du contenu de A, chemins compris — pour qu'un renommage compte comme
# un changement. Sert au seul cas que `FileChanged` ne couvre pas : une session
# reprise avec `--resume`, dont le transcript rejoué contient la version d'avant.
empreinte_instructions() {
  local f
  instructions_permanentes | while IFS= read -r f; do
    printf '%s\n' "$f"
    [ -f "$f" ] && cat "$f"
  done | somme
}
