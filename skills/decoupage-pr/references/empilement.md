# Mécanique des PR empilées

À lire quand l'empilement est retenu — pas pour arbitrer, l'arbitrage est dans
`SKILL.md`. `$BASE` est la branche de base déduite du remote, comme là-bas :
`develop` sur slash-interim, `main` sur slash-web.

## Découper une branche déjà implémentée

Si les commits ont été découpés par intention (mode découpage de `slash-commit`),
la frontière existe déjà : un groupe de commits = une PR. Relever les SHA une
fois pour toutes, la suite les consomme :

```bash
git log "$BASE"..HEAD --oneline --reverse
```

Puis construire les branches **dans l'ordre de la pile**, chacune sur la
précédente :

```bash
git checkout -b sli-1234-1-extraire-helper "$BASE"
git cherry-pick <sha-1>

git checkout -b sli-1234-2-corriger-arrondi sli-1234-1-extraire-helper
git cherry-pick <sha-2>
```

En parallèle, c'est le même geste avec `$BASE` comme point de départ partout.

**Ne pas supprimer la branche d'origine** avant que les PR soient ouvertes et
vertes : c'est le seul endroit où le travail existe en entier.

## Ouvrir les PR

Une PR par branche, dans l'ordre, chacune sur la précédente :

```bash
git push -u origin sli-1234-1-extraire-helper
gh pr create --base "$BASE" --head sli-1234-1-extraire-helper --draft \
  --assignee @me --title "..." --body-file <fichier>

git push -u origin sli-1234-2-corriger-arrondi
gh pr create --base sli-1234-1-extraire-helper --head sli-1234-2-corriger-arrondi \
  --draft --assignee @me --title "..." --body-file <fichier>
```

Le `--base` de la seconde est **la branche de la première**, pas `$BASE`. C'est
ce qui garde le diff propre : GitHub n'affiche que ce que la PR n°2 ajoute.

Vérifier après coup, parce qu'une base fausse ne se voit pas dans le diff quand
la pile est encore courte :

```bash
gh pr list --json number,title,baseRefName,headRefName
```

## Après la fusion d'une PR amont

`slash-interim` supprime la branche à la fusion, donc **GitHub retargete
automatiquement** la PR suivante sur `$BASE`. C'est fait, il n'y a rien à cliquer.

Ce qui n'est pas fait, c'est le diff. Deux cas, et seule la stratégie de fusion
retenue les distingue — les deux sont autorisées sur le dépôt :

- **merge commit** : les commits de la PR n°1 sont devenus des ancêtres de
  `$BASE`, le diff de la n°2 se nettoie tout seul. Rien à faire ;
- **squash** : le squash a créé un commit **neuf**, différent des commits
  cherry-pickés. Les changements de la n°1 réapparaissent dans le diff de la
  n°2, en double, et le reviewer voit soudain 400 lignes qu'il a déjà
  approuvées. Il faut rebaser :

```bash
git checkout sli-1234-2-corriger-arrondi
git fetch origin
git rebase --onto "origin/$BASE" <sha-du-dernier-commit-de-la-PR-1>
git push --force-with-lease
```

`--onto` plutôt qu'un `rebase origin/$BASE` simple : il jette explicitement les
commits déjà fusionnés au lieu de demander à git de les rejouer et de produire
des conflits sur du code déjà à jour.

`--force-with-lease`, jamais `--force` : si quelqu'un a poussé sur la branche
entre-temps, la commande refuse au lieu d'écraser.

## Pièges vérifiés

**Le force-push efface le fil des commentaires ancrés.** Les commentaires de
review attachés à une ligne d'un commit réécrit deviennent *outdated* et se
replient. Prévenir avant de rebaser une PR déjà relue, ou attendre que la review
soit traitée.

**La CI d'une PR empilée teste la pile, pas la PR.** Elle passe parce que le code
de la n°1 est là. Un vert sur la n°2 ne dit rien de ce qui se passerait si elle
partait seule sur `$BASE` — ce qui est normal, c'est le principe même de
l'empilement, mais ça interdit de merger dans un autre ordre.

**Une pile de plus de trois PR ne se tient pas.** Chaque merge amont impose un
rebase à toutes les suivantes. Au-delà de trois, le coût d'intendance dépasse le
gain de relecture : mieux vaut une PR plus grosse assumée, ou un découpage du
ticket lui-même côté Linear.

**Sortir de draft dans l'ordre.** Une PR n°2 en *ready for review* alors que la
n°1 n'est pas relue envoie le reviewer dans un diff qui va changer sous ses
pieds.
