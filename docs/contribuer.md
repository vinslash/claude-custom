# Contribuer

## Ajouter un skill

Le créer **dans ce dépôt**, sous `skills/<nom>/SKILL.md` — jamais directement dans
`~/.claude/skills/slash/`, qui est le clone installé : le travail y serait perdu au
premier `pull`, et hors versionnement en attendant.

Il devient actif quand le clone le reçoit : commit puis push, et le tick suivant
l'apporte — dans les deux minutes, sans redémarrer aucune session. Pour l'éprouver
sans le pousser, `/slash:force-update` sait tirer depuis ce dépôt-ci.

Vérifier son coût avant de le laisser vivre :

```bash
claude plugin details slash@skills-dir
```

La colonne *always-on* est payée par **toutes** les sessions de **tous** les
projets — c'est la description du frontmatter. La colonne *on-invoke* est payée à
chaque déclenchement : au-delà de quelques milliers de tokens, sortir le détail
en `references/`, lu seulement quand la question se pose.

Ce seuil se pondère par la **fréquence de déclenchement**. `process-ticket` est à
~6 k et les assume : il ne part qu'une fois par ticket, et tout son contenu sert
dès le début du parcours — l'extraire en référence ajouterait une lecture sans
rien économiser. Un skill qui part plusieurs fois par session n'a pas cette
latitude.

L'autre levier, quand la référence ne convient pas parce que la règle doit être
lue à coup sûr : la rendre **appelable** plutôt que lisible. Un contrôle en
`scripts/` ne coûte rien en contexte, et la prose qu'il remplace n'a plus à
énumérer ce qu'il vérifie — il le dit lui-même en sortie.

## Tenir la doc à jour

Toute modification du dépôt se termine ici, en **confrontant la doc au dépôt**
plutôt qu'en la relisant seule. Les dérives ne se voient pas de l'intérieur : une
relecture a déjà trouvé un montage annoncé comme un lien unique alors qu'il en
faut deux, et cinq entrées suivies absentes de l'inventaire.

La doc est découpée, donc **chaque fait a un domicile** et un seul. Sans ça,
personne ne sait plus quel fichier possède quel fait, et un fait sans domicile ne
se met jamais à jour :

| Ce qui a changé | Le fichier à confronter | Ce qu'on vérifie |
| --- | --- | --- |
| Un skill ajouté, retiré, renommé | `README.md` | La liste des skills : une entrée par dossier de `skills/`, ni plus ni moins |
| Un fichier du montage ajouté ou déplacé | `docs/montage.md` | Aucune pièce du montage absente de l'inventaire, tous les chemins cités qui existent |
| `install.sh` ou `bin/mise-a-jour.sh` | `docs/installation.md`, et `README.md` si les commandes d'installation bougent | Les comportements décrits conformes au script, pas à l'intention |
| Un hook, `hooks.json`, `.mcp.json` | `docs/propagation.md` | Ce qui se recharge à chaud contre ce qui exige `/reload-plugins` — vérifié, jamais supposé |
| Un chiffre dans un skill : seuil, budget, volumétrie | `docs/bornes.md` | Chaque chiffre annoncé traçable jusqu'au skill qui le porte, et sa conséquence énoncée |

Un chiffre qui vit dans deux fichiers est un bug : `docs/bornes.md` est son seul
domicile, les autres y renvoient.

### Entre deux skills, le fait général vit dans le skill général

Même règle, autre axe. Quand un fait éprouvé en faisant X sert en réalité à tout
le monde, il se domicilie dans le skill **le plus général**, et le spécifique
n'en garde que son application.

Le sens du renvoi se déduit, il ne s'arbitre pas : le spécifique charge déjà le
général — `github-screenshots` impose `chrome-isolation` avant sa première action
navigateur —, donc c'est le spécifique qui renvoie. L'inverse ferait un cycle, et
priverait du fait toute session qui ne passe pas par le cas spécifique : une
session qui téléverse un CV dans l'ATS ne chargera jamais un skill dont la
description dit « sur un écrit GitHub ».

Ce que ça donne sur le téléversement : le refus des chemins hors workspace root
et l'`input[type=file]` caché à chercher puis démasquer vivent dans
`chrome-isolation` — ce sont des propriétés du serveur MCP et des éditeurs web ;
les identifiants de GitHub, la zone à viser et le snippet de repli vivent dans
`github-screenshots`.

Le coût de l'oubli est mesuré : une affirmation fausse sur l'absence
d'`input[type=file]` a vécu dans les deux fichiers, et sa correction a failli
n'en toucher qu'un.
