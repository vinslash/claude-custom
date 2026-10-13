#!/bin/bash
# Claude Code status line: model │ context bar + % │ cost (€) │ duration │ dir + git branch
if ! command -v jq >/dev/null 2>&1; then
  echo "statusline: jq not installed (brew install jq)"
  exit 0
fi

export LC_NUMERIC=C  # sinon la locale fr fait échouer printf sur "62.4"
input=$(cat)
j() { printf '%s' "$input" | jq -r "$1" 2>/dev/null; }

model=$(j '.model.display_name // .model.id // empty')
pct=$(j '.context_window.used_percentage // empty')
# tokens actuellement dans le contexte (entrée + cache) et taille de la fenêtre
ctx_tokens=$(j '.context_window.current_usage | if . then (.input_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0) else empty end')
ctx_size=$(j '.context_window.context_window_size // empty')
cost=$(j '.cost.total_cost_usd // empty')
duration_ms=$(j '.cost.total_duration_ms // empty')
dir=$(j '.workspace.current_dir // .cwd // empty')
transcript=$(j '.transcript_path // empty')

G=$'\033[32m'; Y=$'\033[33m'; R=$'\033[31m'; D=$'\033[2m'; N=$'\033[0m'
SEP=" │ "
# 66558 → 67k, 1000000 → 1M, 1940000 → 1,9M, 248600000 → 249M
human() { awk -v n="$1" 'BEGIN {
  if (n >= 1e7) s = sprintf("%.0fM", n / 1e6)
  else if (n >= 1e6) { s = sprintf("%.1fM", n / 1e6); sub(/\.0M$/, "M", s); gsub(/\./, ",", s) }
  else if (n >= 1e3) s = sprintf("%.0fk", n / 1e3)
  else s = n
  print s }'; }
parts=()

[ -n "$model" ] && parts+=("$model")

if [ -n "$pct" ]; then
  p=$(printf '%.0f' "$pct" 2>/dev/null || echo 0)
  if [ "$p" -gt 80 ]; then c=$R; elif [ "$p" -ge 50 ]; then c=$Y; else c=$G; fi
  # barre de 10 cases au pas de 5 % : une case pleine vaut 10 %, une demi-case 5 %
  steps=$(( (p + 2) / 5 )); [ "$steps" -gt 20 ] && steps=20
  full=$(( steps / 2 )); half=$(( steps % 2 ))
  bar=""
  for ((i = 0; i < 10; i++)); do
    if [ "$i" -lt "$full" ]; then bar+="█"
    elif [ "$i" -eq "$full" ] && [ "$half" -eq 1 ]; then bar+="▌"
    else bar+="░"; fi
  done
  seg="${c}${bar} ${p}%${N}"
  if [ -n "$ctx_tokens" ] && [ -n "$ctx_size" ]; then
    seg+=" ${D}$(human "$ctx_tokens")/$(human "$ctx_size")${N}"
  fi
  parts+=("$seg")
else
  parts+=("${D}░░░░░░░░░░ --${N}")
fi

if [ -n "$cost" ]; then
  # taux USD→EUR de la BCE (frankfurter.app), rafraîchi en arrière-plan une fois par jour
  rate_file="$HOME/.claude/cache/usd_eur_rate"
  if [ ! -s "$rate_file" ] || [ -n "$(find "$rate_file" -mmin +1440 2>/dev/null)" ]; then
    mkdir -p "${rate_file%/*}"
    ( r=$(curl -sL --max-time 3 'https://api.frankfurter.app/latest?from=USD&to=EUR' | jq -r '.rates.EUR // empty' 2>/dev/null)
      [ -n "$r" ] && printf '%s' "$r" > "$rate_file" ) >/dev/null 2>&1 &
  fi
  rate=$(cat "$rate_file" 2>/dev/null); [ -n "$rate" ] || rate=0.89
  parts+=("$(awk -v c="$cost" -v r="$rate" 'BEGIN { printf "%.2f €", c * r }' | tr . ,)")
fi

# total des tokens facturés sur la session, sous-agents compris, relu depuis l'historique ;
# un même message y apparaît sur plusieurs lignes, d'où le dédoublonnage par id
if [ -n "$transcript" ] && [ -f "$transcript" ]; then
  files=("$transcript")
  for f in "${transcript%.jsonl}"/subagents/*.jsonl; do [ -f "$f" ] && files+=("$f"); done
  total=$(jq -n '[inputs | select(.type == "assistant" and .message.usage) | {id: .message.id, u: .message.usage}]
    | group_by(.id) | map(.[-1].u
      | (.input_tokens // 0) + (.output_tokens // 0) + (.cache_creation_input_tokens // 0) + (.cache_read_input_tokens // 0))
    | add // 0' "${files[@]}" 2>/dev/null)
  [ -n "$total" ] && [ "$total" -gt 0 ] && parts+=("Σ $(human "$total") tok")
fi

if [ -n "$duration_ms" ]; then
  s=$(( ${duration_ms%.*} / 1000 ))
  if [ "$s" -ge 3600 ]; then dur=$(printf '%dh%02d' $(( s / 3600 )) $(( s % 3600 / 60 )))
  elif [ "$s" -ge 60 ]; then dur="$(( s / 60 ))min"
  else dur="${s}s"; fi
  parts+=("⏱ $dur")
fi

if [ -n "$dir" ]; then
  seg=$(basename "$dir")
  if branch=$(git -C "$dir" --no-optional-locks symbolic-ref --short -q HEAD 2>/dev/null || git -C "$dir" --no-optional-locks rev-parse --short HEAD 2>/dev/null); then
    if [ -n "$branch" ]; then
      dirty=""
      [ -n "$(git -C "$dir" --no-optional-locks status --porcelain -uno 2>/dev/null | head -n1)" ] && dirty="*"
      seg="$seg ($branch$dirty)"
    fi
  fi
  parts+=("$seg")
fi

out=""
for x in "${parts[@]}"; do
  if [ -z "$out" ]; then out="$x"; else out="$out$SEP$x"; fi
done
printf '%s\n' "$out"
