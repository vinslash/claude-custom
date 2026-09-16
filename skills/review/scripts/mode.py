#!/usr/bin/env python3
"""Deduit le mode de review d'une PR et imprime ses instructions.

La detection et les instructions arrivent ensemble : il n'y a pas de lecture
separee a oublier, et les trois modes qui ne servent pas ne coutent rien.

Usage : mode.py [PR]            PR = numero ou URL ; sinon la branche courante
        mode.py --mode N [PR]   force le mode : la phrase de l'utilisateur
                                prime toujours sur la detection
"""
import json
import re
import subprocess
import sys
from pathlib import Path

REFERENCES = Path(__file__).resolve().parent.parent / "references"
FICHIERS = {
    1: "mode-1-auto-review.md",
    2: "mode-2-traiter-la-review.md",
    3: "mode-3-reviewer.md",
    4: "mode-4-verifier.md",
}
TITRES = {
    1: "auto-review, avant de soumettre",
    2: "traiter la review recue",
    3: "reviewer la PR d'un collegue",
    4: "verifier les corrections",
}


def run(binaire, *args):
    r = subprocess.run([binaire, *args], capture_output=True, text=True)
    if r.returncode != 0:
        return None
    return r.stdout.strip()


def gh(*args):
    return run("gh", *args)


def git(*args):
    return run("git", *args)


def sortir(*lignes):
    print("\n".join(lignes))
    sys.exit(0)


def imprimer(mode, entete, avertissement=None):
    print("\n".join(entete))
    if avertissement:
        print("\n" + avertissement)
    print("\n" + "-" * 72 + "\n")
    print((REFERENCES / FICHIERS[mode]).read_text(encoding="utf-8").rstrip())


argv = sys.argv[1:]
force = None
if "--mode" in argv:
    i = argv.index("--mode")
    try:
        force = int(argv[i + 1])
    except (IndexError, ValueError):
        sortir("ERREUR : --mode attend 1, 2, 3 ou 4.")
    if force not in FICHIERS:
        sortir("ERREUR : --mode attend 1, 2, 3 ou 4.")
    del argv[i : i + 2]
cible = argv[:1]

moi = gh("api", "user", "--jq", ".login")
if not moi:
    sortir("ERREUR : `gh` ne repond pas. Verifier `gh auth status`.")

champs = "number,title,author,isDraft,reviewDecision,reviews,headRefName,url"
brut = gh("pr", "view", *cible, "--json", champs)

# Pas de PR ouverte : l'auto-review precede l'ouverture, c'est le mode 1.
if not brut:
    if force and force != 1:
        sortir("ERREUR : aucune PR resolue, seul le mode 1 est possible ici.")
    branche = git("rev-parse", "--abbrev-ref", "HEAD") or "?"
    imprimer(
        1,
        [
            "Mode 1 — %s" % TITRES[1],
            "Aucune PR ouverte sur la branche `%s`." % branche,
            "Decide par : rien a resoudre cote GitHub, l'auto-review precede",
            "l'ouverture. Le perimetre se lit sur `origin/$BASE...HEAD`.",
        ],
    )

pr = json.loads(brut)
auteur = (pr.get("author") or {}).get("login", "?")
mien = auteur == moi
reviews = pr.get("reviews") or []
tiers = [r for r in reviews if (r.get("author") or {}).get("login") != moi]
miennes = [r for r in reviews if (r.get("author") or {}).get("login") == moi]

sli = ""
for source in (pr.get("headRefName", ""), pr.get("title", "")):
    m = re.search(r"[Ss][Ll][Ii][-_]?(\d{3,})", source or "")
    if m:
        sli = "SLI-%s" % m.group(1)
        break

# Threads ouverts : sert la 2e question de la porte anti-overkill, et le
# script y repond mieux que la prose ne saurait l'expliquer.
ouverts = attente = None
m = re.match(r"https://[^/]+/([^/]+)/([^/]+)/pull/(\d+)", pr.get("url", ""))
if m:
    owner, repo, num = m.groups()
    q = """
      query($owner:String!,$repo:String!,$num:Int!){
        repository(owner:$owner,name:$repo){ pullRequest(number:$num){
          reviewThreads(first:100){ nodes{ isResolved
            comments(first:50){ nodes{ author{login} } } } } } } }
    """
    d = gh("api", "graphql", "-f", "query=%s" % q,
           "-F", "owner=%s" % owner, "-F", "repo=%s" % repo, "-F", "num=%s" % num)
    if d:
        noeuds = (json.loads(d)["data"]["repository"]["pullRequest"]
                  ["reviewThreads"]["nodes"])
        ouverts = [t for t in noeuds if not t["isResolved"]]
        # Un thread « en attente de nous » : ouvert, et dont le dernier
        # message ne vient pas de nous.
        attente = [t for t in ouverts
                   if t["comments"]["nodes"]
                   and t["comments"]["nodes"][-1]["author"]["login"] != moi]

if force:
    mode, decide = force, "force par --mode %d ; la detection disait autre chose" % force
elif mien:
    mode = 2 if tiers else 1
    decide = ("tu es l'auteur, et %d review(s) soumise(s) par %s"
              % (len(tiers), ", ".join(sorted({(r.get("author") or {}).get("login")
                                               for r in tiers})))) if tiers else \
             "tu es l'auteur, et personne n'a encore soumis de review"
else:
    mode = 4 if miennes else 3
    decide = ("la PR est de %s, et tu l'as deja relue (%d review(s))"
              % (auteur, len(miennes))) if miennes else \
             "la PR est de %s, et tu ne l'as pas encore relue" % auteur

entete = [
    "Mode %d — %s" % (mode, TITRES[mode]),
    "PR #%s « %s » de %s%s%s"
    % (pr.get("number"), pr.get("title", ""), auteur,
       " (toi)" if mien else "",
       " · %s" % sli if sli else ""),
    "Branche `%s`%s" % (pr.get("headRefName", "?"),
                        " · brouillon" if pr.get("isDraft") else ""),
    "Decide par : %s." % decide,
]
if ouverts is not None:
    entete.append("Threads : %d ouvert(s), dont %d en attente de toi."
                  % (len(ouverts), len(attente)))

# Porte anti-overkill, 2e question : en mode 2 et 4, pas de thread en attente
# = pas de passe a jouer.
if mode in (2, 4) and attente is not None and not attente and not force:
    sortir(*entete, "",
           "RIEN A TRAITER — aucun thread ouvert n'attend de reponse de toi.",
           "La porte anti-overkill coupe ici : le dire en trois lignes plutot",
           "que d'inventer du travail. Relancer avec `--mode %d` pour forcer." % mode)

imprimer(mode, entete)
