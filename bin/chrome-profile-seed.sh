#!/bin/sh
# Amorce un profil de worktree en le clonant depuis le profil modèle.
#
#   chrome-profile-seed.sh <dossier-du-profil>
#
# Appelé par `chrome-marker-proxy.py` au premier appel d'outil, et non plus au
# démarrage du serveur : un `claude` éphémère lancé dans un scratchpad démarre
# lui aussi le serveur `chrome` sans jamais ouvrir de navigateur, et le clonage
# au démarrage semait ainsi des profils parasites — `scratchpad`, `empty-cc`,
# `T`… — dans `~/.cache/chrome-mcp/`. Mesuré le 24/11/2026 : quinze profils sur
# quarante n'appartenaient à aucun worktree.
#
# Ne fait rien si le profil existe déjà ou si le modèle manque : sort 0 dans les
# deux cas, et dit sur stdout ce qu'il a fait, pour le journal.
set -eu

profile=$1
template="${HOME}/.cache/chrome-mcp/_modele"

if [ -d "$profile" ]; then
  echo "profil existant"
  exit 0
fi
if [ ! -d "$template" ]; then
  echo "profil neuf, sans modèle à cloner"
  exit 0
fi

# Passer par un dossier temporaire : un clone interrompu ne doit pas laisser
# derrière lui un profil à moitié rempli, que le lancement suivant prendrait
# pour un profil valide et n'amorcerait donc jamais.
workdir="${profile}.workdir.$$"
rm -rf "$workdir"

# -c demande un clone APFS : instantané, et le disque n'est payé qu'au fur et
# à mesure que le profil diverge du modèle. Le repli couvre les volumes qui
# ne savent pas cloner.
cp -Rc "$template" "$workdir" 2>/dev/null || cp -R "$template" "$workdir"

# Les verrous d'instance sont des liens symboliques vers le Chrome qui tenait
# le modèle. Recopiés tels quels, ils feraient croire au profil neuf qu'il est
# déjà ouvert ailleurs, et Chrome refuserait de démarrer.
rm -rf "$workdir/SingletonLock" "$workdir/SingletonCookie" "$workdir/SingletonSocket"

# Caches : reconstruits seuls, et ils pèsent l'essentiel du profil.
rm -rf "$workdir/Default/Cache" "$workdir/Default/Code Cache" \
       "$workdir/Default/GPUCache" "$workdir/Default/DawnGraphiteCache" \
       "$workdir/Default/DawnWebGPUCache" "$workdir/GraphiteDawnCache" \
       "$workdir/GPUPersistentCache"

mv "$workdir" "$profile"
echo "profil cloné depuis _modele"
