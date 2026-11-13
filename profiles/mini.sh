# profiles/mini.sh — Mac mini M5 Pro 64GB (primo metallo, 13/11/2026)
# Cervello locale: coder-next in quant lean (IQ4_XS ~42GB: 16-24k ctx,
# ~30-45 tok/s). UNO alla volta: accanto non entra altro (con IQ3 ~34GB
# ci sta anche mistral-small: da misurare sul metallo).
# I compiti da contesto lungo (>30k) vanno al remoto (ASK_API_URL).

export NIGHT_MODEL="${NIGHT_MODEL:-qwen3-coder-next:iq4xs}"   # tag da confermare il giorno-1
export MODELLO="${MODELLO:-qwen3-coder-next:iq4xs}"
export ASK_MODEL="${ASK_MODEL:-qwen3-coder-next:iq4xs}"
export ASK_TIMEOUT="${ASK_TIMEOUT:-1800}"
export ASK_API_URL="${ASK_API_URL:-https://openrouter.ai/api/v1}"   # remoto per i grossi
# La chiave NON vive nel repo: esportala nel tuo .profile
# export ASK_API_KEY="sk-or-v1-..."
export ASK_API_KEY="${ASK_API_KEY:-}"
