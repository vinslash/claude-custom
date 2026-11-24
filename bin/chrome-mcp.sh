#!/bin/sh
# Lanceur du serveur MCP `chrome`.
#
# Il fait cinq choses que `.mcp.json` ne sait pas faire seul :
#
#   - dériver le profil du worktree courant, pour que deux sessions parallèles
#     n'aient jamais le même navigateur ;
#   - faire amorcer un profil neuf, au premier appel d'outil, en clonant le
#     profil modèle, pour que les extensions y soient déjà installées et
#     connectées — Dashlane en tête ;
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

base_dir="${HOME}/.cache/chrome-mcp"

workspace_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
profile="${base_dir}/$(basename "$workspace_root")"

# Le profil n'est PAS cloné ici : le serveur démarre avec chaque session, y
# compris les `claude` éphémères qui n'ouvriront jamais de navigateur. Le relais
# l'amorce au premier appel d'outil, par `chrome-profile-seed.sh`.

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
# retiré `--load-extension`. Le CDP sait encore installer, lui : c'est l'outil
# `install_extension`, d'où le `--categoryExtensions` plus bas.
#
# Mais ce qu'il pose ne survit pas au navigateur. Mesuré : premier lancement,
# extension active et service worker en vie ; deuxième lancement sur le même
# profil, plus aucune trace, l'entrée a même disparu des préférences. Il faut
# donc reposer l'extension à chaque ouverture — ce qui interdit d'en faire un
# geste de session, et interdit aussi de l'installer une fois dans le modèle
# pour que les profils en héritent. D'où le relais `chrome-marker-proxy.py`,
# qui s'en charge tout seul au premier appel d'outil.
#
# Le dossier vit dans le worktree, et pas à côté du profil, parce que
# `install_extension` refuse tout chemin hors des roots MCP — vérifié, y compris
# avec `--allowUnrestrictedPaths`, qui ne couvre que le cas où le client n'en
# déclare aucune. Or une session Claude déclare toujours son worktree.
here=$(cd "$(dirname "$0")" && pwd)
marker_dir="${workspace_root}/.chrome-marker"

label=$(basename "$workspace_root")
case "$label" in
  sli-[0-9]*)
    number=${label#sli-}
    label="SLI-${number%%-*}"
    case "$(basename "$workspace_root")" in
      *-review) label="$label · review" ;;
    esac
    ;;
esac

# Écraser les fichiers un à un plutôt que refaire le dossier : deux sessions sur
# le même worktree se marcheraient dessus, et Chrome tient l'extension ouverte
# depuis ce chemin.
#
# Le worker porte un nom tiré de son contenu, étiquette comprise. Chrome garde
# dans le profil l'enregistrement du service worker de l'extension, et le
# reprend tel quel à chaque réinstallation : même nom de script, même code,
# quels que soient le fichier sur disque et le numéro de version. Mesuré le
# 05/10 — après une mise à jour du worker, le fichier servi était le nouveau,
# le code exécuté l'ancien. Un nom neuf est la seule chose qui le fasse relire.
mkdir -p "$marker_dir"
printf 'globalThis.LABEL = "%s";\n' "$label" > "$marker_dir/label.js"
worker="worker-$(cat "$here/extension-marker/worker.js" "$marker_dir/label.js" | shasum | cut -c1-12).js"
cp "$here/extension-marker/worker.js" "$marker_dir/$worker"
sed "s/\"worker\.js\"/\"$worker\"/" "$here/extension-marker/manifest.json" > "$marker_dir/manifest.json"
# Les versions précédentes ne servent plus à rien : le manifeste ne les nomme
# plus.
find "$marker_dir" -name 'worker*.js' ! -name "$worker" -delete

# Git ne doit pas voir passer ce dossier. L'exclusion va dans le fichier local du
# dépôt, jamais dans le `.gitignore` versionné : c'est de l'outillage de poste,
# il n'a rien à faire dans l'historique de l'équipe.
if git_common=$(git -C "$workspace_root" rev-parse --path-format=absolute --git-common-dir 2>/dev/null); then
  mkdir -p "$git_common/info"
  grep -qxF '.chrome-marker/' "$git_common/info/exclude" 2>/dev/null \
    || echo '.chrome-marker/' >> "$git_common/info/exclude"
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
#
# La version est épinglée. `@latest` faisait changer le serveur sous nos pieds
# sans que rien ne le dise, alors que le relais dépend de sa prose : c'est la
# phrase « the browser was restarted » qui déclenche la repose du repère. Pour
# monter de version, vérifier que cette phrase existe toujours (`grep -r` dans
# le paquet), puis changer le numéro ici.
#
# Le journal vit hors de `~/.cache/chrome-mcp`, où `chrome-propagate.sh`
# prendrait tout dossier pour un profil. Il est la seule trace d'un repère qui
# n'a pas été posé : le stderr du relais n'est conservé nulle part.
export CHROME_MCP_PROFILE="$profile"
export CHROME_MCP_LABEL="$label"
export CHROME_MCP_SEED="$here/chrome-profile-seed.sh"
export CHROME_MCP_LOG="${HOME}/Library/Logs/chrome-mcp/$(basename "$profile").log"
exec python3 "$here/chrome-marker-proxy.py" "$marker_dir" \
  npx -y chrome-devtools-mcp@1.13.0 \
  --userDataDir="$profile" \
  --viewport 1440x820 \
  --categoryExtensions \
  --ignore-default-chrome-arg='--disable-extensions' \
  --ignore-default-chrome-arg='--use-mock-keychain'
