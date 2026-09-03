#!/bin/sh
# Lanceur du serveur MCP `chrome`.
#
# Il fait cinq choses que `.mcp.json` ne sait pas faire seul :
#
#   - dériver le profil du worktree courant, pour que deux sessions parallèles
#     n'aient jamais le même navigateur ;
#   - amorcer un profil neuf en clonant le profil modèle, pour que les
#     extensions y soient déjà installées et connectées — Dashlane en tête ;
#   - poser un onglet de repère qui dit à quel worktree la fenêtre appartient ;
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

# L'onglet de repère. Une dizaine de fenêtres Chrome identiques à l'écran, et
# plus rien ne dit laquelle appartient à quel worktree. Les places qui portent
# une identité dans le chrome de la fenêtre sont toutes prises ou trop petites :
# le nom du profil ne s'affiche que dans le menu du profil, et l'avatar n'a la
# place que de deux caractères — mesuré, un `SLI-8422` n'y tient pas.
#
# Ce qu'on aurait voulu et qui n'existe pas : un groupe d'onglets, dont le chip
# est exactement ça, une couleur et un libellé dans la barre d'onglets. Aucune
# commande du CDP n'en crée (Chrome 150 expose `tabGroupId`, en lecture seule),
# et les groupes vivent dans le fichier de session binaire. Une extension qui
# poserait un vrai badge est fermée aussi : Chrome 142 a retiré
# `--load-extension` et son contournement.
#
# Reste l'onglet, seul objet de la barre d'onglets qui porte du texte long et
# qu'on sache fabriquer sans main humaine.
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

mkdir -p "$profil"
carte="${profil}/repere-ne-pas-naviguer.html"
cat > "$carte" <<HTML
<!doctype html>
<html lang="fr">
<meta charset="utf-8">
<title>$etiquette</title>
<link rel="icon" type="image/svg+xml" href="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 16 16'%3E%3Crect width='16' height='16' rx='3.5' fill='%23F4D63E'/%3E%3Cpath d='M10.4 3.2 5.6 12.8' stroke='%23191500' stroke-width='2.6' stroke-linecap='round'/%3E%3C/svg%3E">
<style>
  body { margin: 0; height: 100vh; display: grid; place-content: center; gap: .6rem;
         text-align: center; background: #faf8f2; color: #191500;
         font: 15px/1.5 -apple-system, system-ui, sans-serif; }
  h1 { margin: 0; font-size: 3.2rem; letter-spacing: -.02em; }
  h1::before { content: ""; display: inline-block; vertical-align: .1em;
               width: .5em; height: .5em; margin-right: .35em; border-radius: .12em;
               background: #F4D63E; }
  p { margin: 0; color: #6b6450; }
  code { font-size: .95em; }
</style>
<h1>$etiquette</h1>
<p><code>$racine</code></p>
<p>Onglet de repère : il dit à quel worktree cette fenêtre appartient.<br>Ne pas naviguer ici.</p>
HTML

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
# `about:blank` est posé à la main parce que Puppeteer ne l'ajoute que si tous
# les arguments reçus commencent par un tiret, ce que le repère rompt. Sans lui,
# la seule page ouverte serait le repère, et la première session venue le
# naviguerait pour travailler.
#
# L'ordre des deux URL, lui, ne se commande pas : observé dans les deux sens —
# `about:blank` en premier sur un profil neuf, le repère en premier sur un
# profil déjà rodé. Rien ne doit donc en dépendre, et surtout pas le fait que le
# repère ne soit pas la page sélectionnée. D'où son nom de fichier, qui porte la
# consigne jusque dans la liste des pages, pour la session qui n'aurait pas lu
# le skill `chrome-ancrage`.
exec npx -y chrome-devtools-mcp@latest \
  --userDataDir="$profil" \
  --viewport 1440x820 \
  --chromeArg="file://$carte" \
  --chromeArg=about:blank \
  --ignore-default-chrome-arg='--disable-extensions' \
  --ignore-default-chrome-arg='--use-mock-keychain'
