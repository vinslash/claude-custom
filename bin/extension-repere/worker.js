// Le lanceur génère, dans le profil du worktree, une copie de cette extension
// où `etiquette.js` porte le nom du ticket. On range alors tous les onglets de
// chaque fenêtre dans un groupe qui l'affiche — jaune, comme la marque.
//
// Grouper *tous* les onglets, et pas seulement le premier, est ce qui rend le
// repère indestructible : un groupe disparaît avec son dernier onglet, mais ici
// le suivant le recrée.

importScripts('etiquette.js');

const COULEUR = 'yellow';

async function ranger(fenetreCible) {
  if (!globalThis.ETIQUETTE) return;

  const onglets = await chrome.tabs.query(
    fenetreCible ? { windowId: fenetreCible } : {}
  );

  const parFenetre = new Map();
  for (const onglet of onglets) {
    if (onglet.groupId > 0) continue;
    if (!parFenetre.has(onglet.windowId)) parFenetre.set(onglet.windowId, []);
    parFenetre.get(onglet.windowId).push(onglet.id);
  }

  for (const [windowId, tabIds] of parFenetre) {
    // Réutiliser le groupe de la fenêtre s'il existe déjà : sans ça, chaque
    // onglet neuf fabriquerait son propre groupe et la barre se remplirait de
    // chips identiques.
    const [existant] = await chrome.tabGroups.query({ windowId, title: globalThis.ETIQUETTE });
    const groupId = await chrome.tabs.group(
      existant ? { tabIds, groupId: existant.id } : { tabIds, createProperties: { windowId } }
    );
    await chrome.tabGroups.update(groupId, {
      title: globalThis.ETIQUETTE, color: COULEUR, collapsed: false,
    });
    console.log(`repère : groupe « ${globalThis.ETIQUETTE} » (${groupId}) sur la fenêtre ${windowId}`);
  }
}

// Un échec silencieux nous rendrait le repère invisible sans rien dire. On le
// fait donc voir : un onglet dont l'URL porte l'erreur.
async function rangerOuCrier(fenetreCible) {
  try {
    await ranger(fenetreCible);
  } catch (e) {
    chrome.tabs.create({ url: 'about:blank#repere-en-erreur=' + encodeURIComponent(String(e)) });
  }
}

chrome.runtime.onInstalled.addListener(() => rangerOuCrier());
chrome.runtime.onStartup.addListener(() => rangerOuCrier());
chrome.tabs.onCreated.addListener((onglet) => rangerOuCrier(onglet.windowId));
rangerOuCrier();
