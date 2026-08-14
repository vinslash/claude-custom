#!/usr/bin/env bash
#
# Met à jour le dépôt INSTALLÉ (`~/.claude/skills/slash`) depuis son origine.
#
# Tiré toutes les deux minutes par un agent launchd, et à la demande par le skill
# `slash:maj`. Volontairement hors de Claude Code : une mise à jour qui dépend
# d'une session ouverte n'est pas une mise à jour automatique, c'est un geste
# manuel déguisé. Ici, aucun process Claude n'est requis, et rien n'est facturé.
#
# Ne touche JAMAIS au dépôt de développement. Le clone installé n'est édité par
# personne : c'est ce qui permet de tirer en `--ff-only` sans jamais rien perdre.
#
# Usage :
#   mise-a-jour.sh                    depuis origin
#   mise-a-jour.sh --depuis-dev       depuis ~/Development/claude-custom
#   mise-a-jour.sh --clone <chemin>   viser un autre clone installé

set -u

# launchd ne fournit presque aucun environnement : ni PATH utilisable, ni
# SSH_AUTH_SOCK. Le PATH est donc posé ici. L'absence d'agent SSH, elle, ne pose
# pas de problème — vérifié : la clé du trousseau suffit à `git ls-remote`.
PATH=/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin
export PATH

CLONE="$HOME/.claude/skills/slash"
DEV="$HOME/Development/claude-custom"
SOURCE=origin
ETAT="$HOME/.claude/slash-etat"   # même dossier que les handlers de hook
JOURNAL="$ETAT/mise-a-jour.log"
VERROU="$ETAT/verrou"

while [ $# -gt 0 ]; do
  case "$1" in
    --depuis-dev) SOURCE="$DEV"; shift ;;
    --clone)      CLONE="${2:?--clone attend un chemin}"; shift 2 ;;
    *) printf 'option inconnue : %s\n' "$1" >&2; exit 2 ;;
  esac
done

mkdir -p "$ETAT" 2>/dev/null

