#!/usr/bin/env bash
# `FileChanged` : un fichier de configuration a bougé sur disque.
#
# C'est le maillon qui rend la chaîne automatique. Ce hook se déclenche SEUL,
# sans prompt, sans que personne ne tape quoi que ce soit — dans toutes les
# sessions ouvertes à la fois, à la seconde où `git pull` pose les fichiers. La
# liste surveillée est déclarée par `session-start.sh` (`watchPaths`).
#
# Il ne peut pas injecter de contexte : sur cet événement, seul `systemMessage`
# sort, et il va à l'utilisateur, pas au modèle. Il pose donc un marqueur, que
# `user-prompt-submit.sh` consomme au message suivant pour le vrai rattrapage.

set -u
# shellcheck source=./commun.sh
. "$(dirname "${BASH_SOURCE[0]}")/commun.sh"

# La reconnaissance du fichier se fait en python et pas en shell, pour une raison
# précise : sur macOS, la surveillance de fichiers rapporte parfois un chemin
# préfixé `/System/Volumes/Data`. Comparé par égalité de chaînes à notre liste, il
# ne correspondrait à rien — et le rattrapage ne partirait jamais, sans le moindre
# signe. On normalise donc les deux côtés, et on écrit dans le marqueur NOTRE
# forme du chemin, pour que la comparaison en aval soit exacte par construction.
#
# La liste surveillée peut par ailleurs contenir des chemins posés par d'autres
# sources : ce qui n'est pas à nous est ignoré.
lu=$(CC_A="$(instructions_permanentes)" CC_B="$(cablage)" python3 -c '
import json, os, sys

def normalise(p):
    p = os.path.realpath(os.path.expanduser(p))
    prefixe = "/System/Volumes/Data"
    if p.startswith(prefixe + "/"):
        p = p[len(prefixe):]
    return p

try:
    d = json.load(sys.stdin)
except Exception:
    sys.exit(1)
sid = d.get("session_id") or ""
vu = d.get("file_path") or ""
if not sid or not vu:
    sys.exit(1)

vu = normalise(vu)
for nom in ("CC_A", "CC_B"):
    for f in os.environ.get(nom, "").split("\n"):
        if f.strip() and normalise(f) == vu:
            print("%s\t%s\t%s" % (sid, f, "a" if nom == "CC_A" else "b"))
            sys.exit(0)
sys.exit(1)
' 2>/dev/null) || exit 0

IFS=$'\t' read -r sid fichier categorie <<< "$lu"
[ -n "${sid:-}" ] && [ -n "${fichier:-}" ] || exit 0

attente="$SESSIONS/$sid.attente"
grep -qxF "$fichier" "$attente" 2>/dev/null || printf '%s\n' "$fichier" >> "$attente"

# Une mise à jour touche plusieurs fichiers, et ce hook part une fois par
# fichier : sans ça, un `pull` de trois fichiers afficherait trois fois le même
# message. Le premier parle, les suivants accumulent en silence — et le
# rattrapage, lui, sera précis.
signale="$SESSIONS/$sid.signale"
if [ -f "$signale" ]; then
  pose=$(stat -f %m "$signale" 2>/dev/null || stat -c %Y "$signale" 2>/dev/null || echo 0)
  [ $(($(date +%s) - pose)) -lt 15 ] && exit 0
fi
: > "$signale"

# `/reload-plugins` ne concerne que le câblage. Ne le dire que quand c'est vrai :
# un avertissement affiché à chaque modification de skill serait ignoré au bout
# de deux jours, et ne servirait plus le jour où il compte.
recharger=0
while IFS= read -r f; do
  [ -n "$f" ] && grep -qxF "$f" "$attente" 2>/dev/null && recharger=1
done < <(cablage)

if [ "$recharger" = 1 ]; then
  # Les deux gestes, parce que le hook ne sait pas d'où il parle : la commande
  # /reload-plugins n'est pas exposée par l'extension VSCode, où il faut ouvrir
  # une nouvelle session. Voir docs/propagation.md.
  msg='Configuration slash mise à jour — le câblage du plugin a changé : /reload-plugins dans le terminal, nouvelle session dans VSCode.'
else
  msg='Configuration slash mise à jour — skills déjà rechargés, instructions permanentes au prochain message.'
fi

MSG="$msg" python3 -c '
import json, os
print(json.dumps({"systemMessage": os.environ["MSG"]}))
'
