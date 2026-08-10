---
name: slash-chrome-ancrage
description: >
  Ancre les onglets Chrome pilotés par une session sur cette session, pour que
  plusieurs sessions Claude en parallèle — typiquement un worktree par ticket — ne
  se marchent pas dessus dans le même navigateur. Impose d'ouvrir son propre
  onglet plutôt que de réutiliser un onglet existant, d'en retenir l'identité, de
  vérifier la page avant chaque action qui compte, et de ne jamais fermer ni
  naviguer un onglet qu'on n'a pas ouvert soi-même.
  Use when about to open or drive Chrome — `claude-in-chrome`, ouverture d'un
  onglet, navigation, clic, capture d'écran, lecture de la console — and BEFORE
  the first browser action, not after. Also when the user says « ouvre le
  navigateur », « va voir la page », « constate dans Chrome », « prends une
  capture », or mentions plusieurs sessions en parallèle. Ne PAS utiliser pour
  `WebFetch` / `WebSearch`, qui ne touchent pas au navigateur de l'utilisateur.
---

# Ancrer les onglets Chrome sur la session

## Pourquoi ce skill existe

Un seul Chrome, un seul profil, et souvent plusieurs sessions Claude en parallèle
sur des worktrees différents. Rien n'isole les onglets les uns des autres.

Le dégât n'est pas un crash, c'est un **faux constat**. Une session navigue
l'onglet qu'une autre était en train d'observer, lit la page d'un autre worktree,
et rapporte que le bug est corrigé alors qu'elle regardait ailleurs. Une capture
prise dans le mauvais onglet est pire qu'une absence de capture : elle a l'air
d'une preuve.

## La règle

**Ouvre ton propre onglet.** La première action navigateur d'une session, c'est
l'ouverture d'un onglet neuf — jamais la réutilisation d'un onglet déjà là, même
s'il pointe déjà la bonne URL. Si l'outillage sait ouvrir une **fenêtre**, la
préférer : une fenêtre dédiée est visible d'un coup d'œil et beaucoup plus dure à
confondre qu'un onglet noyé parmi trente.

**Retiens son identité.** L'identifiant d'onglet si l'outillage en expose un,
sinon l'URL exacte attendue — le port du dev local du worktree suffit à
distinguer. L'écrire dans le scratchpad de session, qui a exactement la bonne
durée de vie : celle de la session.

**Cible explicitement.** Chaque action nomme l'onglet visé. Si l'outillage n'agit
que sur l'onglet actif, l'ancrage n'est plus une garantie mais une convention :
le dire à Vince plutôt que de le laisser croire le contraire, et lui demander de
ne pas changer d'onglet pendant la manipulation.

**Vérifie avant d'agir.** Avant toute action qui compte — un clic, une capture, la
lecture d'un état dont dépend un constat — confirmer que la page est bien celle
attendue : l'URL, et un repère visible dans la page. Si ça ne correspond pas,
**s'arrêter et le dire**. Ne pas « rattraper » en naviguant : naviguer, c'est
précisément écraser l'onglet de quelqu'un d'autre.

**Ne touche qu'à ce que tu as ouvert.** Jamais fermer, jamais naviguer un onglet
dont on n'est pas l'auteur. À la fin, laisser le sien ouvert si Vince doit
constater lui-même — c'est ce que demande `slash-process-ticket` à ses étapes 2 et
4 — sinon fermer le sien, et lui seul.

**Annonce ton ancrage.** En ouvrant l'onglet, dire en une ligne lequel est le tien
(URL et port). Quand trois sessions tournent, c'est ce qui permet à Vince de
savoir qui regarde quoi.

## Ce que ce skill ne garantit pas

Il n'isole rien. Le navigateur et son profil restent partagés : cette règle
réduit les collisions, elle ne les rend pas impossibles.

Sa solidité dépend d'un point qui reste **à vérifier** — les outils
`claude-in-chrome` ciblent-ils un onglet par identifiant, ou agissent-ils sur
l'onglet actif ? Dans le premier cas l'ancrage tient même si Vince clique
ailleurs. Dans le second, un simple changement de focus le contourne, et la seule
réponse sérieuse est la fenêtre dédiée. Cela se vérifie en regardant si les outils
prennent un paramètre d'onglet. **Quand ce sera tranché, mettre à jour ce
paragraphe** : une règle dont on ignore la portée finit par être appliquée à
l'aveugle.

L'isolation réelle passerait par un profil Chrome distinct par worktree
(`--user-data-dir`), mais elle suppose de réinstaller et re-permissionner
l'extension dans chaque profil — disproportionné tant que la règle ci-dessus
suffit.
