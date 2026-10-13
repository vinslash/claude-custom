# Schéma de PR

Charte reprise de `slash-create-pr` (`references/pr-visual.md` du dépôt
slash-interim), pour les dépôts qui ne l'ont pas. Dans slash-interim, c'est la
version du dépôt qui fait foi si les deux divergent.

La section Schéma porte une seule image SVG : ce que la PR modifie, lisible en
dix secondes par quelqu'un qui n'a pas lu le diff. Elle ne contient rien
d'autre que l'image ; sa légende est le texte alternatif.

Jamais de Mermaid, nulle part dans la description, « Pour la review »
comprise : GitHub en calcule la mise en page, la charte ci-dessous ne s'y
applique pas. Dans slash-interim, le hook `pr-body-budget.sh` le refuse.

## Quoi montrer

Choisir la forme selon ce que la PR change, jamais un inventaire de fichiers :

| La PR change | Forme |
| --- | --- |
| un comportement | avant / après, côte à côte |
| un flux entre composants | blocs reliés par des flèches, le trajet modifié en couleur |
| un cycle de statuts | états et transitions, la transition ajoutée ou retirée en couleur |
| une règle de décision | l'arbre de décision, la branche modifiée en couleur |
| une interface | capture ou GIF à la place du SVG |

## Charte

- **Une idée par schéma.** 8 blocs au plus, une seule couleur d'accent pour
  ce que la PR change ; le reste en gris.
- **Des mots, pas de code.** Libellés de 3 mots au plus, en français, en
  vocabulaire métier : jamais un nom de classe, de fichier ou de table.
- **Lisible partout.** Fond explicite (le SVG est affiché tel quel, en thème
  clair comme sombre), `font-family="sans-serif"`, texte ≥ 13 px, largeur
  800 px au plus.
- **Autonome.** Aucune ressource externe (police, image, script) : GitHub
  l'affiche comme une image et n'en charge aucune.

## Mise en page

- **Schéma centré** : l'image dans un `<div align="center">`, lignes vides
  autour, pour que GitHub interprète le markdown qu'il contient.
- **Preuves côte à côte** : un tableau `| Avant | Après |` centré (`:---:`),
  une image par cellule. Les deux images ont la même taille, pour qu'elles
  s'alignent : même `width`, même `height`, même fond.
- **Toujours `![légende](chemin)`**, jamais `<img src>` : `gh --attach` ne
  réécrit que la syntaxe markdown, y compris dans un tableau ou un `<div>`.
- **Une capture de terminal se dessine** en SVG (fond sombre, police
  monospace) plutôt que de coller un bloc de code.

## Gabarit

Copier dans le scratchpad, adapter les blocs, vérifier le rendu avant de
joindre — un libellé qui déborde de son bloc se voit tout de suite :

```bash
"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" --headless=new \
  --user-data-dir="$(mktemp -d)" --hide-scrollbars --window-size=<largeur>,<hauteur> \
  --screenshot=<scratchpad>/schema.png "file://<scratchpad>/schema.svg"
```

Ce rendu jetable, sur un profil vide, n'est pas un navigateur piloté :
`slash:chrome-isolation` ne s'y applique pas, mais le profil temporaire est ce
qui l'empêche de s'accrocher au Chrome déjà ouvert. Lire `schema.png`, corriger, puis joindre le SVG avec
`--attach "<scratchpad>/schema.svg#<légende>"`.

```svg
<svg xmlns="http://www.w3.org/2000/svg" width="720" height="220" viewBox="0 0 720 220" font-family="sans-serif" font-size="14">
  <rect width="720" height="220" rx="12" fill="#ffffff"/>
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="8" markerHeight="8" orient="auto">
      <path d="M0,0 L10,5 L0,10 z" fill="#57606a"/>
    </marker>
  </defs>
  <text x="180" y="36" text-anchor="middle" font-weight="bold" fill="#57606a">Avant</text>
  <text x="540" y="36" text-anchor="middle" font-weight="bold" fill="#0969da">Après</text>
  <line x1="360" y1="20" x2="360" y2="200" stroke="#d0d7de" stroke-dasharray="4 4"/>

  <rect x="40" y="70" width="120" height="48" rx="8" fill="#f6f8fa" stroke="#d0d7de"/>
  <text x="100" y="99" text-anchor="middle" fill="#1f2328">Étape A</text>
  <line x1="160" y1="94" x2="198" y2="94" stroke="#57606a" stroke-width="2" marker-end="url(#arrow)"/>
  <rect x="200" y="70" width="120" height="48" rx="8" fill="#f6f8fa" stroke="#d0d7de"/>
  <text x="260" y="99" text-anchor="middle" fill="#1f2328">Étape B</text>

  <rect x="400" y="70" width="120" height="48" rx="8" fill="#f6f8fa" stroke="#d0d7de"/>
  <text x="460" y="99" text-anchor="middle" fill="#1f2328">Étape A</text>
  <line x1="520" y1="94" x2="558" y2="94" stroke="#0969da" stroke-width="2" marker-end="url(#arrow)"/>
  <rect x="560" y="70" width="120" height="48" rx="8" fill="#ddf4ff" stroke="#0969da" stroke-width="2"/>
  <text x="620" y="99" text-anchor="middle" fill="#0969da" font-weight="bold">Étape modifiée</text>

  <text x="360" y="180" text-anchor="middle" fill="#57606a" font-size="13">Une phrase au plus, si le schéma ne se suffit pas</text>
</svg>
```

Couleurs : gris `#57606a` / `#d0d7de` / `#f6f8fa`, texte `#1f2328`, accent
`#0969da` sur fond `#ddf4ff`. Pour une suppression, accent `#cf222e` sur
fond `#ffebe9`.
