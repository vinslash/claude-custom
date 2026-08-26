# Exemples annotés

Paires avant/après tirées de vraies PR. À enrichir à chaque fois qu'une rédaction
se fait retoquer.

---

## PR #158 — slash-web, SLI-8493 (2026-08-07)

Correctif d'une ligne fonctionnelle : la page de détail d'une annonce n'affichait
pas la ville. Cas typique d'un **petit diff noyé sous une grosse description**.

### ❌ Avant — 420 mots

````markdown
Closes [SLI-8493](...)

## Problème

Le bloc `top-job` lisait la ville et le code postal directement dans le marqueur
géocodé du champ ACF `job_city` :

```php
$city = $job_city['markers'][0]['geocode'][0]['properties']['address']['city'] ?? '';
```

Or `slash_build_job_city_data()` ne construit ce marqueur que si le géocodage a
abouti. Sans coordonnées, aucun marqueur n'est créé et le chemin retourne une
chaîne vide — la pastille se rend alors avec l'icône seule, alors que la ville est
bien en base dans le champ `localisation` de l'annonce.

Exemple en production : https://slash-interim.com/trouver-une-mission/ats-44aa.../

## Correctif

Le bloc passe par `sla_job_location()` (`cor/themes/peexeo/inc/slalocation.php`),
le helper qui enchaîne déjà tous les replis : format Mapbox → ancien format
OpenStreetMap → libellé du marqueur → champ `localisation` brut → ville du
conseiller rattaché. Il est déjà utilisé par `search-jobs.php`,
`discover-jobs-related`, `top-advisor` et l'AJAX des profils ; la page de détail
était la seule à ne pas y passer.

Quand aucune localisation n'est disponible, la pastille affiche « Localisation non
précisée » au lieu d'une icône seule (2ᵉ critère d'acceptation).

Effet de bord voulu : le format s'aligne sur celui des conseillers, `Ville (73460)`
au lieu de `Ville ( 73460 )`.

## Recette

Vérifié en local, avant/après, sur trois cas :

| Annonce | Avant | Après |
|---|---|---|
| Nominale (marqueur géocodé présent) | `Sainte-Hélène-sur-Isère ( 73460 )` | `Sainte-Hélène-sur-Isère (73460)` |
| Marqueur absent, champ `localisation` renseigné — **le bug** | *(vide)* | `Dommartin (80440)` |
| Aucune localisation, aucune agence | *(vide)* | `Localisation non précisée` |

3ᵉ critère d'acceptation — localisation affichée identique à la source ATS,
contrôlée sur trois annonces d'agences différentes (301, 322, 242) :
`Sainte-Hélène-sur-Isère (73460)`, `Dommartin (80440)`, `Roussillon (38150)`.
Les trois correspondent.

`fr_FR.mo` recompilé avec `msgfmt` : diff des msgid limité à la seule chaîne
ajoutée, aucune traduction perdue.
````

**Ce qui cloche :**

- le **snippet PHP** est la première ligne du diff — le relecteur l'a déjà ;
- la **chaîne de replis énumérée en cinq maillons** : il suffit de dire que le
  helper couvre tous les cas, le détail est dans `slalocation.php` ;
- les **cinq fichiers appelants listés nommément** — « les autres rendus
  d'annonce l'utilisent tous » dit la même chose et se lit dix fois plus vite ;
- le **tableau de recette** occupe le tiers de la description pour prouver un
  correctif de six lignes. C'est de la preuve adressée au demandeur ; ce que le
  relecteur attend à cet endroit, c'est un mode d'emploi — par où passer et ce
  qu'il doit voir, puisque c'est lui qui recette avant de relire ;
- les **IDs d'agence 301/322/242** et les villes exactes : aucune décision du
  relecteur n'en dépend ;
- la **ligne sur `msgfmt`** : pur détail d'outillage. Que le `.mo` soit bien
  recompilé, ça se voit dans le diff ;
- les **renvois aux « 2ᵉ / 3ᵉ critère d'acceptation »** : le relecteur n'a pas le
  ticket sous les yeux et n'ira pas compter.

### ✅ Après — 120 mots de prose, plus un script de trois étapes

```markdown
Closes [SLI-8493](...)

## Le problème

La page de détail d'une annonce lisait la ville uniquement dans le marqueur
géocodé de `job_city`. Quand le géocodage échoue, il n'y a pas de marqueur : la
pastille s'affichait avec l'icône seule, alors que la ville est bien en base dans
le champ `localisation`.

[Exemple en prod](https://slash-interim.com/trouver-une-mission/ats-44aa.../)

## Le correctif

Le bloc passe désormais par `sla_job_location()`, le helper qui enchaîne déjà tous
les replis (Mapbox, ancien format OSM, champ `localisation`, ville du conseiller).
Les autres rendus d'annonce l'utilisent tous ; la page de détail était la seule à
ne pas y passer.

Et quand vraiment aucune localisation n'est disponible, la pastille affiche
« Localisation non précisée » plutôt qu'une icône orpheline.

## Recettage

Prérequis : une annonce dont le champ `localisation` est renseigné mais dont le
géocodage n'a pas abouti.

1. Ouvrir sa page de détail → la pastille affiche la ville et le code postal, au
   lieu de l'icône seule.
2. Ouvrir une annonce géocodée → affichage inchangé, au format près :
   `Ville (73460)` et non `Ville ( 73460 )`.
3. Ouvrir une annonce sans localisation ni agence rattachée → « Localisation non
   précisée ».
```

