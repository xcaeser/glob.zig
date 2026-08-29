#!/usr/bin/env bash

# Usage: ./release.sh 1.0.0
set -euo pipefail

VERSION=${1:-}
NOTES_FILE="RELEASE-NOTES.md"

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+([+-][0-9A-Za-z.-]+)?$ ]]; then
  echo "Usage: $0 <version>"
  exit 1
fi

if [ ! -f "$NOTES_FILE" ]; then
  echo "❌ Release notes file '$NOTES_FILE' not found."
  exit 1
fi

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Working tree must be clean before a release."
  exit 1
fi

if ! grep -Fq ".version = \"$VERSION\"," build.zig.zon; then
  echo "build.zig.zon version does not match $VERSION."
  exit 1
fi

if git rev-parse -q --verify "refs/tags/v$VERSION" >/dev/null; then
  echo "Tag v$VERSION already exists."
  exit 1
fi

command -v gh >/dev/null || { echo "GitHub CLI (gh) is required."; exit 1; }
zig build test --summary all

BRANCH=$(git branch --show-current)
if [[ -z "$BRANCH" ]]; then
  echo "Releases require a checked-out branch."
  exit 1
fi

git tag -a "v$VERSION" -m "Version $VERSION"
git push origin "$BRANCH" "v$VERSION"

gh release create "v$VERSION" \
  --title "v$VERSION" \
  --notes-file "$NOTES_FILE"

echo "✅ GitHub release v$VERSION published."
