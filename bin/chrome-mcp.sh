#!/bin/sh
# Lanceur du serveur MCP `chrome`.
#
# Il fait cinq choses que `.mcp.json` ne sait pas faire seul :
#
#   - dériver le profil du worktree courant, pour que deux sessions parallèles
#     n'aient jamais le même navigateur ;
#   - amorcer un profil neuf en clonant le profil modèle, pour que les
#     extensions y soient déjà installées et connectées — Dashlane en tête ;
#   - préparer l'extension qui range les onglets dans un groupe au nom du
#     ticket, pour qu'on sache de loin à quel worktree une fenêtre appartient ;
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

# Le repère. Une dizaine de sessions en parallèle, donc une dizaine de fenêtres
# Chrome identiques, et plus rien qui dise laquelle sert quel ticket. Les places
# du chrome de la fenêtre ont été essayées et mesurées : le nom de profil ne
# s'affiche que dans le menu déplié, la photo de profil tient deux caractères
# quand `SLI-8422` en demande huit, le chip « Bonjour X » se replie au bout de
# quelques secondes, et la couleur de fenêtre est refusée en écriture.
#
# Reste ce que fait l'extension Claude for Chrome : un **groupe d'onglets**,
# c'est-à-dire un chip coloré et nommé dans la barre d'onglets. Il faut une
# extension pour ça — `chrome.tabGroups` n'existe que là — et Chrome 142 a
# retiré `--load-extension`. Mais le CDP, lui, sait installer : c'est l'outil
# `install_extension` du serveur, d'où le `--categoryExtensions` plus bas. La
# pose revient donc à la session, une fois par profil ; Chrome l'inscrit ensuite
# dans le profil et la recharge tout seul. Voir le skill `chrome-ancrage`.
#
# Le dossier vit dans le worktree, et pas à côté du profil, parce que
# `install_extension` refuse tout chemin hors des roots MCP — vérifié, y compris
# avec `--allowUnrestrictedPaths`, qui ne couvre que le cas où le client n'en
# déclare aucune. Or une session Claude déclare toujours son worktree.
ici=$(cd "$(dirname "$0")" && pwd)
atelier="${racine}/.chrome-repere"

etiquette=$(basename "$racine")
case "$etiquette" in
  sli-[0-9]*)
    numero=${etiquette#sli-}
    etiquette="SLI-${numero%%-*}"
    case "$(basename "$racine")" in
      *-review) etiquette="$etiquette · review" ;;
    esac
    ;;
esac

# Écraser les fichiers un à un plutôt que refaire le dossier : deux sessions sur
# le même worktree se marcheraient dessus, et Chrome tient l'extension ouverte
# depuis ce chemin.
mkdir -p "$atelier"
cp "$ici/extension-repere/manifest.json" "$ici/extension-repere/worker.js" "$atelier/"
printf 'globalThis.ETIQUETTE = "%s";\n' "$etiquette" > "$atelier/etiquette.js"

# Git ne doit pas voir passer ce dossier. L'exclusion va dans le fichier local du
# dépôt, jamais dans le `.gitignore` versionné : c'est de l'outillage de poste,
# il n'a rien à faire dans l'historique de l'équipe.
if commun=$(git -C "$racine" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  mkdir -p "$commun/info"
  grep -qxF '.chrome-repere/' "$commun/info/exclude" 2>/dev/null \
    || echo '.chrome-repere/' >> "$commun/info/exclude"
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
  --categoryExtensions \
  --ignore-default-chrome-arg='--disable-extensions' \
  --ignore-default-chrome-arg='--use-mock-keychain'
