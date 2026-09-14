---
name: github-screenshots
description: >
  Pose des images — captures avant/après, schéma, trace d'exécution — sur un
  écrit GitHub : description de pull request, commentaire de PR ou de ticket,
  commentaire de code review. `gh` ne sait pas uploader d'image et GitHub
  n'expose aucune API pour les pièces jointes ; le seul chemin passe par le
  navigateur du serveur MCP `chrome`, qui dépose les fichiers dans une zone de
  commentaire pour n'en récolter que les URL. Le texte, lui, reste écrit par
  `gh` dans tous les cas. Un seul point d'arrêt : la connexion GitHub, qui est
  un geste d'utilisateur.
  Use when about to publish anything on GitHub that contains an image — before
  `gh pr create`, `gh pr edit --body`, `gh pr comment`, `gh pr review`,
  `gh issue comment` — and whenever a PR description has a « Screenshots »
  section to fill. Also when the user says « mets les captures », « ajoute les
  screenshots », « illustre la PR », « colle l'image dans le commentaire »,
  « sers-toi du champ de commentaire pour les URL ».
  Ne PAS utiliser pour décider s'il faut des captures ni pour les cadrer
  (→ `slash:writing`), ni pour les prendre (→ `slash:chrome-isolation`).
---

# Poser des images sur un écrit GitHub

## Le principe qui commande tout le reste

**Le navigateur ne sert qu'à héberger les images ; `gh` écrit le texte.**

C'est ce partage qui évite toute une classe de dégâts. Un éditeur GitHub ouvert
dans le navigateur pendant qu'on pousse le même texte par `gh` finit par écraser
l'un des deux états, au hasard — et c'est le genre de perte qu'on ne remarque
qu'une fois la PR relue. Le navigateur ne soumet donc jamais rien : il dépose des
fichiers, on récolte les URL, on repart.

La règle vaut pour **toutes** les surfaces, description comme commentaire. Il n'y
a qu'un geste à retenir.

## La connexion GitHub, une fois pour toutes

Le profil d'un worktree est cloné depuis `~/.cache/chrome-mcp/_modele` à sa
**naissance**. Une session GitHub ouverte dans le modèle est donc héritée par
tous les worktrees créés ensuite — c'est déjà comme ça que Dashlane arrive.

Le bon geste, une seule fois : quitter Chrome entièrement (Cmd+Q, sinon le
script refuse de partir), lancer `bin/chrome-template.sh`, se connecter à GitHub
dans l'onglet qu'il ouvre, puis quitter par Cmd+Q — Chrome n'écrit ses cookies
qu'en sortant. Le script contrôle lui-même que la session a été enregistrée. Les worktrees déjà nés
n'en profitent pas — le clonage a eu lieu —, il faut s'y connecter une fois
chacun. C'est aussi le cas quand la session héritée a expiré.

**Une page de connexion est un point d'arrêt, pas un obstacle à contourner.**
Rendre la fenêtre et demander la connexion. Ne pas saisir d'identifiant, ne pas
piloter Dashlane, ne pas toucher à une 2FA. Une fois connecté, les dépôts
suivants dans ce worktree ne redemandent rien.

## Le geste

Charger `slash:chrome-isolation` avant la première action navigateur, comme pour
n'importe quel pilotage.

1. **Écrire le texte sans les images** et le pousser par `gh` — `pr edit
   --body-file`, `pr comment --body-file`, ce qu'il faut selon la surface. La
   section « Screenshots » existe déjà, vide.
2. **Ouvrir la page cible.** Vérifier l'URL **et le numéro de PR ou de ticket**
   avant de toucher à quoi que ce soit : un commentaire parti sur la PR d'un
   autre worktree est irrattrapable.
3. **Déposer les fichiers dans la zone de nouveau commentaire** — jamais dans un
   éditeur de description, jamais dans un champ de review ouvert. Les deux
   captures d'un avant/après partent ensemble ; le DOM réserve des surprises,
   voir ci-dessous.
4. **Récolter les URL** que GitHub vient d'insérer dans la zone.
5. **Vider la zone sans la soumettre.** Le dépôt a eu lieu, les URL vivent, le
   commentaire n'a aucune raison d'exister.
6. **Réécrire le fichier de corps avec les URL** et le repousser par `gh`.

## Déposer : les pièges, tous éprouvés

Cette section a été écrite en déroulant le geste pour de vrai — le 2026-09-11 sur
le formulaire de nouvelle issue de `vinslash/claude-custom`, puis le 2026-09-14
sur `slash-interim/slash-interim#1064`. Chaque point est un échec rencontré, pas
une précaution supposée.

Entre ces deux dates l'éditeur de GitHub avait changé, et ce fichier affirmait
une absence constatée un jour donné comme si elle valait toujours. D'où la règle
qui commande cette section : **constater le DOM avant d'agir**, ne jamais se
fier à ce qui est décrit ici comme à un état permanent.

`chrome-isolation`, chargé au premier pas du geste, porte déjà les deux
contraintes génériques du téléversement : le fichier doit être dans le workspace
root — le scratchpad est rejeté —, et l'`input[type=file]` d'un éditeur moderne
est caché, donc à chercher puis démasquer avant tout `upload_file`. Ce qui suit
n'est que leur application à GitHub.

**Quel input viser.** Le 2026-09-14 la page en exposait deux, un par éditeur :
`#fc-issue-<id>-body` pour la description, `#fc-new_comment_field` pour la zone
de nouveau commentaire. C'est le second qu'on veut, conformément au principe —
on dépose dans la zone de commentaire, jamais dans un éditeur de description.
Le démasquage tient en quatre lignes :

