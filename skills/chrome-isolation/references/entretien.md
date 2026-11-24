# Entretien des profils Chrome

Ce qui ne sert qu'à diagnostiquer ou réparer : le profil modèle, l'échéance des
sessions, un repère absent, un profil à refaire. Une session qui se contente de
piloter le navigateur n'a pas besoin de lire ceci.

## Le profil modèle et sa descendance

Le serveur `chrome` (`bin/chrome-mcp.sh`) lance son propre Chrome sur
`~/.cache/chrome-mcp/<nom-du-worktree>`. Le nom est celui du dossier où la
session a **démarré** (racine git, sinon le dossier courant) — d'où la règle de
piloter un ticket depuis la session ouverte dans son worktree.

Un profil qui n'existe pas encore est **cloné depuis `_modele`** au premier appel
d'outil (`bin/chrome-profile-seed.sh`, appelé par le relais). Pas au démarrage
du serveur : chaque `claude` lancé ailleurs — scratchpad, dossier temporaire —
aurait semé un profil qu'aucun navigateur n'ouvrirait. C'est du modèle que
viennent les extensions, Dashlane au premier chef, et les sessions Dashlane et
GitHub déjà ouvertes.

Le clonage n'a lieu qu'à la **naissance** du profil. Une extension installée dans
le modèle aujourd'hui n'apparaît pas dans un worktree ouvert hier : pour qu'un
ticket en cours reparte du modèle, supprimer son dossier, au prix de sa session
applicative. Les sessions Dashlane et GitHub font exception, voir plus bas.

Le modèle doit être **fermé** pendant un clonage : sa session Dashlane vit dans
une base leveldb, et copiée pendant que Chrome écrit dedans, elle arrive
incohérente — un Dashlane déconnecté sans rien pour le relier à la cause. Le jour
où l'on ouvre le modèle, ne pas ouvrir de worktree neuf en même temps.

## Échéance des sessions : 14 jours

GitHub et Dashlane expirent au bout de 14 jours, et le modèle ne les prolonge pas
puisque personne ne l'ouvre. Le geste est `bin/chrome-template.sh` — `cl-chrome`
dans le terminal de l'utilisateur : il rafraîchit le modèle, puis
`bin/chrome-propagate.sh` recopie dans **tous** les profils déjà nés le stockage
de l'extension Dashlane et les cookies `github.com`, rien d'autre — la session
applicative du ticket reste intacte. Un profil dont le Chrome tournait pendant
le passage est sauté et nommé ; relancer `chrome-propagate.sh` seul, sa session
fermée, le rattrape. Le début de session prévient quand l'échéance approche.

Le contrôle tient en une commande :

```bash
sqlite3 "file:$HOME/.cache/chrome-mcp/_modele/Default/Cookies?immutable=1" \
  "select datetime(expires_utc/1000000 - 11644473600, 'unixepoch') from cookies
   where host_key = 'github.com' and name = 'user_session';"
```

Une date à venir : bon. Une date passée : modèle à rafraîchir. Rien : la
connexion n'a pas été enregistrée — Chrome écrit ses cookies à la fermeture,
donc fermer le modèle avant de vérifier.

`chrome-template.sh` exige que le Chrome personnel soit **entièrement quitté**
(Cmd+Q) : sur macOS, lancer le binaire quand il tourne déjà fait main basse sur
lui, `--user-data-dir` est ignoré, et les identifiants partent dans le profil
personnel sans que rien ne le dise. Les Chrome des sessions Claude, eux, ne
gênent pas.

## Repère absent ou profil mal pris : le journal

Chaque serveur écrit dans `~/Library/Logs/chrome-mcp/<profil>.log` : au
démarrage le dossier, le profil, l'étiquette et la version du serveur ; puis
l'amorçage du profil, la pose du repère, ses échecs et les redémarrages du
navigateur. C'est la seule trace : le stderr du relais n'est conservé nulle part.

- **Pas de groupe jaune** : chercher `install_extension a échoué` ou `sans
  réponse`. Un `Access denied … workspace roots` veut dire que le client n'a pas
  déclaré le worktree en root MCP.
- **Mauvais profil** : la ligne `démarrage` dit quel dossier a servi. Une session
  ouverte sur le checkout principal partage le profil `slash-interim` avec toutes
  les autres sessions démarrées au même endroit.
- **Profil neuf, déconnecté** : `profil : profil neuf, sans modèle à cloner`, ou
  un worktree renommé — son nom a changé, donc son profil aussi.

## Réparer un profil

**Dashlane perdu.** `ls ~/.cache/chrome-mcp/<worktree>/Default/Extensions` doit
lister `fdjamakpfbbddfjaooikfcpapjohcfmg`. S'il manque, rien ne le réinstalle :
supprimer le dossier du profil pour qu'il soit recloné, en y perdant la session
applicative.

**Arrêter la session avant de supprimer, jamais l'inverse.** Tant qu'elle vit,
son serveur relance un Chrome qui recrée le dossier — vide — et ne le reclonera
pas : l'amorçage n'a lieu qu'une fois par serveur. Fermer la session, vérifier
qu'il ne reste ni `chrome-devtools-mcp` ni Chrome sur ce `--user-data-dir`,
supprimer ensuite.

**Le profil n'est pas jetable.** Il évite de se reconnecter à chaque fois. Ne
pas le supprimer par réflexe de nettoyage, et jamais `_modele`.

**Le ménage se fait seul.** Chaque profil note dans `.worktree` le chemin des
worktrees qui l'ont ouvert ; `bin/chrome-sweep.sh`, lancé en arrière-plan à
chaque démarrage de session, supprime ceux dont plus aucun chemin n'existe et
qu'aucun Chrome ne tient. Ce qu'il a fait est dans
`~/Library/Logs/chrome-mcp/_menage.log` ; `--dry-run` dit ce qu'il ferait. Un
profil sans `.worktree` n'est jamais touché.

## Divers

`list_pages` montre une section « Extension Service Workers » : le moteur du
repère et celui de Dashlane. Ce ne sont pas des pages, et leur absence ne veut
rien dire — un service worker inactif s'endort.

La version de `chrome-devtools-mcp` est épinglée dans `bin/chrome-mcp.sh`. Avant
de la monter, vérifier que la phrase « the browser was restarted » existe
toujours dans le paquet : c'est elle qui fait reposer le repère.
