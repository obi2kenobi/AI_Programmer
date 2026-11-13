# profiles/max.sh
# File di configurazione per Mac Studio Max (128GB RAM).
# Caricarlo con `source profiles/max.sh` PRIMA di ogni turno.
# Su Mac mini con 64GB, usare invece "mistral-small" come default.

export NIGHT_MODEL="${NIGHT_MODEL:-qwen3-coder-next}"
export MODELLO="${MODELLO:-qwen3-coder-next}"
export ASK_MODEL="${ASK_MODEL:-qwen3-coder-next}"
export ASK_TIMEOUT="${ASK_TIMEOUT:-1800}"
