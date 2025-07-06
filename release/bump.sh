# Make sure working directory is clean.
if output=$(git status --porcelain) && [ -n "$output" ]; then
    echo "error: Please commit any uncommitted files before proceeding:\n$output"
    exit 1
fi

# Make sure we are on master (and not a feature branch, for instance)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$CURRENT_BRANCH" != "master" ]]; then
    echo "error: Please switch to the master branch before proceeding."
    exit 1
fi

# Get the current marketing version
OLD_VERSION=$(agvtool what-marketing-version -terse1)
if [[ "$OLD_VERSION" == "\$(MARKETING_VERSION)" ]]; then
    OLD_VERSION="${MARKETING_VERSION}"
    echo "warning: agvtool is still broken, and ignores \$(MARKETING_VERSION). Using \"$OLD_VERSION\" as the marketing version."
fi

# Get the old build number
OLD_BUILD=$(agvtool what-version -terse);

# Tag the last commit on master
TAG_MESSAGE="Version $OLD_VERSION ($OLD_BUILD)"
GIT_TAG="releases/${OLD_VERSION//[^0-9A-Za-z.]/_}-${OLD_BUILD//[^0-9A-Za-z.]/_}"
echo $TAG_MESSAGE | git tag -a "$GIT_TAG" -f -F -

# Bump the build version
agvtool bump

# Get the new build number
NEW_BUILD=$(agvtool what-version -terse)

# Decide the new branch name
NEW_BRANCH="version/${OLD_VERSION//[^0-9A-Za-z]/_}-${NEW_BUILD//[^0-9A-Za-z]/_}"

# Make sure it doesn't already exist, or revert if it does
if output=$(git rev-parse --verify --quiet refs/heads/$NEW_BRANCH) && [ -n "$output" ]; then
    agvtool new-version "$OLD_BUILD"
    git tag -d "GIT_TAG"
    echo "error: The branch $NEW_BRANCH already exists. Please remove it and try again. Reverting to the previous version."
    exit 1
fi

# Try to create the new branch, or revert if we can't
if output=$(git checkout -q -b "$NEW_BRANCH") && [ -n "$output" ]; then
    agvtool new-version "$OLD_BUILD"
    git tag -d "GIT_TAG"
    echo "error: An error occurred while branching. Reverting to the previous version."
    exit 1
fi

# Commit the changes
COMMIT_MESSAGE="Version $OLD_VERSION ($NEW_BUILD)"
echo $COMMIT_MESSAGE | git commit -a -F -

LOG_MESSAGE="Bumped build from $OLD_BUILD to $NEW_BUILD [Version: $OLD_VERSION Build: $NEW_BUILD]"
echo $LOG_MESSAGE
