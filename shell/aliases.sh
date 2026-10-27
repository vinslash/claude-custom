# Les commandes de poste du dépôt, sous un préfixe commun : `cl-` pour Claude,
# et `cl-<Tab>` liste toute la série.
#
# Sourcé par `~/.zshrc` depuis le CLONE installé, jamais depuis le dépôt de dev :
# les alias suivent donc les mises à jour sans qu'on y touche, comme la status
# line. La ligne est posée par `install.sh`. Écrit en sh portable, pour que bash
# puisse le sourcer aussi.
#
# Un alias de plus se range ici, préfixé `cl-`, avec une ligne qui dit quand
# s'en servir.

_cl_bin="${HOME}/.claude/skills/slash/bin"

# Reconnecter Dashlane et GitHub dans le profil Chrome modèle, puis dans tous les
# worktrees. Tous les 14 jours, ou quand le début de session le demande.
alias cl-chrome="bash '${_cl_bin}/chrome-template.sh'"

# Rattraper les worktrees que `cl-chrome` a sautés parce que leur Chrome tournait.
alias cl-propagate="bash '${_cl_bin}/chrome-propagate.sh'"

# Tirer le clone installé sans attendre launchd ; `cl-update --from-dev` pour
# éprouver un commit pas encore poussé.
alias cl-update="bash '${_cl_bin}/update.sh'"

# Reposer le montage : après un renommage de script, sur une machine neuve, ou
# quand `/slash:` ne répond plus. Lancé depuis le dépôt de DEV, pas depuis le
# clone : `install.sh` écrit dans son propre dossier (RTK.md versé, sauvegardes
# récupérées), et une seule écriture dans le clone gèlerait les mises à jour.
alias cl-install="bash '${HOME}/Development/claude-custom/install.sh'"
