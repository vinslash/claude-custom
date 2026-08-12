# Services externes — ce qui est mockable et ce qui ne l'est pas

À lire quand un critère d'acceptation mentionne une synchronisation, un envoi ou
un système tiers.

## Les services externes du produit

Tempo, Firebase Auth, Brevo, Allianz (assurance), Armado (GED), DPAE URSSAF,
All My SMS, Hiresweet, Microsoft Graph, AWS SES, S3.

## La règle dure — Tempo

Tempo **n'est pas mocké**. `TEMPO_BASE_URL` a pour défaut
`https://ws-stg.slash-interim.com/api/tempo`
(`backend/src/tempo/tempo.module.ts:43`), c'est-à-dire le **Tempo de staging
partagé**. Écrire dessus depuis un worktree local est **interdit** :

- ça pollue un système partagé par toute l'équipe, de façon souvent
  irréversible (Tempo n'expose pas de DELETE sur certaines entités — c'est la
  cause d'origine de l'ADR 0004) ;
- un mock serveur Tempo est **souhaité mais n'existe pas encore**, donc il n'y a
  pas d'échappatoire technique aujourd'hui.

## Les autres

Vérifier ce que couvre le mockserver local :
`backend/mockserver/expectations.json` — Brevo, Microsoft Graph, INSEE Sirene,
SMTP et Hellowork y figurent. Ce qui est mocké est validable localement ; ce qui
ne l'est pas, non.

## Ce que le plan doit dire

Un critère qui dépend d'un externe non mocké **n'est pas validable en recette
locale**. Ne pas le contourner, ne pas le passer sous silence. Le plan doit dire,
pour ce critère :

- ce qui **est** couvert localement : mapping vérifié par test unitaire, payload
  inspecté avant envoi, valeur persistée en base ;
- ce qui **reste** à valider ailleurs : recette humaine en staging ou preprod, ou
  différé jusqu'à l'arrivée du mock.
