// Le lanceur génère, dans le profil du worktree, une copie de cette extension
// où `label.js` porte le nom du ticket. On range alors tous les onglets de
// chaque fenêtre dans un groupe qui l'affiche — jaune, comme la marque.
//
// Grouper *tous* les onglets, et pas seulement le premier, est ce qui rend le
// repère indestructible : un groupe disparaît avec son dernier onglet, mais ici
// le suivant le recrée.

importScripts('label.js');

const COLOR = 'yellow';

async function group(targetWindow) {
  if (!globalThis.LABEL) return;

  const tabs = await chrome.tabs.query(
    targetWindow ? { windowId: targetWindow } : {}
  );

  const byWindow = new Map();
  for (const tab of tabs) {
    if (tab.groupId > 0) continue;
    if (!byWindow.has(tab.windowId)) byWindow.set(tab.windowId, []);
    byWindow.get(tab.windowId).push(tab.id);
  }

  for (const [windowId, tabIds] of byWindow) {
    // Réutiliser le groupe de la fenêtre s'il existe déjà : sans ça, chaque
    // onglet neuf fabriquerait son propre groupe et la barre se remplirait de
    // chips identiques.
    const [existing] = await chrome.tabGroups.query({ windowId, title: globalThis.LABEL });
    const groupId = await chrome.tabs.group(
      existing ? { tabIds, groupId: existing.id } : { tabIds, createProperties: { windowId } }
    );
    await chrome.tabGroups.update(groupId, {
      title: globalThis.LABEL, color: COLOR, collapsed: false,
    });
    console.log(`repère : groupe « ${globalThis.LABEL} » (${groupId}) sur la fenêtre ${windowId}`);
  }
}

// Un échec silencieux nous rendrait le repère invisible sans rien dire. On le
// fait donc voir : un onglet dont l'URL porte l'erreur.
async function groupOrShout(targetWindow) {
  try {
    await group(targetWindow);
  } catch (e) {
    chrome.tabs.create({ url: 'about:blank#repere-en-erreur=' + encodeURIComponent(String(e)) });
  }
}

chrome.runtime.onInstalled.addListener(() => groupOrShout());
chrome.runtime.onStartup.addListener(() => groupOrShout());
chrome.tabs.onCreated.addListener((tab) => groupOrShout(tab.windowId));
groupOrShout();
