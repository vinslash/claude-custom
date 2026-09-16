# Mode 1 — L'auto-review, avant de soumettre

Ce qu'on cherche : ce que le relecteur va demander, pour qu'il n'ait pas à le
demander. Les invariants du `SKILL.md` s'appliquent, celui-ci ne les répète pas.

1. **Lancer les contrôles mécaniques** sur la branche — lint et typage ciblés sur
   ce qui est touché, et le contrôle des red flags SDDD si le diff touche
   `backend/src/` :

   ```bash
   python3 <base-dir du skill>/../process-ticket/scripts/red-flags-sddd.py
   ```

   depuis la racine du worktree. Sur sa propre PR, ce qu'ils sortent se corrige
   ou s'assume avant de soumettre — ça ne se présente pas comme une remarque.

2. **Relire le diff contre le ticket**, pas contre un idéal : un critère
   d'acceptation non couvert, un cas limite du ticket oublié, un effet de bord
   hors périmètre qui a été livré quand même.

3. **Vérifier que la PR est relisible** : le script « Comment tester » est jouable
   par un tiers — prérequis, jeu de données, point d'entrée, attendu à chaque
   étape —, les captures avant/après sont là si l'UI bouge, le lien Linear
   referme le ticket. C'est `slash:writing` qui porte ces trois exigences ; une
   PR qui les rate se fera retoquer avant même la lecture du code. Si la PR n'est
   pas encore ouverte, le point tient quand même : c'est ce qu'il restera à
   écrire, et l'étape 7 de `slash:process-ticket` s'en charge.

Le script de recettage ne se rejoue pas : l'étape 4 de `slash:process-ticket`
vient de le dérouler. On vérifie qu'il est **jouable par un tiers**, pas qu'il
marche. Absent ou illisible, ce n'est pas une remarque : la PR n'est pas prête à
être soumise.

Rien n'est posté. Le livrable est le tableau d'arbitrage, la reco globale —
soumettre, ou corriger d'abord —, et les corrections appliquées après
l'arbitrage de l'utilisateur.
