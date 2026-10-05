#!/bin/sh
# Ouvre le profil modèle dont chaque profil de worktree sera cloné.
#
# C'est la seule et unique fois où l'on lance Chrome à la main — voir le skill
# `chrome-isolation`, qui l'interdit partout ailleurs. Ce lancement-ci est sûr :
# aucun port de debug n'est ouvert, donc aucune session Claude ne peut se
# tromper de navigateur et venir piloter celui-ci.
#
# À faire dans cette fenêtre, deux choses et non une : installer Dashlane depuis
# le Chrome Web Store et s'y connecter, ET se connecter à GitHub — c'est ce qui
# dispense les worktrees à naître du point d'arrêt de `slash:github-screenshots`.
# Puis fermer la fenêtre. Tout profil de worktree créé ensuite partira de cet
# état.
#
# Pas d'`exec` : le script reste vivant derrière Chrome pour vérifier le profil
# une fois la fenêtre fermée, et le dire. Sans ça, on ne sait pas si le modèle
# est prêt ou laissé à moitié écrit.
set -eu

template="${HOME}/.cache/chrome-mcp/_modele"

for candidate in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "${HOME}/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
do
  [ -x "$candidate" ] && chrome="$candidate" && break
done

if [ -z "${chrome:-}" ]; then
  echo "Google Chrome introuvable dans /Applications." >&2
  exit 1
fi

# Sur macOS, lancer le binaire Chrome alors qu'une instance tourne déjà fait
# main basse sur celle-ci : `--user-data-dir` est ignoré, la fenêtre qui s'ouvre
# est celle du profil personnel, et rien ne le signale. On croit avoir préparé le
# modèle, on a saisi ses identifiants dans son navigateur de tous les jours.
if pgrep -x "Google Chrome" >/dev/null 2>&1; then
  echo "Chrome tourne déjà : quitter TOUTES ses fenêtres (Cmd+Q) avant de" >&2
  echo "relancer ce script. Sinon le lancement serait absorbé par l'instance" >&2
  echo "en cours, le profil modèle ne serait pas touché, et la connexion" >&2
  echo "partirait dans le profil personnel sans que rien ne le dise." >&2
  exit 1
fi

mkdir -p "$template"

echo "Profil modèle : $template"
echo
echo "Dans la fenêtre qui s'ouvre, DEUX choses :"
echo "  1. installer Dashlane depuis le Chrome Web Store, et s'y connecter en"
echo "     cochant « Garder ma session ouverte pendant 14 jours » ;"
echo "  2. se connecter à GitHub dans le second onglet."
echo
echo "Puis QUITTER PAR CMD+Q, et non en fermant la dernière fenêtre — sur macOS"
echo "Chrome survit parfois à sa dernière fenêtre, et un profil pas encore vidé"
echo "sur disque serait cloné à moitié écrit. Ne pas interrompre ce script."
echo
echo "Ces sessions durent 14 jours, et le modèle ne les prolonge pas : le rouvrir"
echo "avant l'échéance. Le début de session prévient quand elle approche."
echo
echo "Les profils de worktree DÉJÀ créés ne changent pas. Pour qu'un ticket en"
echo "cours reparte du modèle, supprimer son dossier dans ~/.cache/chrome-mcp/."
echo

"$chrome" --user-data-dir="$template" --no-first-run --no-default-browser-check \
  "https://chromewebstore.google.com/detail/fdjamakpfbbddfjaooikfcpapjohcfmg" \
  "https://github.com/login" || true

# Chrome est sorti. Les verrous d'instance sont des liens symboliques vers le
# process qui vient de mourir ; `chrome-mcp.sh` les jette de toute façon à chaque
# clonage, mais les laisser ici rendrait le modèle inouvrable à la main.
rm -f "$template/SingletonLock" "$template/SingletonCookie" "$template/SingletonSocket"

echo
missing=""

[ -d "$template/Default/Extensions/fdjamakpfbbddfjaooikfcpapjohcfmg" ] \
  || missing="$missing Dashlane"

# Le fichier dépend de la version de Chrome : les deux emplacements connus. On
# lit l'échéance de `user_session` plutôt que sa seule présence : un cookie
# expiré compterait comme une session alors qu'il n'en est plus une. C'est la
# même lecture que fait `hooks/handlers/session-start.sh` pour prévenir.
expiry=0
for base in "$template/Default/Cookies" "$template/Default/Network/Cookies"; do
  [ -f "$base" ] || continue
  e=$(sqlite3 "file:$base?immutable=1" \
        "select max(expires_utc/1000000 - 11644473600) from cookies
         where host_key = 'github.com' and name = 'user_session';" 2>/dev/null || true)
  case "$e" in ''|*[!0-9]*) e=0 ;; esac
  if [ "$e" -gt "$expiry" ]; then expiry="$e"; fi
done
[ "$expiry" -gt "$(date +%s)" ] || missing="$missing GitHub"

if [ -z "$missing" ]; then
  echo "Modèle prêt : Dashlane installé, session GitHub enregistrée."
  echo "Les prochains worktrees en hériteront jusqu'au $(date -r "$expiry" '+%d/%m') ;"
  echo "rouvrir le modèle avant."
else
  echo "Attention, il manque :$missing — relancer ce script."
  echo "Si c'est GitHub : Chrome n'écrit ses cookies qu'en quittant par Cmd+Q."
fi
