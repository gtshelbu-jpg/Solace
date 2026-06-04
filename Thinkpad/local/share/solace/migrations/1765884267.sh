echo "Change to openai-codex instead of openai-codex-bin"

if solace-pkg-present openai-codex-bin; then
    solace-pkg-drop openai-codex-bin
    solace-pkg-add openai-codex
fi
