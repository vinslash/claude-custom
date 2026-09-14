# Installer chez soi

Le geste d'installation est dans le [README](../README.md). Ce fichier porte le
reste : ce que l'installateur fait d'une configuration déjà en place, comment la
mise à jour automatique se vérifie, et comment revenir en arrière.

## Prérequis

| Il faut | Parce que |
| --- | --- |
| **macOS** | La mise à jour automatique est un agent launchd, et `bin/chrome-mcp.sh` cherche Chrome dans `/Applications`. Ailleurs, l'installation se termine mais rien ne se met plus à jour tout seul. |
| `git`, `python3` | `install.sh` lit `settings.json` en Python, et le hook `session-start.sh` s'en sert à chaque ouverture de session. Sur macOS, `python3` arrive avec les outils en ligne de commande Xcode. |
| La CLI `claude` | L'installateur s'en sert pour valider le manifeste et afficher le coût en tokens du plugin. |
| Un accès **SSH en lecture** à `vinslash/claude-custom` | Le clone installé tire ses mises à jour depuis GitHub. Sans accès, l'installation se termine avec un avertissement et la configuration reste figée à son état du jour. |
| Google Chrome | Seulement pour le serveur MCP `chrome` et les skills qui en dépendent. Le reste marche sans. |

`rtk` est **facultatif**. `RTK.md` est importé dans toutes les sessions et décrit
un proxy CLI qui économise des tokens ; sans le binaire, ces instructions restent
sans effet et rien ne casse.

## Ce que fait `install.sh`

Idempotent, relançable sans risque, et il ne supprime jamais un fichier sans
l'avoir sauvegardé à côté sous `.bak-<horodatage>`.

| Ce qu'il rencontre | Ce qu'il en fait |
| --- | --- |
| `~/.claude/skills/slash` absent | Clone ce dépôt-ci, puis fait pointer l'origine du clone sur GitHub — c'est de là que viendront les mises à jour. |
| `~/.claude/skills/slash` déjà un clone | Le garde, remet son origine et sa branche suivie. |
| `~/.claude/skills/slash` autre chose | **S'arrête sans rien toucher.** À vous de trancher. |
| `~/.claude/CLAUDE.md` existant | Sauvegarde, puis réécrit le fichier avec la ligne d'import **au-dessus** du contenu existant, qui est conservé intégralement. |
| `~/.claude/CLAUDE.md` lien symbolique | Le remplace par le fichier d'une ligne — voir [`montage.md`](montage.md), qui dit pourquoi ce ne doit pas être un lien. |
| `~/.claude/RTK.md` | N'est plus lu par personne une fois l'import en place : versé dans le dépôt s'il n'y est pas, retiré s'il est identique, sauvegardé et retiré s'il diffère — avec proposition d'en verser le contenu dans le dépôt. |
| Anciens liens `~/.claude/skills/slash-*` | Retire **seulement** ceux qui pointent vers ce dépôt. Les autres sont laissés, avec un avertissement. |
| `~/.claude/settings.json` | Ajoute une seule clé : `disabledMcpjsonServers: ["chrome-devtools"]` — voir [`../settings.snippet.json`](../settings.snippet.json). Ne sauvegarde que s'il modifie vraiment. |
| L'agent launchd | Écrit `~/Library/LaunchAgents/com.slash.claude-custom.maj.plist` et le charge. |

Il finit par des vérifications : manifeste de plugin valide, import en place,
chaque référence `@` de `CLAUDE.md` qui résout pour de vrai, mise à jour
opérationnelle, agent actif, et l'inventaire des composants avec leur coût.

Rien à déclarer côté marketplace : un dossier de `~/.claude/skills/` qui contient
un `.claude-plugin/plugin.json` est chargé comme plugin complet — skills, hooks,
serveur MCP.

## Ce qu'il ne touche pas

Vos skills personnels dans `~/.claude/skills/`, vos hooks et le reste de
`settings.json`, vos autres plugins, vos `CLAUDE.md` de projet, `settings.local.json`,
et le contenu de votre `~/.claude/CLAUDE.md`, qui reste sous l'import.

Les instructions du dépôt et les vôtres cohabitent donc dans la même session. En
cas de contradiction, c'est à vous de trancher : rien n'arbitre à votre place.

## La mise à jour automatique

L'agent launchd lance `~/.claude/skills/slash/bin/mise-a-jour.sh` toutes les
**120 secondes**, hors de Claude Code — donc sans session ouverte et sans rien
facturer. Le script fait un `git pull --ff-only` sur le clone installé, et
n'écrit dans `.git/` que s'il y a vraiment du neuf.

