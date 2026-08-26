# Quand un changement prend effet

Ce qui se recharge à chaud, ce qui ne se recharge pas, et la chaîne qui rattrape
le reste sans qu'on ait rien à faire.

## Ce qui se propage tout seul

Une session ouverte depuis trois jours doit bénéficier d'un correctif sans qu'on
la redémarre. Ce qui se recharge à chaud et ce qui ne se recharge pas n'est pas
affaire de goût : c'est ce que Claude Code sait faire, vérifié.

| Ce qui change | Propagation |
| --- | --- |
| Corps d'un `SKILL.md`, sa description, ajout, suppression, renommage | Surveillant natif, dans la session en cours |
| Corps d'un handler de hook | Relu à chaque déclenchement — `hooks.json` ne nomme qu'un script |
| `~/.claude/settings.json` | Surveillant natif |
| `CLAUDE.md` et ses imports `@` — `RTK.md`, les `AMORCE.md` | **Rien ne les relit.** Réinjectés par `user-prompt-submit.sh` |
| `hooks/hooks.json`, `.mcp.json`, `agents/`, `output-styles/` | `/reload-plugins` — le seul geste manuel qui reste |

Les instructions permanentes sont le trou réel, et le plus sournois : une session
de trois jours obéit aux amorces d'il y a trois jours, et rien ne le montre. D'où
la chaîne, qui ne demande aucun geste —

launchd tire → les fichiers changent sur disque → `FileChanged` part **seul**,
sans prompt, dans toutes les sessions ouvertes à la fois → les skills sont déjà
rechargés → un message dit ce qui a bougé → et au message suivant, le contenu
frais des instructions permanentes est réinjecté dans le contexte.

Rattraper au message suivant plutôt qu'à l'instant du changement n'est pas un
pis-aller : c'est l'instant juste avant que ces instructions puissent compter. Une
session au repos n'a besoin de rien.

`.mcp.json` suit la même discipline : il ne nomme que `bin/chrome-mcp.sh`. Le
script est relu à chaque lancement du serveur, donc changer la façon dont Chrome
démarre — un argument, le clonage du profil modèle — ne coûte rien. Seul un
changement du câblage lui-même redemanderait `/reload-plugins`.

**`/reload-plugins` est irréductible.** Le câblage du plugin vit dans la mémoire du
process, et `reload_plugins` est une control request réservée au SDK — vérifié dans
le binaire : aucun hook ne peut la déclencher. D'où `hooks.json` réduit à nommer
des scripts : tant qu'on n'y ajoute pas d'événement, il ne bouge plus, et le geste
manuel ne se présente jamais.

L'état des hooks vit dans `~/.claude/slash-etat/` — un marqueur par session, le
journal des mises à jour. Jamais dans le clone, qui doit rester impeccable.

`claude plugin validate` avertit que le `CLAUDE.md` de la racine « n'est pas
chargé comme contexte de projet ». C'est **attendu** : il n'est pas censé l'être,
il est
lu via le lien `~/.claude/CLAUDE.md` en tant qu'instructions globales. Ne pas
chercher à faire taire cet avertissement en déplaçant ou en supprimant le fichier.
