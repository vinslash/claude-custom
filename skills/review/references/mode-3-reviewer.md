# Mode 3 — Reviewer la PR d'un collègue

Les invariants du `SKILL.md` s'appliquent, celui-ci ne les répète pas. Deux
comptent plus que les autres ici : **on ne modifie jamais le code d'une PR qu'on
relit**, et **rien ne part sans arbitrage**.

**Commencer par recetter, pas par lire le diff.** Le worktree porte déjà sa
branche : dérouler le script « Comment tester » **en entier**, et noter à chaque
étape l'écart entre l'attendu annoncé et ce qu'on voit. Un écart est une remarque
en soi, et la plus solide de toutes — elle ne se discute pas. Le navigateur est
celui du serveur MCP `chrome` : charger `slash:chrome-isolation` avant la
première action.

Absence de « Comment tester », ou script qui ne se déroule pas : c'est la
première remarque, elle est bloquante, et elle se pose **tout de suite** plutôt
qu'à la fin. On ne relit pas le code d'une PR dont personne ne peut vérifier
l'effet, et l'auteur peut réparer ça pendant qu'on lit.

Puis, dans cet ordre :

1. **Les contrôles mécaniques** — lint, typage, et les red flags SDDD si le diff
   touche `backend/src/` :

   ```bash
   python3 <base-dir du skill>/../process-ticket/scripts/red-flags-sddd.py
   ```

   Sur la PR d'un collègue, ce qu'ils sortent est la remarque la plus solide
   après un écart de recettage : elle cite une règle du dépôt, pas un goût.

2. **Le ticket contre la PR** : ce que le ticket demande est-il livré, entier, et
   rien d'autre ?
3. **Le code** : correction sur les cas limites, régression sur l'existant,
   décision de conception qui coûtera cher à défaire. Pas le style.

Livrable : le tableau d'arbitrage et la reco globale. Après arbitrage, la review
part **d'un bloc** — remarques ancrées aux lignes et état de review dans le même
envoi, voir `mecanique-gh.md`. Poster les remarques une par une notifie l'auteur
à chaque fois et le fait travailler sur une review incomplète.
