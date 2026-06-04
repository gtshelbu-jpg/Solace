SOLACE_MIGRATIONS_STATE_PATH=~/.local/state/solace/migrations
mkdir -p $SOLACE_MIGRATIONS_STATE_PATH

for file in ~/.local/share/solace/migrations/*.sh; do
  touch "$SOLACE_MIGRATIONS_STATE_PATH/$(basename "$file")"
done
