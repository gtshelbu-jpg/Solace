#!/usr/bin/env bash
set -euo pipefail
root=$(git rev-parse --show-toplevel)
cd "$root"

echo "Collecting paths with 'solace' in name..."
mapfile -t gitpaths < <(git ls-files | grep -F 'solace' || true)
mapfile -t findpaths < <(find . -path './.git' -prune -o -name '*solace*' -print | sed 's|^./||' | grep -v '^$' || true)

# Merge unique and sort by depth (deep paths first)
paths=("${gitpaths[@]}" "${findpaths[@]}")
# unique
IFS=$'\n' read -r -d '' -a uniqpaths < <(printf "%s\n" "${paths[@]}" | awk '!seen[$0]++' | sort -r && printf '\0')

if [ ${#uniqpaths[@]} -eq 0 ]; then
  echo "No paths to rename." && exit 0
fi

echo "Renaming files and directories..."
for p in "${uniqpaths[@]}"; do
  # skip current script if matched
  if [[ "$p" == scripts/rename-solace-to-solace.sh ]]; then
    continue
  fi
  newp=${p//solace/solace}
  if [ "$p" = "$newp" ]; then
    continue
  fi
  # ensure destination directory exists
  dstdir=$(dirname "$newp")
  if [ ! -d "$dstdir" ]; then
    mkdir -p "$dstdir"
  fi
  if git ls-files --error-unmatch "$p" >/dev/null 2>&1; then
    git mv -f "$p" "$newp" || echo "git mv failed for $p -> $newp"
  else
    mv -f "$p" "$newp" || echo "mv failed for $p -> $newp"
  fi
  echo "Renamed: $p -> $newp"
done

# Replace contents in tracked text files that mention 'solace'
echo "Replacing content inside text files..."
mapfile -t files < <(git grep -Il -- 'solace' || true)
if [ ${#files[@]} -gt 0 ]; then
  for f in "${files[@]}"; do
    sed -i \
      -e 's/Solace/Solace/g' \
      -e 's/solace/solace/g' \
      -e 's/SOLACE/SOLACE/g' "$f"
    git add "$f"
    echo "Updated content: $f"
  done
else
  echo "No tracked files containing 'solace' found."
fi

# Also replace in untracked textual files (best-effort)
mapfile -t extra < <(grep -Irl --exclude-dir=.git 'solace' || true)
for f in "${extra[@]}"; do
  if [ -f "$f" ]; then
    sed -i \
      -e 's/Solace/Solace/g' \
      -e 's/solace/solace/g' \
      -e 's/SOLACE/SOLACE/g' "$f" && echo "Updated content: $f"
  fi
done

# Final commit
echo "Committing rename changes..."
if git status --porcelain | grep -q .; then
  git add -A
  git commit -m "Rename Solace -> Solace (filenames and contents)"
  echo "Committed changes."
else
  echo "No changes to commit."
fi

echo "Done."
