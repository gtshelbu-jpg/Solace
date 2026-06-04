# Place in each assistant's global skills directory so the Solace skill is available on first install
mkdir -p ~/.agents/skills ~/.claude/skills ~/.codex/skills ~/.pi/agent/skills
ln -sfn "$SOLACE_PATH/default/solace-skill" ~/.agents/skills/solace
ln -sfn "$SOLACE_PATH/default/solace-skill" ~/.claude/skills/solace
ln -sfn "$SOLACE_PATH/default/solace-skill" ~/.codex/skills/solace
ln -sfn "$SOLACE_PATH/default/solace-skill" ~/.pi/agent/skills/solace
