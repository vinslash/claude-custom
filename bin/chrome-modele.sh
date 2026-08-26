#!/bin/sh
# Ouvre le profil modèle dont chaque profil de worktree sera cloné.
#
# C'est la seule et unique fois où l'on lance Chrome à la main — voir le skill
# `chrome-ancrage`, qui l'interdit partout ailleurs. Ce lancement-ci est sûr :
# aucun port de debug n'est ouvert, donc aucune session Claude ne peut se
# tromper de navigateur et venir piloter celui-ci.
#
# À faire dans cette fenêtre : installer les extensions voulues depuis le Chrome
# Web Store — Dashlane — et s'y connecter. Puis fermer la fenêtre. Tout profil de
# worktree créé ensuite partira de cet état.
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

mkdir -p "$modele"

echo "Profil modèle : $modele"
echo
echo "Dans la fenêtre qui s'ouvre : installer Dashlane depuis le Chrome Web Store,"
echo "et s'y connecter."
echo
echo "Puis QUITTER PAR CMD+Q, et non en fermant la dernière fenêtre — sur macOS"
echo "Chrome survit parfois à sa dernière fenêtre, et un profil pas encore vidé"
echo "sur disque serait cloné à moitié écrit. Ne pas interrompre ce script."
echo
echo "Les profils de worktree DÉJÀ créés ne changent pas. Pour qu'un ticket en"
echo "cours reparte du modèle, supprimer son dossier dans ~/.cache/chrome-mcp/."
echo

"$chrome" --user-data-dir="$modele" --no-first-run --no-default-browser-check \
  "https://chromewebstore.google.com/detail/fdjamakpfbbddfjaooikfcpapjohcfmg" || true

# Chrome est sorti. Les verrous d'instance sont des liens symboliques vers le
# process qui vient de mourir ; `chrome-mcp.sh` les jette de toute façon à chaque
# clonage, mais les laisser ici rendrait le modèle inouvrable à la main.
rm -f "$modele/SingletonLock" "$modele/SingletonCookie" "$modele/SingletonSocket"

echo
extensions="$modele/Default/Extensions"
if [ -d "$extensions/fdjamakpfbbddfjaooikfcpapjohcfmg" ]; then
  echo "Modèle prêt : Dashlane installé. Les prochains worktrees en hériteront."
else
  echo "Attention : Dashlane n'est pas dans le modèle. Relancer ce script."
fi
