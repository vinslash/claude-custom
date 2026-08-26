---
name: chrome-ancrage
description: >
  Garantit qu'une session Claude pilote SON navigateur et pas celui d'une autre,
  quand plusieurs sessions tournent en parallèle sur des worktrees différents.
  L'isolation vient du serveur MCP `chrome` fourni par ce plugin, qui lance sa
  propre instance avec un profil dédié au worktree : il ne faut donc jamais
  lancer Chrome à la main, ni se connecter à un navigateur par un port de debug
  partagé. Impose aussi de vérifier la page avant toute action dont dépend un
  constat, et de ne fermer que l'instance qu'on possède.
  Use when about to open or drive Chrome — opening a page, navigating, clicking,
  taking a screenshot, reading the console — and BEFORE the first browser action,
  not after. Also when the user says « ouvre le navigateur », « va voir la page »,
  « constate dans Chrome », « prends une capture », or mentions several parallel
  sessions. Ne PAS utiliser pour `WebFetch` / `WebSearch`,
  qui ne touchent pas au navigateur.
---

# Piloter son propre navigateur, jamais celui d'un autre

## Pourquoi ce skill existe

Le dégât n'est pas un crash, c'est un **faux constat**. Une session lit la page
d'un autre worktree et rapporte que le bug est corrigé alors qu'elle regardait
ailleurs. Une capture prise dans le mauvais navigateur est pire qu'une absence de
capture : elle a l'air d'une preuve.

Ce n'est pas théorique. Un Chrome lancé à la main par une session a tenu le port
de debug pendant deux jours après la mort de cette session ; pendant ce temps,
une session travaillant sur SLI-8534 pilotait le navigateur — et le profil — de
SLI-8298, sans que rien ne le signale.

## D'où vient l'isolation

Du serveur MCP **`chrome`** déclaré par ce plugin. Il ne se connecte pas à un
navigateur existant : il **lance le sien**, avec un profil dérivé du worktree
(`~/.cache/chrome-mcp/<nom-du-worktree>`) et un viewport de 1440×820.

Le lancement passe par `bin/chrome-mcp.sh`, qui fait une chose de plus : quand le
profil du worktree n'existe pas encore, il le **clone depuis un profil modèle**,
`~/.cache/chrome-mcp/_modele`. C'est de là que viennent les extensions — Dashlane
au premier chef — et leur session déjà ouverte.

Conséquence : deux sessions sur deux worktrees ont deux navigateurs, deux
profils, deux jeux de cookies. Il n'y a plus de port partagé, donc plus de
collision possible — à condition de ne pas recréer le problème à la main.

## Les règles

**Ne jamais lancer Chrome soi-même.** Pas de `open -na "Google Chrome"`, pas de
`--remote-debugging-port`, pas de profil posé dans le scratchpad. C'est
exactement le geste qui a produit l'incident ci-dessus. Le navigateur appartient
au serveur MCP, et à lui seul.

Une seule exception, et elle est bornée : `bin/chrome-modele.sh`, qui ouvre le
profil modèle pour y installer une extension. Il n'ouvre aucun port de debug, donc
aucune session ne peut se tromper et venir piloter cette fenêtre-là. C'est un
geste d'utilisateur, pas un geste de session.

**Ne jamais se connecter par un port.** Une configuration en `--browserUrl` vise
un endpoint unique que toutes les sessions partagent. Celle que déclare le dépôt
slash-interim est neutralisée côté utilisateur (`disabledMcpjsonServers`) : ne
pas la réactiver, ne pas en improviser une autre.

**Vérifier avant toute action qui compte.** Avant un clic, une capture, la
lecture d'un état dont dépend un constat : confirmer que la page est bien celle
attendue — l'URL, et un repère visible dans la page. Si ça ne correspond pas,
**s'arrêter et le dire** plutôt que de « rattraper » en naviguant.

**Ne fermer que ce qu'on possède.** Si une instance survit à sa session, elle
s'identifie par son `--user-data-dir`. On ne tue que celle de son propre
worktree, jamais une autre, et jamais son Chrome personnel.

**Laisser la fenêtre ouverte quand l'utilisateur doit constater.** C'est ce que
demandent `slash:constat` et `slash:process-ticket` : le navigateur est là pour
qu'il manipule lui-même, pas seulement pour produire des captures.

## Ce qu'il faut savoir en pratique

**Le profil est par worktree, pas par session.** Première conséquence : la
première utilisation sur un ticket demande de se connecter à l'application, puis
la session est persistante pour ce ticket. Deuxième conséquence : deux sessions
Claude sur le **même** worktree se disputent le même profil, et Chrome refusera
d'en ouvrir un second. L'échec est bruyant — c'est voulu, il vaut mieux qu'un
partage silencieux. Dans ce cas, une seule des deux sessions pilote le navigateur.

**Le profil n'est pas jetable.** Il vit dans `~/.cache/chrome-mcp/`, il survit aux
sessions et c'est ce qui évite de se reconnecter à chaque fois. Ne pas le
supprimer par réflexe de nettoyage. Et surtout pas `_modele`, dont tous les
profils à venir descendent.

**Le clonage n'a lieu qu'à la naissance du profil.** Une extension installée dans
le modèle aujourd'hui n'apparaîtra pas dans un worktree ouvert hier. Pour qu'un
ticket en cours reparte du modèle, il faut supprimer son dossier dans
`~/.cache/chrome-mcp/` — au prix de sa session applicative.

**Le modèle doit être fermé quand un profil en est cloné.** Sa session Dashlane
vit dans une base leveldb ; copiée pendant que Chrome écrit dedans, elle arrive
incohérente dans le clone. Le symptôme serait illisible — un Dashlane déconnecté
dans un worktree sur deux, sans rien pour le relier à la cause. En pratique le
modèle n'est ouvert que le jour où l'on y installe quelque chose ; ce jour-là, ne
pas ouvrir de worktree neuf en même temps.
