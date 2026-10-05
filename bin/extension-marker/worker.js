// Le lanceur génère, dans le profil du worktree, une copie de cette extension
// où `label.js` porte le nom du ticket. On range alors tous les onglets de
// chaque fenêtre dans un groupe qui l'affiche — jaune, comme la marque.
//
// Grouper *tous* les onglets, et pas seulement le premier, est ce qui rend le
// repère indestructible : un groupe disparaît avec son dernier onglet, mais ici
// le suivant le recrée.
//
// Un second compte connecté en parallèle vit sur une autre origine,
// `127.0.0.1` au lieu de `localhost` : le navigateur sépare le stockage par nom
// d'hôte, donc les deux sessions applicatives ne se marchent pas dessus, et
// leurs onglets restent dans le contexte que l'extension voit — ce que
// `isolatedContext` ne permet pas. Ces onglets-là vont dans un second groupe,
// violet, qui porte le nom du compte. L'agent le donne une fois, dans l'URL de
// la première page : `http://127.0.0.1:3301/#repere=superadmin`.

importScripts('label.js');

const SECOND_HOST = '127.0.0.1';
const COLORS = { main: 'yellow', second: 'purple' };
const ACCOUNT = /[#?&]repere=([^&#]+)/;

function kindOf(tab) {
  try {
    return new URL(tab.url || tab.pendingUrl || '').hostname === SECOND_HOST ? 'second' : 'main';
  } catch {
    return 'main';
  }
}

async function group(targetWindow) {
  if (!globalThis.LABEL) return;

  const tabs = await chrome.tabs.query(
    targetWindow ? { windowId: targetWindow } : {}
  );

  // Le nom du compte se lit dans les URL ouvertes plutôt que dans l'événement
  // de navigation : la première page s'est souvent chargée avant que ce worker
  // ait fini de démarrer, et l'événement est alors perdu. On le retient, parce
  // que l'application aura retiré le fragment dès sa première redirection.
  let { compte } = await chrome.storage.local.get('compte');
  for (const tab of tabs) {
    const named = kindOf(tab) === 'second' && ACCOUNT.exec(tab.url || tab.pendingUrl || '');
    if (named && decodeURIComponent(named[1]) !== compte) {
      compte = decodeURIComponent(named[1]);
      await chrome.storage.local.set({ compte });
    }
  }

  const titles = {
    main: globalThis.LABEL,
    second: `${globalThis.LABEL} · ${compte || SECOND_HOST}`,
  };

  // Nos groupes se reconnaissent à leur couleur et non à leur titre : celui du
  // second change quand l'agent nomme le compte. Les réutiliser évite qu'un
  // onglet neuf fabrique son propre groupe et remplisse la barre de chips
  // identiques.
  const groups = new Map();
  for (const windowId of new Set(tabs.map((tab) => tab.windowId))) {
    for (const kind of Object.keys(COLORS)) {
      const [existing] = await chrome.tabGroups.query({ windowId, color: COLORS[kind] });
      if (existing) groups.set(`${windowId}|${kind}`, existing);
    }
  }

  // Un onglet déjà rangé n'est déplacé que s'il a changé d'origine : passé de
  // `localhost` à `127.0.0.1`, il doit changer de groupe.
  const pending = new Map();
  for (const tab of tabs) {
    const key = `${tab.windowId}|${kindOf(tab)}`;
    if (groups.get(key)?.id === tab.groupId) continue;
    if (!pending.has(key)) pending.set(key, []);
    pending.get(key).push(tab.id);
  }

  for (const [key, tabIds] of pending) {
    const [windowId, kind] = key.split('|');
    const existing = groups.get(key);
    const groupId = await chrome.tabs.group(
      existing
        ? { tabIds, groupId: existing.id }
        : { tabIds, createProperties: { windowId: Number(windowId) } }
    );
    if (!existing) {
      await chrome.tabGroups.update(groupId, {
        title: titles[kind], color: COLORS[kind], collapsed: false,
      });
      groups.set(key, { id: groupId, title: titles[kind] });
    }
  }

  // Le titre seul, et seulement s'il a changé : rouvrir un groupe que
  // l'utilisateur a replié à chaque navigation serait une nuisance.
  for (const [key, existing] of groups) {
    const kind = key.split('|')[1];
    if (existing.title !== titles[kind]) {
      await chrome.tabGroups.update(existing.id, { title: titles[kind] });
    }
  }
  console.log(`repère : ${[...groups.keys()].join(', ')}`);
}

// Les événements arrivent en rafale — création, puis chaque changement d'URL.
// Deux passes simultanées créeraient chacune leur groupe : on les enchaîne.
let queue = Promise.resolve();
let shouted = false;

function schedule(targetWindow) {
  queue = queue
    .then(async () => {
      try {
        await group(targetWindow);
      } catch {
        // « Tabs cannot be edited right now » : un glisser d'onglet en cours.
        // Passager, d'où un second essai avant de crier.
        await new Promise((resolve) => setTimeout(resolve, 500));
        await group(targetWindow);
      }
    })
    .catch((e) => {
      // Un échec silencieux nous rendrait le repère invisible sans rien dire.
      // On le fait donc voir — une fois : l'onglet d'erreur déclenche lui-même
      // une passe, et un échec qui dure ouvrirait des onglets sans fin.
      if (shouted) return;
      shouted = true;
      chrome.tabs.create({ url: 'about:blank#repere-en-erreur=' + encodeURIComponent(String(e)) });
    });
}

chrome.runtime.onInstalled.addListener(() => schedule());
chrome.runtime.onStartup.addListener(() => schedule());
chrome.tabs.onCreated.addListener((tab) => schedule(tab.windowId));
chrome.tabs.onUpdated.addListener((tabId, info, tab) => {
  if (info.url) schedule(tab.windowId);
});
schedule();
