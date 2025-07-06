# Make sure working directory is clean.
if output=$(git status --porcelain) && [ -n "$output" ]; then
    echo "error: Please commit any uncommitted files before proceeding:\n$output"
    exit 1
fi

CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "main" ]]; then
    echo "error: Please switch to the main branch before proceeding."
    exit 1
fi

OLD_VERSION_OUT=$(agvtool what-marketing-version -terse)
OLD_VERSION=$(echo "$OLD_VERSION_OUT" | awk -F '=' '{print $2}' | tr -d '[:space:]')

NEW_VERSION=$(echo "$OLD_VERSION" | awk -F '.' '{printf "%d.%d", $1, $2 + 1}')

echo "Current version: $OLD_VERSION"
echo "New version: $NEW_VERSION"

agvtool new-marketing-version "$NEW_VERSION"
agvtool new-version -all "$NEW_VERSION"

# Open release/release.md with $EDITOR
RELEASE_NOTES=$(cat <<EOF
# Vechsel v$NEW_VERSION

EOF
)
RELEASE_FILE="release/release.md"
mkdir -p releases

# if first line is up to date skip
if [ -f "$RELEASE_FILE" ]; then
    FIRST_LINE=$(head -n 1 "$RELEASE_FILE")
    if [[ "$FIRST_LINE" == "# Vechsel v$NEW_VERSION" ]]; then
        echo "Release notes are already up to date."
    else
        echo "$RELEASE_NOTES" > "$RELEASE_FILE"
        $EDITOR "$RELEASE_FILE"
    fi
else
    echo "$RELEASE_NOTES" > "$RELEASE_FILE"
    $EDITOR "$RELEASE_FILE"
fi

# Commit the changes
git add .
git commit -m "Bump version to $NEW_VERSION" -m "$RELEASE_NOTES"

git tag -a "v$NEW_VERSION" -m "Release version $NEW_VERSION"

# Push changes to the remote repository
git push origin main
git push origin "v$NEW_VERSION"
