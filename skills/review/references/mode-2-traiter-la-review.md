# Mode 2 — Traiter la review reçue

Les invariants du `SKILL.md` s'appliquent, celui-ci ne les répète pas. La
mécanique `gh` est dans `mecanique-gh.md`, à lire au moment de publier.

1. **Lire tous les threads**, résolus compris : un débat déjà tranché ne se
   rouvre pas.
2. **Ne retenir que les threads ouverts dont le dernier message vient du
   relecteur.** Un thread `isOutdated` se vérifie sur le code actuel avant d'être
   traité — la remarque peut être tombée toute seule.
3. **Pour chaque thread, une position** : corrigé, corrigé autrement, ou assumé.
   « Assumé » est une réponse légitime et fréquente — un choix volontaire se
   défend, il ne se plie pas par politesse.
4. **Appliquer les corrections** dans le code, groupées par intention, puis
   **rejouer les étapes du script de recettage que ces corrections touchent**.
   Une correction faite pour satisfaire un relecteur peut casser ce qu'un autre
   a validé, et personne ne le rejouera après.
5. **Présenter le tableau** : un thread par ligne, la position, et la réponse
   proposée en une ou deux phrases.

Après arbitrage : committer (`slash-commit`), pousser, puis poster les réponses
retenues et résoudre les threads traités. Un thread dont la réponse n'a pas été
retenue reste ouvert — et on dit lesquels.

Les réponses partent **sous le nom de l'utilisateur**, sans préfixe ni signature
d'agent : il les a arbitrées, elles sont de lui.

## La capitalisation

Une remarque qu'un humain a attrapée et qu'un script aurait dû attraper est le
seul signal qui ait valeur de preuve pour faire évoluer les guidelines. Verser
ces cas — et rien d'autre — dans `.claude/review-patterns/<slug-branche>.md`, au
format que `slash-process-review-patterns` consomme. Le fichier part avec la
branche, dans les commits de la PR.

Si rien n'est généralisable, ne pas créer le fichier : un pattern creux coûte
plus cher que pas de pattern.
