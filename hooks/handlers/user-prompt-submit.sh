#!/usr/bin/env bash
# `UserPromptSubmit` : le seul endroit d'où l'on peut réparer des instructions
# permanentes périmées.
#
# Ce hook tourne à CHAQUE message, dans toutes les sessions : il doit donc ne
# rien coûter quand il n'y a rien à faire. D'où le chemin rapide ci-dessous — un
# glob, aucun `python3`, aucune lecture de fichier. Le travail réel n'a lieu que
# si `file-changed.sh` a laissé un marqueur, c'est-à-dire seulement après une
# vraie mise à jour.
#
# Rattraper ici plutôt qu'au moment du changement n'est pas un pis-aller : c'est
# l'instant juste avant que ces instructions puissent compter. Une session au
# repos n'a besoin de rien.

set -u
# shellcheck source=./commun.sh
. "$(dirname "${BASH_SOURCE[0]}")/commun.sh"

# Chemin rapide : aucun marqueur pour personne, on sort avant même de savoir de
# quelle session il s'agit.
shopt -s nullglob
marqueurs=("$SESSIONS"/*.attente)
[ ${#marqueurs[@]} -gt 0 ] || exit 0

sid=$(python3 -c '
import json, sys
try:
    print(json.load(sys.stdin).get("session_id", ""))
except Exception:
    pass
' 2>/dev/null)
[ -n "${sid:-}" ] || exit 0

attente="$SESSIONS/$sid.attente"
[ -f "$attente" ] || exit 0

a=$(instructions_permanentes)
b=$(cablage)

# Le marqueur est consommé avant de produire la sortie : si quelque chose échoue
# après, on préfère rater un rattrapage que le rejouer à chaque message.
modifies=$(cat "$attente")
rm -f "$attente" "$SESSIONS/$sid.signale"
empreinte_instructions > "$SESSIONS/$sid.empreinte" 2>/dev/null

CC_A="$a" CC_B="$b" CC_MODIFIES="$modifies" python3 -c '
import json, os, sys

def liste(nom):
    return [l for l in os.environ.get(nom, "").split("\n") if l.strip()]

modifies = liste("CC_MODIFIES")
a = [f for f in liste("CC_A") if f in modifies]
b = [f for f in liste("CC_B") if f in modifies]
if not a and not b:
    sys.exit(0)

PLAFOND = 40000
bouts = []

if a:
    bouts.append(
        "La configuration `slash` a été mise à jour sur disque depuis l’ouverture de "
        "cette session. Les instructions permanentes ci-dessous ont changé : "
        "**cette version fait foi** et remplace celle chargée au démarrage."
    )
    total = 0
    tronque = []
    for f in a:
        try:
            with open(f, encoding="utf-8") as fh:
                contenu = fh.read()
        except FileNotFoundError:
            bouts.append("--- %s ---\n(supprimé)" % f)
            continue
        except OSError:
            continue
        if total + len(contenu) > PLAFOND:
            tronque.append(f)
            continue
        total += len(contenu)
        bouts.append("--- %s ---\n%s" % (f, contenu.strip()))
    if tronque:
        # Réinjecter sans limite ferait exploser le contexte le jour où une amorce
        # grossit. Mieux vaut une lecture explicite qu’un contexte noyé.
        bouts.append(
            "Trop volumineux pour être réinjecté, à lire avec l’outil Read avant "
            "de t’en servir : " + ", ".join(tronque)
        )

if b:
    bouts.append(
        "Le câblage du plugin a changé (%s). Il ne peut pas être rechargé à chaud : "
        "dis à l’utilisateur de lancer `/reload-plugins`. Les skills, eux, sont "
        "déjà à jour." % ", ".join(os.path.basename(f) for f in b)
    )

bouts.append(
    "Annonce-le à l’utilisateur en une ligne — il doit savoir pourquoi ton "
    "comportement peut changer — puis continue sur sa demande."
)

print(json.dumps({
    "hookSpecificOutput": {
        "hookEventName": "UserPromptSubmit",
        "additionalContext": "\n\n".join(bouts),
    }
}))
'
