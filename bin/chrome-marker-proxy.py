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
  - Il refait l'amorce dès que le serveur signale que le navigateur a
    redémarré, sans attendre l'appel suivant : la session qui vient d'ouvrir une
    page et passe la main à l'utilisateur n'en fera peut-être plus aucun.
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

MARKER_DIR = sys.argv[1]
COMMAND = sys.argv[2:]

HIDDEN_TOOLS = {
    'install_extension', 'list_extensions', 'reload_extension',
    'uninstall_extension', 'trigger_extension_action',
}
BOOTSTRAP_ID = 'repere-amorce'
RESTART_SIGNAL = 'the browser was restarted'

server = subprocess.Popen(
    COMMAND, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
    text=True, bufsize=1,
)

bootstrapped = threading.Event()   # l'amorce initiale a eu lieu
answered = threading.Event()   # notre propre appel a reçu sa réponse
lock = threading.Lock()
# Les deux fils écrivent au serveur depuis que la réamorce part du fil de
# lecture : deux lignes entrelacées casseraient le JSON-RPC.
write_lock = threading.Lock()


def vers_client(message):
    sys.stdout.write(json.dumps(message) + '\n')
    sys.stdout.flush()


def vers_serveur(message):
    ecrire_serveur(json.dumps(message) + '\n')


def ecrire_serveur(line):
    with write_lock:
        server.stdin.write(line)
        server.stdin.flush()


def demande_amorce():
    vers_serveur({
        'jsonrpc': '2.0', 'id': BOOTSTRAP_ID, 'method': 'tools/call',
        'params': {'name': 'install_extension', 'arguments': {'path': MARKER_DIR}},
    })


def signaler_echec(message):
    """Un repère absent ne se voit pas : l'échec doit au moins laisser une trace."""
    result = message.get('result') or {}
    if 'error' in message or result.get('isError'):
        print('repère : install_extension a échoué (%s)'
              % json.dumps(message.get('error') or result.get('content')),
              file=sys.stderr)


def lire_serveur():
    """Remonte les réponses au client, sauf les nôtres."""
    for line in server.stdout:
        try:
            message = json.loads(line)
        except Exception:
            sys.stdout.write(line)
            sys.stdout.flush()
            continue

        if message.get('id') == BOOTSTRAP_ID:
            signaler_echec(message)
            answered.set()
            continue

        # Le serveur prévient lui-même quand le navigateur a redémarré ; c'est
        # notre seul indice qu'il faut reposer l'extension. La demande part
        # avant la réponse qui porte l'avis, pour passer devant tout appel que
        # la session enverrait ensuite. Sans attente : sa réponse arrive par ce
        # fil-ci, qui l'avalera au tour suivant. Une fois posée, l'extension
        # range aussi l'onglet que l'appel de relance vient d'ouvrir.
        if RESTART_SIGNAL in json.dumps(message.get('result', {})):
            try:
                demande_amorce()
            except Exception as erreur:
                print('repère : réamorce impossible (%s)' % erreur, file=sys.stderr)

        result = message.get('result')
        if isinstance(result, dict) and isinstance(result.get('tools'), list):
            result['tools'] = [
                tool for tool in result['tools']
                if tool.get('name') not in HIDDEN_TOOLS
            ]

        vers_client(message)

    sys.exit(server.wait())


def amorcer():
    answered.clear()
    demande_amorce()
    # Ne jamais bloquer indéfiniment : sans repère la session travaille quand
    # même, sans navigateur elle ne fait plus rien.
    answered.wait(timeout=60)
    bootstrapped.set()


threading.Thread(target=lire_serveur, daemon=True).start()

for line in sys.stdin:
    try:
        message = json.loads(line)
    except Exception:
        ecrire_serveur(line)
        continue

    if message.get('method') == 'tools/call' and not bootstrapped.is_set():
        with lock:
            if not bootstrapped.is_set():
                try:
                    amorcer()
                except Exception as erreur:
                    print('repère : amorce impossible (%s)' % erreur, file=sys.stderr)
                    bootstrapped.set()

    vers_serveur(message)

server.terminate()
