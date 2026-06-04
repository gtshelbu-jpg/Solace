#!/usr/bin/env bash
set -euo pipefail
root=$(git rev-parse --show-toplevel)
cd "$root"

# Replace user-facing occurrences while preserving OMARCHY_ variable names for compatibility.
# This script will:
# - Replace standalone words 'Omarchy' -> 'Solace' (case-sensitive)
# - Replace lowercase 'omarchy' -> 'solace' (non-variable contexts)
# - Replace 'Omarchy' inside comments and desktop entries etc.

echo "Searching tracked files containing 'omarchy'..."
mapfile -t files < <(git grep -Il --word-regexp 'omarchy' || true)

for f in "${files[@]}"; do
  echo "Processing: $f"
  # skip binary files
  if file --mime "${f}" | grep -q binary; then
    echo "  Skipping binary"
    continue
  fi
  # Replace words but avoid changing OMARCHY_ environment variable names and function names that start with OMARCHY_
  # First replace capitalized user-facing 'Omarchy' -> 'Solace'
  perl -0777 -pe "s/\bOmarchy\b/Solace/g" -i "$f"
  # Replace lower-case 'omarchy' when not part of OMARCHY_ or 'omarchy-' prefixes used in filenames (best-effort)
  perl -0777 -pe "s/(?<!OMARCHY_)(?<!omarchy-)\bomarchy\b/solace/g" -i "$f"
  # Replace 'omarchy-' filename references inside files to 'solace-'
  perl -0777 -pe "s/omarchy-/solace-/g" -i "$f"
  git add "$f" || true
done

# Also handle untracked files (best-effort)
mapfile -t extra < <(grep -Irl --exclude-dir=.git 'omarchy' || true)
for f in "${extra[@]}"; do
  echo "Processing untracked: $f"
  if [ -f "$f" ]; then
    perl -0777 -pe "s/\bOmarchy\b/Solace/g; s/omarchy-/solace-/g; s/(?<!OMARCHY_)(?<!omarchy-)\bomarchy\b/solace/g" -i "$f"
  fi
done

# Commit if changes
if git status --porcelain | grep -q .; then
  git commit -m "Content: replace user-facing 'Omarchy' -> 'Solace'"
  echo "Committed content replacements."
else
  echo "No content changes to commit."
fi

echo "Done. Please run 'git grep -n "omarchy" || true' to verify no remaining occurrences." 
