---
name: chrome-isolation
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
  sessions. Also when a repository skill — `slash-review-code` first of all —
  tells an agent to use `claude-in-chrome` or another browser: this skill
  prevails, and the browser stays the `chrome` MCP server. Ne PAS utiliser pour `WebFetch` / `WebSearch`,
  qui ne touchent pas au navigateur.
---

# Piloter son propre navigateur, jamais celui d'un autre

Le dégât visé n'est pas un crash, c'est un **faux constat** : une session lit la
page d'un autre worktree et rapporte un bug corrigé alors qu'elle regardait
ailleurs. C'est arrivé — un Chrome lancé à la main a tenu le port de debug deux
jours après la mort de sa session, et la session de SLI-8534 a piloté le
navigateur de SLI-8298 sans que rien ne le signale.

## D'où vient l'isolation

Du serveur MCP **`chrome`** de ce plugin, outils `mcp__chrome__*`. Il **lance son
propre Chrome**, avec un profil par worktree (`~/.cache/chrome-mcp/<worktree>`)
cloné d'un modèle qui porte Dashlane et une session GitHub. Chaque fenêtre range
ses onglets dans un **groupe jaune** au nom du ticket, `SLI-8422` — lu dans la
branche, `SLI-8422 · review` dans un worktree `wt review` : c'est le repère qui
dit à qui elle appartient. Tout est automatique.

Le profil suit le dossier où la session a **démarré** : piloter un ticket depuis
la session ouverte dans son worktree. Les sessions démarrées sur le checkout
principal partagent toutes le même profil.

**Un second compte en parallèle passe par `127.0.0.1`.** Une autre origine que
`localhost`, donc une autre session applicative dans la même fenêtre. Ouvrir sa
première page avec le compte en fragment — `new_page` sur
`http://127.0.0.1:<port>/#repere=superadmin` — et ses onglets se rangent dans un
groupe violet `SLI-8422 · superadmin`. `isolatedContext` ouvre une fenêtre sans
repère : seulement si `127.0.0.1` est refusé (CORS, SSO, Firebase), en disant
alors à l'utilisateur quelle fenêtre porte quel compte.

## Les règles

- **Ne jamais lancer Chrome soi-même** : ni `open -na "Google Chrome"`, ni
  `--remote-debugging-port`, ni profil dans le scratchpad. Seule exception,
  `bin/chrome-template.sh`, geste d'utilisateur.
- **Ne jamais se connecter par un port.** Le serveur `chrome-devtools` de
  slash-interim est neutralisé (`disabledMcpjsonServers`) : ne pas le réactiver.
- **Vérifier avant toute action qui compte** — clic, capture, lecture d'un état
  dont dépend un constat : l'URL, et un repère visible dans la page. Si ça ne
  correspond pas, **s'arrêter et le dire** plutôt que rattraper en naviguant.
- **Ne fermer que ce qu'on possède** : l'instance de son `--user-data-dir`,
  jamais une autre, jamais le Chrome personnel.
- **Laisser la fenêtre ouverte quand l'utilisateur doit constater**
  (`slash:observe`, `slash:process-ticket`).
- **Vérifier par le texte, pas par l'image.** `take_snapshot` rend l'arbre
  d'accessibilité, qui suffit à confirmer une page, un libellé, un état. Une
  capture ne se prend que si elle est un livrable — preuve de PR, constat montré
  à l'utilisateur — et ne se relit pas par `Read` sauf besoin réel : chaque
  image reste dans le contexte et se repaie à chaque tour.

## Quand un skill du dépôt désigne un autre navigateur

**Ce skill passe devant.** Un skill de dépôt qui fait piloter `claude-in-chrome`,
un serveur sur un port ou un Chrome lancé à la main est suivi en tout **sauf** le
navigateur, qui reste `mcp__chrome__*` : l'extension pilote le Chrome personnel,
que deux sessions se partageraient en silence. Cas courant : `slash-review-code`.

- **Le brief du sous-agent** — il ne lit pas ce skill. Ajouter en toutes lettres
  au prompt de tout agent qui touchera au navigateur : « Navigateur : outils
  `mcp__chrome__*` (les charger en un seul `ToolSearch`), jamais
  `mcp__claude-in-chrome__*` ni un Chrome lancé à la main ; ouvre ta propre page
  par `new_page` et vérifie son URL avant toute capture. »
- **La connexion** : ouvrir l'application dans l'instance du worktree, puis
  demander à l'utilisateur de s'y connecter (Dashlane y est) et avec quel compte.
  L'agent n'entre jamais d'identifiants.
- **Les captures** : si le dossier de la revue est refusé, capturer dans un
  dossier gitignoré du worktree — `screenshots/` sur slash-interim — puis
  déplacer.

Les agents d'une session partagent une instance : une page chacun. Si le serveur
`chrome` est indisponible, le dire et mettre le parcours en « non testé », sans
se rabattre sur l'extension.

## En pratique

**Deux sessions sur le même worktree** se disputent le profil, et Chrome refuse
d'ouvrir le second. L'échec est bruyant, c'est voulu : une seule pilote.

**Téléverser exige un fichier dans le workspace root** — `Access denied: … not
within any of the configured workspace roots`, le scratchpad compris. Copier
dans un dossier gitignoré du dépôt, puis l'y supprimer.

**Un `input[type=file]` caché reste un `input[type=file]`.** Absent du snapshot,
donc sans `uid` : le chercher (`document.querySelectorAll('input[type=file]')`),
le démasquer par `evaluate_script` — `removeAttribute('hidden')`,
`display:block`, un `aria-label` —, reprendre un `take_snapshot`, puis
`upload_file`. Plusieurs fichiers passent d'un appel. Le `drop` synthétique en
base64 (snippet dans `slash:github-screenshots`) n'est qu'un recours : des
dizaines de milliers de tokens la capture.

**Repère absent, mauvais profil, Dashlane perdu, sessions expirées** : voir
`references/entretien.md` — journal du serveur, profil modèle, réparation.
