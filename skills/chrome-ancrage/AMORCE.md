# Chrome : chaque session pilote sa propre instance

Avant d'ouvrir ou de piloter Chrome — première navigation, clic, capture — charge
le skill `slash:chrome-ancrage`. Plusieurs sessions tournent en parallèle : le
navigateur est fourni par le serveur MCP `chrome`, jamais lancé à la main, et on
ne touche jamais à l'instance d'une autre session.