**Ce qui est conservé, et pourquoi :**

- la **cause réelle** (« quand le géocodage échoue, il n'y a pas de marqueur ») —
  c'est ce que le diff ne dit pas ;
- le **lien vers l'exemple en prod** — le relecteur peut constater en un clic ;
- l'argument **« les autres rendus l'utilisent tous »** — c'est ce qui rassure
  sur le choix d'approche, bien plus qu'une preuve de test ;
- le **script de recettage**, trois étapes avec leur attendu : le relecteur
  recette avant de relire, il faut qu'il sache par où passer. Les mêmes trois cas
  que le tableau du « avant », mais tournés vers ce qu'il doit faire plutôt que
  vers ce qu'on a fait — et sans les IDs d'agence, dont il n'a pas besoin ;
- le **changement de format**, porté par l'étape 2 plutôt qu'annoncé à part :
  c'est la seule chose de cette PR qui peut surprendre quelqu'un en prod.

Le tout tient dans un écran, sans scroll.

---

## PR #942 — slash-interim, SLI-8669 (2026-08-26)

Grosse feature backend, PR empilée. Le diff était découpé, la prose dans les
bornes, le POURQUOI solide — et la description ratait quand même, sur un seul
point : **la section de test racontait le travail de l'auteur au lieu de donner
son mode d'emploi au relecteur.**

### ❌ Avant — section « Tests »

```markdown
# 🧭 Tests

Simulation puis exécution réelle entre deux indépendants d'agences distinctes,
`--page-size 2` pour traverser plusieurs pages du curseur. En simulation aucun
port d'écriture n'est appelé ; en réel les quatre listes de la cible passent de
vide à peuplé et la source garde tous ses liens.

Deux pièges couverts par les tests : `ats_command.createdById` est un id
d'**utilisateur** et n'a aucune clé étrangère — la confusion avec l'id
d'indépendant passerait en silence ; et un échec n'interrompt pas les suivants.
```

**Ce qui cloche :**

- tout est au **passé et à la première personne** — « simulation puis exécution
  réelle », « aucun port n'est appelé ». C'est un rapport d'avancement, pas un
  script. Le relecteur, qui recette avant de relire, ne sait toujours pas quelle
  commande taper ;
- **aucun prérequis**, alors que le cas demande deux indépendants dans deux
  agences distinctes avec un portefeuille — sans ça le relecteur ne peut rien
  observer, et il abandonnera ;
- « **deux pièges couverts par les tests** » : formulé comme une preuve, alors
  que le contenu est utile. Ces deux pièges disent *où poser l'attention* — leur
  place est dans « Le correctif », pas dans une section de test ;
- le tout **existait déjà ailleurs** : le script du constat mode « après », avec
  ses attendus chiffrés, dormait dans le fichier d'observation. Il n'y avait
  qu'à le recopier.

### ✅ Après — même titre, autre destinataire

```markdown
# 🧭 Tests

Prérequis : deux indépendants dans deux agences distinctes, la source détenant
des affaires, un client, des intérimaires et des commandes ATS. Le plus rapide
est deux `POST /api/e2e/seed`, un par conseiller.

1. `yarn command transfer-independent-portfolio --from-independent <source> --to-independent <cible> --dry-run --page-size 2`
   → un rapport par nature où `scanned = transferred + skipped + failed`, un log
   par page, et **aucune** écriture en base.
2. Rejouer sans `--dry-run` → mêmes compteurs, `failed=0`.
3. Connecté en tant que la cible : « Mes affaires » et « Mes clients » passent de
   vide à peuplé, `/commandes` affiche les commandes ATS, et la fiche d'un
   intérimaire transféré s'ouvre.
4. Côté source : elle ne gère plus rien, mais conserve tous ses liens d'agence —
   rien ne lui a été retiré.
5. Relancer la commande sur le même couple → `scanned=0`, rien n'est réécrit.

À surveiller au déploiement : les commissions passées ne bougent pas
(`margin.agencyId` est figé au mois), mais les marges historiques afficheront
désormais la cible comme gestionnaire.
```

**Le déplacement qui compte :** les deux pièges sont remontés dans « Le
correctif », sous la forme « deux endroits où poser l'attention ». Même
information, mais adressée à la décision du relecteur au lieu de servir d'alibi.

**La leçon, transposable :** quand le parcours a été mené jusqu'au constat de
résolution, le script de recettage **existe déjà** — dans le fichier
d'observation. Une section « Tests » rédigée au passé est le signe qu'on ne l'a
pas rouvert.

**Le titre ne bouge pas.** Le gabarit du dépôt intitule cette section
`# 🧭 Tests` et on la laisse ainsi : le skill gouverne le contenu, pas le nom des
sections d'un template. C'est le commentaire du gabarit — « décrire comment tu as
testé la PR » — qui produit la version « avant » : il désigne le mauvais
destinataire. La section garde son titre et change de lecteur.