Une session ouverte n'a rien à faire : le hook `FileChanged` part seul quand les
fichiers bougent sur disque, dit ce qui a changé, et les instructions permanentes
sont réinjectées au message suivant. Seuls `hooks.json` et `.mcp.json` demandent
un geste — voir [`propagation.md`](propagation.md).

**Le clone installé ne doit jamais être édité.** Un seul fichier modifié dedans
et le `merge --ff-only` échoue : les mises à jour s'arrêtent. C'est la seule
panne du montage qu'on ne verrait pas venir, d'où la notification macOS
« Config slash — mise à jour bloquée », posée au plus une fois par heure.

Pour développer, on écrit dans le dépôt de développement et on pousse ; le clone
suit. Pour éprouver un commit non poussé, `/slash:force-update` sait tirer depuis le dépôt
de développement.

## Vérifier

```bash
launchctl print gui/$(id -u)/com.slash.claude-custom.maj | head -5   # agent chargé
bash ~/.claude/skills/slash/bin/mise-a-jour.sh                        # « déjà à jour (abc1234) »
git -C ~/.claude/skills/slash status --short                          # doit être VIDE
claude plugin details slash@skills-dir                                # les skills et leur coût
```

Puis ouvrir une nouvelle session et taper `/slash:` — les skills doivent
apparaître. Le journal des mises à jour vit dans
`~/.claude/slash-etat/mise-a-jour.log`, et n'est écrit qu'aux anomalies et aux
mises à jour effectives ; les erreurs de launchd lui-même vont dans
`~/.claude/slash-etat/launchd-erreurs.log`.

## Une fois pour toutes : le profil Chrome modèle

Seulement pour qui se servira du navigateur — captures d'écran sur une PR,
constat dans l'application.

```bash
bash ~/.claude/skills/slash/bin/chrome-modele.sh
```

Chrome s'ouvre sur le profil dont chaque profil de worktree sera cloné. Y faire
**deux** choses : installer Dashlane et s'y connecter, **et** se connecter à
GitHub. Puis fermer la fenêtre. Sans ça, chaque première pose de capture
s'arrêtera sur une connexion GitHub à faire à la main.

C'est le seul lancement de Chrome à la main qui soit permis : partout ailleurs,
le navigateur est fourni par le serveur MCP `chrome`.

## Quand ça coince

| Symptôme | Ce que c'est | Le geste |
| --- | --- | --- |
| Notification « mise à jour bloquée », ou `clone sali` | Un fichier a été édité dans le clone installé | `git -C ~/.claude/skills/slash status --short` pour voir quoi. Si c'est à jeter : `git -C ~/.claude/skills/slash checkout -- .`. Sinon, le reporter dans le dépôt de développement d'abord. |
| Un skill modifié n'a aucun effet | `hooks.json` ou `.mcp.json` a bougé : le câblage vit dans la mémoire du process | `/reload-plugins` dans le terminal ; dans l'extension VSCode, qui n'expose pas la commande, ouvrir une **nouvelle session**. |
| `/reload-plugins` répond « isn't available in this environment » | Vous êtes dans l'extension VSCode | Nouvelle session. |
| Rien du dépôt n'est chargé, sans erreur | Un import `@` qui ne résout pas échoue **en silence** | Relancer `./install.sh` : il vérifie chaque référence et nomme celles qui manquent. |
| `source injoignable` dans le journal | Pas d'accès SSH à GitHub, ou le réseau | `git -C ~/.claude/skills/slash ls-remote origin` pour voir l'erreur réelle. |
| L'agent launchd a été refusé au chargement | Politique de la machine | `launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.slash.claude-custom.maj.plist` |

## Désinstaller

```bash
launchctl bootout gui/$(id -u)/com.slash.claude-custom.maj
rm ~/Library/LaunchAgents/com.slash.claude-custom.maj.plist
rm -rf ~/.claude/skills/slash ~/.claude/slash-etat
```

Reste à retirer à la main la ligne `@~/.claude/skills/slash/CLAUDE.md` en tête de
`~/.claude/CLAUDE.md` — le contenu qui suit est le vôtre, et les sauvegardes
`~/.claude/CLAUDE.md.bak-*` sont toujours là. Et, si elle vous gêne, l'entrée
`disabledMcpjsonServers` de `settings.json`.

Le dépôt de développement, lui, n'a jamais été modifié par l'installation : il
suffit de le supprimer.
