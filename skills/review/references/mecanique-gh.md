# La mécanique `gh`

À lire au moment de publier, pas avant. Les commandes supposent `OWNER`, `REPO`
et `N` connus — `gh pr view --json number,headRepositoryOwner,headRepository` les
donne, et `gh` les déduit seul du dépôt courant dans la plupart des cas.

## Lire les threads, avec leur statut

`gh pr view --json comments` ne rend que les commentaires généraux. Les
commentaires ancrés à une ligne, groupés en threads avec leur `isResolved`, ne
s'obtiennent qu'en GraphQL :

```bash
gh api graphql -f query='
  query($owner:String!,$repo:String!,$num:Int!){
    repository(owner:$owner,name:$repo){
      pullRequest(number:$num){
        reviewThreads(first:100){
          nodes{
            id isResolved isOutdated
            comments(first:50){
              nodes{ id databaseId body path line author{login} createdAt }
            }
          }
        }
      }
    }
  }' -F owner=OWNER -F repo=REPO -F num=N
```

Deux identifiants à ne pas confondre : le `id` du **thread** (une chaîne opaque
`PRRT_…`) sert à le résoudre ; le `databaseId` du **premier commentaire** sert à
y répondre.

Les commentaires généraux, hors code, viennent d'ailleurs :

```bash
gh api repos/OWNER/REPO/issues/N/comments --paginate
```

## Soumettre une review d'un bloc

Une review se rédige et se **soumet d'un seul envoi** : le corps, les remarques
ancrées aux lignes et l'état partent ensemble. Poster les remarques une par une
notifie l'auteur à chaque fois et le fait travailler sur une review incomplète.

```bash
cat > /tmp/review.json <<'JSON'
{
  "body": "Corps de la review — la reco globale, en deux ou trois phrases.",
  "event": "REQUEST_CHANGES",
  "comments": [
    { "path": "backend/src/foo/foo.use-case.ts", "line": 42,
      "body": "**Bloquant** — problème, conséquence, proposition." },
    { "path": "frontend/src/Bar.tsx", "start_line": 88, "line": 94,
      "body": "**Suggestion** — …" }
  ]
}
JSON
gh api repos/OWNER/REPO/pulls/N/reviews --input /tmp/review.json
```

`event` vaut `COMMENT`, `REQUEST_CHANGES` ou `APPROVE` — c'est la reco globale.
`line` est le numéro de ligne **dans le fichier après le diff** ; un commentaire
sur plusieurs lignes se donne avec `start_line` + `line`. Une ligne hors du diff
fait échouer tout l'envoi : vérifier sur `gh pr diff N` avant.

Sans remarque ancrée, `gh pr review` suffit :

```bash
gh pr review N --approve  --body-file /tmp/corps.md
gh pr review N --comment  --body-file /tmp/corps.md
gh pr review N --request-changes --body-file /tmp/corps.md
```

## Répondre dans un thread

```bash
gh api repos/OWNER/REPO/pulls/N/comments/DATABASE_ID/replies \
  -f body="$(cat /tmp/reponse.md)"
```

`DATABASE_ID` est celui du **premier** commentaire du thread, pas du dernier.

## Résoudre un thread

```bash
gh api graphql -f query='mutation($id:ID!){
  resolveReviewThread(input:{threadId:$id}){ thread { isResolved } }
}' -F id=THREAD_ID
```

Les résolutions d'une même passe partent **en parallèle**, dans un seul tour.

## Vérifier avant de rendre la main

Rejouer la requête `reviewThreads` et contrôler, pour chaque thread qu'on
prétend avoir traité, que `isResolved` vaut `true` et que le dernier commentaire
est bien le nôtre. Un thread traité mais non résolu reste ouvert, et l'auteur le
retraitera.

## Des images dans une review

`gh` ne sait pas téléverser d'image et GitHub n'expose pas d'API pour ça. Le
geste est porté par **`slash:github-screenshots`**, qui dépose les fichiers par le
navigateur pour n'en récolter que les URL — à insérer ensuite dans le corps ou
les remarques, qui partent toujours par `gh`.

Attention à son avertissement : les images se déposent dans la **zone de
commentaire** de la PR, jamais dans un champ de review ouvert — sinon la review
part en morceaux.
