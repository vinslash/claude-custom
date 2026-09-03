#!/bin/sh
# Lanceur du serveur MCP `chrome`.
#
# Il fait quatre choses que `.mcp.json` ne sait pas faire seul :
#
#   - dériver le profil du worktree courant, pour que deux sessions parallèles
#     n'aient jamais le même navigateur ;
#   - amorcer un profil neuf en clonant le profil modèle, pour que les
#     extensions y soient déjà installées et connectées — Dashlane en tête ;
#   - retirer le `--disable-extensions` que Puppeteer pose par défaut, sans
#     quoi le profil aurait beau être garni, aucune extension ne démarrerait ;
#   - retirer le `--use-mock-keychain`, sans quoi Chrome vide le profil de ses
#     extensions au premier lancement — voir plus bas.
#
# Le tenir ici plutôt que dans `.mcp.json` a une conséquence pratique : le
# modifier ne demande plus de `/reload-plugins`. Le câblage nomme un script, le
# script est relu à chaque lancement. Même raison que pour `hooks/hooks.json`.
set -eu

base="${HOME}/.cache/chrome-mcp"
modele="${base}/_modele"

racine=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
profil="${base}/$(basename "$racine")"

if [ ! -d "$profil" ] && [ -d "$modele" ]; then
  # Passer par un dossier temporaire : un clone interrompu ne doit pas laisser
  # derrière lui un profil à moitié rempli, que le lancement suivant prendrait
  # pour un profil valide et n'amorcerait donc jamais.
  chantier="${profil}.chantier.$$"
  rm -rf "$chantier"

  # -c demande un clone APFS : instantané, et le disque n'est payé qu'au fur et
  # à mesure que le profil diverge du modèle. Le repli couvre les volumes qui
  # ne savent pas cloner.
  cp -Rc "$modele" "$chantier" 2>/dev/null || cp -R "$modele" "$chantier"

  # Les verrous d'instance sont des liens symboliques vers le Chrome qui tenait
  # le modèle. Recopiés tels quels, ils feraient croire au profil neuf qu'il est
  # déjà ouvert ailleurs, et Chrome refuserait de démarrer.
  rm -rf "$chantier/SingletonLock" "$chantier/SingletonCookie" "$chantier/SingletonSocket"

  # Caches : reconstruits seuls, et ils pèsent l'essentiel du profil.
  rm -rf "$chantier/Default/Cache" "$chantier/Default/Code Cache" \
         "$chantier/Default/GPUCache" "$chantier/Default/DawnGraphiteCache" \
         "$chantier/Default/DawnWebGPUCache" "$chantier/GraphiteDawnCache" \
         "$chantier/GPUPersistentCache"

  mv "$chantier" "$profil"
fi

# `--use-mock-keychain` fait passer OSCrypt sur un trousseau simulé. Sur macOS,
# la clé du vrai trousseau scelle aussi les préférences protégées : sans elle,
# Chrome ne peut plus valider `Default/Secure Preferences`, conclut à une
# altération et efface l'entrée d'installation de chaque extension. Le payload
# suit au ramassage suivant, et `--disable-background-networking` interdit toute
# réinstallation : le profil reste nu. Mesuré le 28/08/2026 — avec le drapeau,
# l'entrée Dashlane tombe de 29 clés à 4 dès le premier lancement ; sans lui,
# elle est intacte après trois lancements. Le chemin du profil n'y est pour rien.
#
# Ce qu'on paie en le retirant : ce Chrome-là lit la clé « Chrome Safe Storage »
# du vrai trousseau, comme le Chrome personnel. Il n'accède pas pour autant à son
# profil, qui vit ailleurs. C'est le prix d'une session Dashlane utilisable, qui
# est précisément ce qu'on cherche.
exec npx -y chrome-devtools-mcp@latest \
  --userDataDir="$profil" \
  --viewport 1440x820 \
  --ignore-default-chrome-arg='--disable-extensions' \
  --ignore-default-chrome-arg='--use-mock-keychain'