note() { printf '%s\n' "$*"; printf '%s  %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >> "$JOURNAL"; }

# Le journal est écrit à chaque anomalie et à chaque mise à jour, jamais quand
# tout va bien : sinon il grossit de 720 lignes par jour et le jour où il faut y
# lire quelque chose, on ne trouve plus rien.
borner_journal() {
  [ -f "$JOURNAL" ] || return 0
  if [ "$(wc -l < "$JOURNAL")" -gt 400 ]; then
    tail -n 200 "$JOURNAL" > "$JOURNAL.tmp" && mv "$JOURNAL.tmp" "$JOURNAL"
  fi
}

# Une notification macOS pour les seuls cas où la mise à jour est BLOQUÉE. Un
# succès n'a rien à notifier : les sessions ouvertes l'apprennent toutes seules
# par le hook `FileChanged`. Et une notification par mise à jour serait du bruit,
# donc ignorée le jour où elle signale une panne.
alerter() {
  command -v osascript >/dev/null 2>&1 || return 0
  local vu="$ETAT/.alerte-vue"
  if [ -f "$vu" ]; then
    local pose
    pose=$(stat -f %m "$vu" 2>/dev/null || echo 0)
    [ $(($(date +%s) - pose)) -lt 3600 ] && return 0
  fi
  : > "$vu"
  osascript -e "display notification \"$1\" with title \"Config slash — mise à jour bloquée\"" >/dev/null 2>&1
}

# Verrou : deux exécutions concurrentes sur le même clone (le tick launchd et un
# `slash:maj` lancé à la main) se marcheraient dessus au milieu d'un merge.
if ! mkdir "$VERROU" 2>/dev/null; then
  pose=$(stat -f %m "$VERROU" 2>/dev/null || echo 0)
  if [ $(($(date +%s) - pose)) -lt 300 ]; then
    # Code distinct : appelé par install.sh, « verrou occupé » ne doit surtout pas
    # se confondre avec un succès, sinon la vérification affiche ✔ sans avoir rien
    # vérifié — ce qui est pire que pas de vérification du tout.
    note "une autre mise à jour est en cours, rien fait"
    exit 3
  fi
  # Verrou abandonné par un process tué en cours de route : on le reprend, sinon
  # les mises à jour s'arrêtent pour toujours sans que personne ne le sache.
  rmdir "$VERROU" 2>/dev/null
  mkdir "$VERROU" 2>/dev/null || exit 0
fi
trap 'rmdir "$VERROU" 2>/dev/null' EXIT

[ -d "$CLONE/.git" ] || { note "pas un clone git : $CLONE — lancer install.sh"; borner_journal; exit 1; }

branche=$(git -C "$CLONE" symbolic-ref --quiet --short HEAD 2>/dev/null) || {
  note "clone sur HEAD détachée : $CLONE"; alerter "Le clone installé est sur une HEAD détachée."; borner_journal; exit 1
}

# LA panne à surveiller. Un seul fichier modifié dans le clone et le `--ff-only`
# échoue : les mises à jour s'arrêteraient net, et en silence. D'où la
# notification — c'est le seul moyen de l'apprendre sans aller lire un journal.
sale=$(git -C "$CLONE" status --porcelain 2>/dev/null)
if [ -n "$sale" ]; then
  note "clone sali, mise à jour impossible :"$'\n'"$sale"
  alerter "Des fichiers ont été modifiés dans ~/.claude/skills/slash. Rien ne doit y être édité : les mises à jour sont gelées jusqu'à remise à zéro."
  borner_journal
  exit 1
fi

local_sha=$(git -C "$CLONE" rev-parse HEAD 2>/dev/null)

# On interroge la source SANS rien écrire dans le clone. C'est ce qui permet de
# tourner toutes les deux minutes sans réveiller pour rien le surveillant de
# fichiers de Claude Code : `.git/` n'est touché que s'il y a vraiment du neuf.
distant_sha=$(git -C "$CLONE" ls-remote --exit-code "$SOURCE" "refs/heads/$branche" 2>/dev/null | awk '{print $1}' | head -1)
if [ -z "${distant_sha:-}" ]; then
  note "source injoignable ($SOURCE), on retentera au prochain tick"
  borner_journal
  exit 0
fi

if [ "$local_sha" = "$distant_sha" ]; then
  printf 'déjà à jour (%s)\n' "${local_sha:0:7}"
  exit 0
fi

# Le distant peut être un ANCÊTRE de notre HEAD : c'est l'état normal juste après
# une installation, quand le dépôt de dev a des commits pas encore poussés. Ce
# n'est pas une divergence, et il ne faut surtout pas la signaler comme telle —
# sinon on alerte toutes les heures pour un état parfaitement sain. Testé sans
# rien écrire dans `.git`, quand l'objet distant y est déjà connu.
if git -C "$CLONE" cat-file -e "${distant_sha}^{commit}" 2>/dev/null \
  && git -C "$CLONE" merge-base --is-ancestor "$distant_sha" HEAD 2>/dev/null; then
  printf 'en avance sur %s, rien à tirer (%s)\n' "$SOURCE" "${local_sha:0:7}"
  exit 0
fi

if ! git -C "$CLONE" fetch --quiet "$SOURCE" "refs/heads/$branche" 2>/dev/null; then
  note "fetch échoué depuis $SOURCE"
  borner_journal
  exit 1
fi

if ! sortie=$(git -C "$CLONE" merge --ff-only FETCH_HEAD 2>&1); then
  note "fast-forward impossible ($local_sha → $distant_sha) : $sortie"
  alerter "Le clone installé a divergé de sa source : fast-forward impossible."
  borner_journal
  exit 1
fi

fichiers=$(git -C "$CLONE" diff --name-only "$local_sha" "$distant_sha" 2>/dev/null | tr '\n' ' ')
note "mis à jour ${local_sha:0:7} → ${distant_sha:0:7} : $fichiers"
rm -f "$ETAT/.alerte-vue"
borner_journal
