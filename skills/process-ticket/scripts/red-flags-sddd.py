#!/usr/bin/env python3
"""Red flags SDDD sur les fichiers back touches par la branche.

Reprend la table « Red flags — stop et corriger » de slash-ddd-backend et les
invariants de .claude/rules/sddd-structure.md. Un depassement = code de sortie 1.

Usage : red-flags-sddd.py [base]
        red-flags-sddd.py --tout      (audit du depot entier, pour calibrer)
"""
import os, re, subprocess, sys

TOUT = "--tout" in sys.argv
args = [a for a in sys.argv[1:] if not a.startswith("-")]

def fichiers_branche(base):
    out = subprocess.run(["git", "diff", "--name-only", "--diff-filter=ACMR", f"{base}...HEAD"],
                         capture_output=True, text=True).stdout.split()
    return [f for f in out if f.startswith("backend/src/") and f.endswith(".ts")]

def fichiers_tout():
    out = []
    for root, _, fs in os.walk("backend/src"):
        for f in fs:
            if f.endswith(".ts"):
                out.append(os.path.join(root, f))
    return out

if TOUT:
    files = fichiers_tout()
else:
    base = args[0] if args else (subprocess.run(
        ["git", "symbolic-ref", "--short", "refs/remotes/origin/HEAD"],
        capture_output=True, text=True).stdout.strip().replace("origin/", "") or "develop")
    files = fichiers_branche(base)

files = [f for f in files if "__tests__" not in f and "/migrations/" not in f
         and not f.endswith("spec.ts")]

CHECKS = [
    ("couche",     "core/ ou application/ importe infrastructure/",
     lambda p, s: bool(re.search(r"/(core|application)/", p)) and re.search(r"from '[^']*infrastructure/", s)),
    ("controller", "repository injecte dans un controller",
     lambda p, s: p.endswith(".controller.ts") and
                  re.search(r"@InjectRepository|@Inject\([A-Za-z]*Repository[A-Za-z]*Interface\)", s)),
    ("typeorm",    "annotation TypeORM dans core/",
     lambda p, s: "/core/" in p and re.search(r"^\s*@(Entity|Column|ManyToOne|OneToMany|JoinColumn)\(", s, re.M)),
    ("cycle",      "forwardRef pour masquer un cycle",
     lambda p, s: p.endswith(".module.ts") and "forwardRef(" in s),
    ("internal",   "*-internal.controller.ts (proscrit par ARCHITECTURE.md §2)",
     lambda p, s: p.endswith("-internal.controller.ts")),
    ("cast",       "as any / as unknown as pour forcer un typage",
     lambda p, s: re.search(r"\bas any\b|as unknown as ", s)),
]

trouve = {}
for p in files:
    try:
        s = open(p, encoding="utf-8", errors="ignore").read()
    except OSError:
        continue
    for code, label, test in CHECKS:
        if test(p, s):
            trouve.setdefault((code, label), []).append(p)

total = 0
for (code, label), ps in sorted(trouve.items()):
    print(f"[{code}] {label} — {len(ps)} fichier(s)")
    for p in sorted(ps)[:8]:
        print(f"        {p.replace('backend/src/', '')}")
    if len(ps) > 8:
        print(f"        … et {len(ps) - 8} autre(s)")
    total += len(ps)
    print()
portee = "le depot entier" if TOUT else f"les {len(files)} fichier(s) back touche(s)"
print(f"{total} signalement(s) sur {portee}.")
sys.exit(1 if total and not TOUT else 0)
