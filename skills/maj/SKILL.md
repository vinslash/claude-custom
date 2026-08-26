---
name: maj
description: >
  Force la mise à jour de la configuration `slash` installée
  (`~/.claude/skills/slash`) sans attendre le tick de launchd, et dit ce qui a
  changé. Sert surtout à éprouver un skill qu'on vient de committer sans avoir à
  le pousser sur GitHub, avec `--depuis-dev`. La mise à jour est normalement
  automatique : ce skill n'existe que pour ne pas attendre.
  Use when the user says « force la maj », « mets à jour la config »,
  « tire tout de suite », « teste ma modif sans pousser », or `/slash:maj`.
  Ne PAS utiliser pour installer le montage la première fois (→ `install.sh`),
  ni pour recharger le câblage du plugin (→ la commande `/reload-plugins`).
---

# Forcer la mise à jour de la configuration installée

Le dépôt installé se met à jour tout seul, toutes les deux minutes. Ce skill ne
sert qu'à ne pas attendre — après un correctif qu'on veut voir tout de suite, ou
pour éprouver une modification avant de la pousser.

## Ce qu'il faut lancer

Depuis GitHub, ce qui est le cas normal :

```bash
bash ~/.claude/skills/slash/bin/mise-a-jour.sh
```

Depuis le dépôt de développement, pour éprouver quelque chose de **committé mais
pas poussé** :

```bash
bash ~/.claude/skills/slash/bin/mise-a-jour.sh --depuis-dev
```

Il n'existe aucun raccourci pour du non-committé, et c'est volontaire : c'est
précisément le filet qui empêche un brouillon de partir dans toutes les sessions.

## Ce qu'il faut en dire

Rapporter en une ligne, pas en rapport d'exécution : ce qui a changé, ou que tout
était déjà à jour.

Deux conséquences à ne pas taire :

- si la sortie mentionne **`hooks.json` ou `.mcp.json`**, dire à l'utilisateur de
  lancer `/reload-plugins` **dans le terminal**, ou d'**ouvrir une nouvelle
  session** s'il est dans l'extension VSCode, qui n'expose pas cette commande. Le
  câblage vit dans la mémoire du process et rien ne peut le recharger à sa place ;
- si la sortie dit **`clone sali`**, ne pas tenter de forcer. Le clone installé
  n'est censé être édité par personne, et un `git checkout` d'autorité
  effacerait ce que quelqu'un y a mis. Montrer la liste et demander.

Les skills, eux, sont déjà actifs : Claude Code les recharge à chaud, sans rien
demander à personne.
