#!/bin/sh
# Ouvre le profil modèle dont chaque profil de worktree sera cloné.
#
# C'est la seule et unique fois où l'on lance Chrome à la main — voir le skill
# `chrome-ancrage`, qui l'interdit partout ailleurs. Ce lancement-ci est sûr :
# aucun port de debug n'est ouvert, donc aucune session Claude ne peut se
# tromper de navigateur et venir piloter celui-ci.
#
# À faire dans cette fenêtre, deux choses et non une : installer Dashlane depuis
# le Chrome Web Store et s'y connecter, ET se connecter à GitHub — c'est ce qui
# dispense les worktrees à naître du point d'arrêt de `slash:captures-github`.
# Puis fermer la fenêtre. Tout profil de worktree créé ensuite partira de cet
# état.
#
# Pas d'`exec` : le script reste vivant derrière Chrome pour vérifier le profil
# une fois la fenêtre fermée, et le dire. Sans ça, on ne sait pas si le modèle
# est prêt ou laissé à moitié écrit.
set -eu

modele="${HOME}/.cache/chrome-mcp/_modele"

for candidat in \
  "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
  "${HOME}/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
do
  [ -x "$candidat" ] && chrome="$candidat" && break
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

mkdir -p "$modele"

echo "Profil modèle : $modele"
echo
echo "Dans la fenêtre qui s'ouvre, DEUX choses :"
echo "  1. installer Dashlane depuis le Chrome Web Store, et s'y connecter ;"
echo "  2. se connecter à GitHub dans le second onglet."
echo
echo "Puis QUITTER PAR CMD+Q, et non en fermant la dernière fenêtre — sur macOS"
echo "Chrome survit parfois à sa dernière fenêtre, et un profil pas encore vidé"
echo "sur disque serait cloné à moitié écrit. Ne pas interrompre ce script."
echo
echo "Les profils de worktree DÉJÀ créés ne changent pas. Pour qu'un ticket en"
echo "cours reparte du modèle, supprimer son dossier dans ~/.cache/chrome-mcp/."
echo

"$chrome" --user-data-dir="$modele" --no-first-run --no-default-browser-check \
  "https://chromewebstore.google.com/detail/fdjamakpfbbddfjaooikfcpapjohcfmg" \
  "https://github.com/login" || true

# Chrome est sorti. Les verrous d'instance sont des liens symboliques vers le
# process qui vient de mourir ; `chrome-mcp.sh` les jette de toute façon à chaque
# clonage, mais les laisser ici rendrait le modèle inouvrable à la main.
rm -f "$modele/SingletonLock" "$modele/SingletonCookie" "$modele/SingletonSocket"

echo
manque=""

[ -d "$modele/Default/Extensions/fdjamakpfbbddfjaooikfcpapjohcfmg" ] \
  || manque="$manque Dashlane"

# Le fichier dépend de la version de Chrome : les deux emplacements connus.
github=0
for base in "$modele/Default/Cookies" "$modele/Default/Network/Cookies"; do
  [ -f "$base" ] || continue
  n=$(sqlite3 "file:$base?immutable=1" \
        "select count(*) from cookies where host_key like '%github%';" 2>/dev/null || true)
  case "$n" in ''|*[!0-9]*) n=0 ;; esac
  if [ "$n" -gt "$github" ]; then github="$n"; fi
done
[ "$github" -gt 0 ] || manque="$manque GitHub"

if [ -z "$manque" ]; then
  echo "Modèle prêt : Dashlane installé, session GitHub enregistrée."
  echo "Les prochains worktrees en hériteront."
else
  echo "Attention, il manque :$manque — relancer ce script."
  echo "Si c'est GitHub : Chrome n'écrit ses cookies qu'en quittant par Cmd+Q."
fi
