# Mode 4 — Vérifier les corrections

Les invariants du `SKILL.md` s'appliquent. **Ne juger que ce que la première
passe a demandé** : c'est la règle qui commande le skill, et c'est ici qu'elle
s'applique le plus littéralement. On ne modifie toujours rien.

**Rejouer avant de juger sur pièces.** Les étapes du script de recettage visées
par les remarques bloquantes du premier tour, et elles seules : un thread peut
être répondu correctement et la correction ne pas marcher. Si les corrections ont
changé le script lui-même, c'est le nouveau qu'on déroule.

Puis reprendre les threads ouverts par nous, un par un, et leur donner un
verdict :

| Verdict | Ce qu'on en fait |
| --- | --- |
| **traité** | résoudre le thread |
| **traité autrement, et c'est recevable** | résoudre, en le disant en une phrase |
| **pas traité**, ou la réponse ne répond pas | laisser ouvert, relancer sur ce point précis |

Ce qu'on découvre en relisant et qui n'était pas demandé au premier tour ne
devient une remarque que s'il est **bloquant** — une régression, un bug sur le cas
nominal. Tout le reste est un ticket, et se dit en une ligne.

Reco globale : approuver si le rejeu passe, qu'aucun verdict n'est « pas traité »
et qu'aucun bloquant n'est apparu. Sinon, demander des changements sur les seuls
points qui restent.

## La capitalisation

Comme en mode 2 : seule une remarque qu'un humain a attrapée et qu'un script
aurait dû attraper mérite d'être versée dans
`.claude/review-patterns/<slug-branche>.md`, au format que
`slash-process-review-patterns` consomme.

Mais il n'y a pas de branche à nous ici : écrire le fichier dans le **clone
principal du dépôt**, pas dans le worktree de relecture, et le laisser non
committé — l'utilisateur le versera avec son prochain ticket. **Rien ne s'écrit
jamais sur la branche d'un collègue**, fichier de patterns compris.