```js
const input = document.querySelector('#fc-new_comment_field');
input.removeAttribute('hidden');
input.style.cssText = 'display:block!important;position:fixed;top:0;left:0;z-index:99999;width:300px;height:40px';
input.setAttribute('aria-label', 'DEPOT-CAPTURES');
```

Puis `take_snapshot`, et `upload_file` sur le `uid` ainsi obtenu. **Les deux
captures d'un avant/après passent d'un seul appel**, les deux chemins dans
`filePaths`.

Ces identifiants sont datés, pas garantis : chercher, ne jamais les supposer.

**Le `drop` synthétique, en repli.** Si la recherche ne rend rien — le DOM de
GitHub a déjà changé deux fois —, voici le snippet éprouvé auquel renvoie
`chrome-isolation`, avec le fichier inliné en base64 :

```js
const bin = atob(b64);
const bytes = new Uint8Array(bin.length);
for (let i = 0; i < bin.length; i++) bytes[i] = bin.charCodeAt(i);
const file = new File([bytes], "avant.png", { type: "image/png" });

const ta = document.querySelector('textarea');   // pas de sélecteur sur le name :
const dt = new DataTransfer();                   // il est généré (`_r_d_`)
dt.items.add(file);
ta.focus();
for (const type of ["dragenter", "dragover", "drop"])
  ta.dispatchEvent(new DragEvent(type, { bubbles: true, cancelable: true, dataTransfer: dt }));
```

Une capture de 350 Ko y pèse ~470 000 caractères de contexte, deux fois sur un
avant/après. C'est un recours, pas une méthode.

**GitHub insère du HTML, pas du markdown.** La zone reçoit d'abord
`<!-- Uploading "avant.png"... -->`, puis, une fois le dépôt fini :

```html
<img width="64" height="64" alt="Image" src="https://github.com/user-attachments/assets/<uuid>" />
```

Une regex qui ne cherche que `![…](…)` récolte donc zéro URL sur un dépôt qui a
parfaitement réussi. Viser les deux formes, et boucler jusqu'à ce que
`Uploading` ait disparu de la valeur avant de lire.

En revanche la crainte qu'on avait ici ne s'est pas matérialisée : c'est un vrai
`<textarea>` et `.value` renvoie bien le contenu. Si un jour ce n'est plus le
cas, prendre un `take_snapshot` avant de conclure à un échec de dépôt — un dépôt
réussi dont on ne sait pas lire l'URL n'est pas un dépôt raté.

**Vider demande le setter natif.** Le champ est contrôlé par React : écrire
`ta.value = ""` ne suffit pas, il faut passer par le setter du prototype puis
émettre un `input`.

```js
Object.getOwnPropertyDescriptor(HTMLTextAreaElement.prototype, 'value').set.call(ta, '');
ta.dispatchEvent(new Event('input', { bubbles: true }));
```

## Selon la surface

Le geste ne change pas ; seules les étapes 1 et 6 changent de commande.

| Ce qu'on publie | Étapes 1 et 6 | Où déposer, étape 3 |
| --- | --- | --- |
| Description de PR | `gh pr edit --body-file` (ou `gh pr create --body-file` pour la première) | La zone de commentaire de cette PR |
| Commentaire de PR ou de ticket | `gh pr comment --body-file` / `gh issue comment --body-file` | La zone de commentaire de cette même page |
| Commentaire de code review, global ou sur une ligne | `gh pr review --body-file`, ou `gh api` pour un commentaire ancré à une ligne | La zone de commentaire de la PR, **pas** le champ de review |

Une review se rédige et se soumet d'un bloc : si on y dépose les images en même
temps qu'on écrit, on n'a plus de moyen de récolter les URL sans soumettre. D'où
le passage obligé par la zone de commentaire ordinaire, qu'on vide ensuite.

## Vérifier, parce que ce coup-ci le silence est possible

Une URL récoltée dans la mauvaise zone, un fichier refusé pour sa taille, un
`uuid` tronqué : tout ça produit un texte qui a l'air juste et des icônes
cassées. Le contrôle se fait avant même de repousser le corps, depuis la page
ouverte, et ne coûte rien :

```js
await new Promise(r => {
  const img = new Image();
  img.onload  = () => r({ rendu: true, w: img.naturalWidth });
  img.onerror = () => r({ rendu: false });
  img.src = url;
});
```

`naturalWidth` doit valoir la largeur réelle de la capture. Puis, une fois le
corps poussé, recharger la page et **regarder les images se rendre** — c'est le
seul contrôle qui couvre aussi le markdown qu'on vient d'écrire.

**Ce contrôle final ne se fait pas sur l'URL qu'on a écrite.** Au rendu, GitHub
réécrit les `https://github.com/user-attachments/assets/<uuid>` en URL signées
`private-user-images.githubusercontent.com`. Un contrôle qui filtre les `<img>`
sur `user-attachments` rend donc **zéro image sur un dépôt parfaitement
réussi** — exactement le faux négatif que ce skill cherche à éviter partout
ailleurs. Prendre tous les `<img>` du `.markdown-body` de la description, sans
filtrer sur la source, et regarder leur `naturalWidth` :

```js
[...document.querySelectorAll('.markdown-body img')].map(i => ({ src: i.src, w: i.naturalWidth }));
```

## Le repli humain, qui n'a jamais cessé d'exister

Si le rendu est cassé, le dire plutôt que réessayer en boucle. Les captures sont
dans le scratchpad : l'utilisateur les colle en dix secondes depuis l'interface
web, et c'est une issue acceptable.

Ce qui ne l'est pas : pousser un `![](…)` mort, et annoncer un écrit illustré
dont les images ne se rendent pas. Une capture qui a l'air d'une preuve est pire
qu'une absence de capture — c'est la règle de `slash:chrome-isolation`, elle vaut
aussi une fois l'image sur GitHub.
