#!/usr/bin/env python3
"""Pose le repère de worktree sans que la session ait à y penser.

Le repère est un groupe d'onglets nommé d'après le ticket, et seule une
extension sait en créer un — `chrome.tabGroups` n'existe nulle part ailleurs.
Or Chrome 142 a retiré `--load-extension`, et une extension posée par le CDP
**ne survit pas au navigateur** : vérifié, le deuxième lancement sur le même
profil n'en garde aucune trace. Il faut donc la reposer à chaque fois.

D'où ce relais, glissé entre Claude Code et `chrome-devtools-mcp` : il laisse
passer tout le trafic MCP sans y toucher, sauf trois gestes.

  - Au premier appel d'outil de la session — donc au moment où le navigateur
    s'ouvre vraiment, jamais avant —, il intercale son propre
    `install_extension` puis relaie l'appel d'origine.
  - Il refait l'amorce si le serveur signale que le navigateur a redémarré.
  - Il retire les outils d'extension de `tools/list`, pour que la session voie
    exactement la panoplie d'avant : ces cinq-là ne la regardent pas, et
    chacun coûterait du contexte à chaque session.

En cas de pépin, on relaie sans rien faire : mieux vaut un navigateur anonyme
qu'un navigateur cassé.
"""

import json
import subprocess
import sys
import threading

ATELIER = sys.argv[1]
COMMANDE = sys.argv[2:]

OUTILS_CACHES = {
    'install_extension', 'list_extensions', 'reload_extension',
    'uninstall_extension', 'trigger_extension_action',
}
ID_AMORCE = 'repere-amorce'
SIGNAL_REDEMARRAGE = 'the browser was restarted'

serveur = subprocess.Popen(
    COMMANDE, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
    text=True, bufsize=1,
)

amorcee = threading.Event()   # l'extension est posée sur le navigateur courant
repondu = threading.Event()   # notre propre appel a reçu sa réponse
verrou = threading.Lock()


def vers_client(message):
    sys.stdout.write(json.dumps(message) + '\n')
    sys.stdout.flush()


def vers_serveur(message):
    serveur.stdin.write(json.dumps(message) + '\n')
    serveur.stdin.flush()


def lire_serveur():
    """Remonte les réponses au client, sauf les nôtres."""
    for ligne in serveur.stdout:
        try:
            message = json.loads(ligne)
        except Exception:
            sys.stdout.write(ligne)
            sys.stdout.flush()
            continue

        if message.get('id') == ID_AMORCE:
            repondu.set()
            continue

        # Le serveur prévient lui-même quand le navigateur a redémarré ; c'est
        # notre seul indice qu'il faut reposer l'extension.
        if SIGNAL_REDEMARRAGE in json.dumps(message.get('result', {})):
            amorcee.clear()

        resultat = message.get('result')
        if isinstance(resultat, dict) and isinstance(resultat.get('tools'), list):
            resultat['tools'] = [
                outil for outil in resultat['tools']
                if outil.get('name') not in OUTILS_CACHES
            ]

        vers_client(message)

    sys.exit(serveur.wait())


def amorcer():
    repondu.clear()
    vers_serveur({
        'jsonrpc': '2.0', 'id': ID_AMORCE, 'method': 'tools/call',
        'params': {'name': 'install_extension', 'arguments': {'path': ATELIER}},
    })
    # Ne jamais bloquer indéfiniment : sans repère la session travaille quand
    # même, sans navigateur elle ne fait plus rien.
    repondu.wait(timeout=60)
    amorcee.set()


threading.Thread(target=lire_serveur, daemon=True).start()

for ligne in sys.stdin:
    try:
        message = json.loads(ligne)
    except Exception:
        serveur.stdin.write(ligne)
        serveur.stdin.flush()
        continue

    if message.get('method') == 'tools/call' and not amorcee.is_set():
        with verrou:
            if not amorcee.is_set():
                try:
                    amorcer()
                except Exception as erreur:
                    print('repère : amorce impossible (%s)' % erreur, file=sys.stderr)
                    amorcee.set()

    vers_serveur(message)

serveur.terminate()
