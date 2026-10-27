#!/bin/sh
# Recopie les sessions Dashlane et GitHub du profil modèle dans les profils de
# worktree déjà nés.
#
# Le clonage depuis `_modele` n'a lieu qu'à la naissance d'un profil : rafraîchir
# le modèle ne servait qu'aux worktrees à venir, et la centaine de profils
# existants retombaient un à un sur un Dashlane déconnecté, à ressaisir fenêtre
# par fenêtre. Ce script greffe dans chacun la seule partie qui expire, sans
# toucher au reste — la session applicative du ticket en premier.
#
# Ce qu'il recopie, et pourquoi c'est suffisant :
#
#   - Dashlane : le stockage de son extension, `Local Extension Settings/<id>`
#     (`chrome.storage.local`, qui porte `localKey`, `authentication`,
#     `authenticationKeys`) et sa base IndexedDB. Le `localStorage` partagé n'en
#     porte que l'analytique — vérifié le 27/10/2026.
#   - GitHub : les lignes de `Cookies` dont l'hôte est `github.com` ou un
#     sous-domaine. Elles sont chiffrées par la clé « Chrome Safe Storage » du
#     trousseau, la même pour le modèle et pour les profils depuis que
#     `chrome-mcp.sh` retire `--use-mock-keychain` : elles se lisent telles quelles.
#
# Un profil dont Chrome tourne est sauté et nommé : copier une base que Chrome
# tient ouverte la laisserait incohérente. Il se rattrape en relançant le script
# une fois sa session fermée.
#
# Usage : chrome-propagate.sh [--dry-run] [profil…]
# Sans nom de profil, tous ceux de ~/.cache/chrome-mcp/.
set -eu

base_dir="${HOME}/.cache/chrome-mcp"
template="${base_dir}/_modele"
ext=fdjamakpfbbddfjaooikfcpapjohcfmg
github_hosts="host_key = 'github.com' or host_key like '%.github.com'"

dry_run=""
if [ "${1:-}" = "--dry-run" ]; then dry_run=1; shift; fi

# Le chemin des cookies dépend de la version de Chrome.
cookies_of() {
  for f in "$1/Default/Network/Cookies" "$1/Default/Cookies"; do
    [ -f "$f" ] && { echo "$f"; return; }
  done
}

# Vrai si un Chrome tient ce profil. On lit les lignes de commande plutôt que
# `SingletonLock`, qu'un Chrome tué laisse derrière lui ; et par `pgrep`, qui
# s'exclut lui-même, là où un `ps | grep` se trouverait dans sa propre liste.
in_use() {
  pgrep -f -- "--user-data-dir=$1( |\$)" >/dev/null 2>&1
}

# Remplace un dossier par la copie de celui du modèle, en passant par un voisin
# temporaire : un remplacement interrompu ne doit pas laisser un stockage à moitié
# écrit.
replace_dir() {
  src="$1" dst="$2"
  tmp="${dst}.propagate.$$"
  rm -rf "$tmp"
  mkdir -p "$(dirname "$dst")"
  cp -Rc "$src" "$tmp" 2>/dev/null || cp -R "$src" "$tmp"
  rm -f "$tmp/LOCK"
  rm -rf "$dst"
  mv "$tmp" "$dst"
}

if in_use "$template"; then
  echo "Le modèle est ouvert : le fermer (Cmd+Q) avant de propager." >&2
  exit 1
fi

[ -d "$template/Default/Local Extension Settings/$ext" ] || {
  echo "Pas de session Dashlane dans le modèle : lancer d'abord chrome-template.sh." >&2
  exit 1
}

tmpl_cookies=$(cookies_of "$template")
tmpl_schema=""
if [ -n "$tmpl_cookies" ]; then
  tmpl_schema=$(sqlite3 "file:$tmpl_cookies?immutable=1" \
    "select group_concat(name) from pragma_table_info('cookies');" 2>/dev/null || true)
fi

if [ $# -gt 0 ]; then
  profiles=""
  for name in "$@"; do profiles="$profiles ${base_dir}/${name}"; done
else
  profiles=$(find "$base_dir" -mindepth 1 -maxdepth 1 -type d ! -name _modele ! -name '*.workdir.*')
fi

done_count=0
busy=""
skipped=""

for profile in $profiles; do
  name=$(basename "$profile")
  [ -d "$profile/Default" ] || { skipped="$skipped $name(pas un profil)"; continue; }

  if in_use "$profile"; then
    busy="$busy $name"
    continue
  fi

  # Un profil qui a perdu l'extension n'a que faire de son stockage : il est à
  # supprimer pour être recloné, ce que ce script ne décide pas à sa place.
  if [ ! -d "$profile/Default/Extensions/$ext" ]; then
    skipped="$skipped $name(sans Dashlane)"
    continue
  fi

  if [ -n "$dry_run" ]; then
    done_count=$((done_count + 1))
    continue
  fi

  replace_dir "$template/Default/Local Extension Settings/$ext" \
              "$profile/Default/Local Extension Settings/$ext"
  for db in "chrome-extension_${ext}_0.indexeddb.leveldb" "chrome-extension_${ext}_0.indexeddb.blob"; do
    if [ -d "$template/Default/IndexedDB/$db" ]; then
      replace_dir "$template/Default/IndexedDB/$db" "$profile/Default/IndexedDB/$db"
    else
      rm -rf "$profile/Default/IndexedDB/$db"
    fi
  done

  # GitHub : seulement si les deux tables ont les mêmes colonnes dans le même
  # ordre, sans quoi le `select *` mélangerait les champs. Un profil né sous une
  # autre version de Chrome peut être en retard d'un schéma : on le dit et on
  # passe, Chrome le migrera à son prochain lancement.
  cookies=$(cookies_of "$profile")
  if [ -n "$tmpl_cookies" ] && [ -n "$cookies" ]; then
    schema=$(sqlite3 "$cookies" \
      "select group_concat(name) from pragma_table_info('cookies');" 2>/dev/null || true)
    if [ "$schema" = "$tmpl_schema" ]; then
      sqlite3 "$cookies" <<SQL
attach 'file:$tmpl_cookies?immutable=1' as tmpl;
begin;
delete from main.cookies where $github_hosts;
insert into main.cookies select * from tmpl.cookies where $github_hosts;
commit;
SQL
    else
      skipped="$skipped $name(cookies : schéma différent)"
    fi
  fi

  done_count=$((done_count + 1))
done

if [ -n "$dry_run" ]; then
  echo "À propager : $done_count profil(s)."
else
  echo "Sessions Dashlane et GitHub propagées dans $done_count profil(s)."
fi
if [ -n "$busy" ]; then
  echo "Sautés car ouverts — relancer ce script une fois leur session fermée :"
  for n in $busy; do echo "  $n"; done
fi
if [ -n "$skipped" ]; then
  echo "Laissés de côté :"
  for n in $skipped; do echo "  $n"; done
fi
