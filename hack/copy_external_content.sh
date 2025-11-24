#!/bin/bash
ORG=${ORG:-kyma-project}
DEFAULT_BRANCH=${BRANCH:-main}
TARGET_DIR=${TARGET_DIR:-../docs/external-content}
mkdir -p "$ORG"
mkdir -p "$TARGET_DIR"
cd "$ORG" || exit

echo '🔁 Cloning selected repositories...'
REPOS=(
  btp-manager
  istio
  serverless
  telemetry-manager
  eventing-manager
  api-gateway
  nats-manager
  application-connector-manager
  keda-manager
  cloud-manager
  docker-registry
  busola
  cli
  registry-proxy
  community-modules
)

for repo in "${REPOS[@]}"; do
  # Check for repo-specific branch environment variable
  repo_upper=$(echo "$repo" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  branch_var="${repo_upper}_BRANCH"
  branch=${!branch_var:-$DEFAULT_BRANCH}
  
  # Check for repo-specific fork environment variable
  fork_var="${repo_upper}_FORK"
  fork_org=${!fork_var:-$ORG}
  
  echo "� Cloning https://github.com/$fork_org/$repo.git (branch: $branch)"
  git clone -b "$branch" https://github.com/$fork_org/$repo.git
done

cd ..
echo '📂 Copying docs/user and docs/assets folders...'
for repo in "${REPOS[@]}"; do
  # Get the same fork organization we used for cloning
  repo_upper=$(echo "$repo" | tr '[:lower:]' '[:upper:]' | tr '-' '_')
  fork_var="${repo_upper}_FORK"
  fork_org=${!fork_var:-$ORG}
  
  # Always copy from the local $ORG/$repo directory (where we cloned)
  SOURCE_USER="$ORG/$repo/docs/user"
  TARGET_USER="$TARGET_DIR/$repo/docs/user"
  SOURCE_ASSETS="$ORG/$repo/docs/assets"
  TARGET_ASSETS="$TARGET_DIR/$repo/docs/assets"

  if [ -d "$SOURCE_USER" ]; then
    echo "📁 Copying docs/user from $fork_org/$repo to $TARGET_USER"
    mkdir -p "$TARGET_USER"
    cp -r "$SOURCE_USER/" "$TARGET_USER/"
  else
    echo "🚫 No docs/user folder in $repo"
  fi

  if [ -d "$SOURCE_ASSETS" ]; then
    echo "📁 Copying docs/assets from $fork_org/$repo to $TARGET_ASSETS"
    mkdir -p "$TARGET_ASSETS"
    cp -r "$SOURCE_ASSETS/" "$TARGET_ASSETS/"
  else
    echo "🚫 No docs/assets folder in $repo"
  fi
done

echo '🧹 Cleanup: remove all cloned repositories...'
rm -rf "$ORG"

echo '✅ Operation completed.'
