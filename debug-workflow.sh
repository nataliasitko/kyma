#!/bin/bash

# Simulate the exact workflow logic
set -euo pipefail

echo "=== Simulating GitHub Actions Workflow ==="

# Simulate the matrix repository
REPO="api-gateway"

# Simulate the inputs (what you should enter in GitHub UI)
INPUTS_REPOSITORY_BRANCHES='{"api-gateway": "crd-desc"}'
INPUTS_REPOSITORY_FORKS='{"api-gateway": "nataliasitko"}'

echo "Matrix repository: $REPO"
echo "Input repository_branches: $INPUTS_REPOSITORY_BRANCHES"
echo "Input repository_forks: $INPUTS_REPOSITORY_FORKS"
echo ""

# === BRANCH DETERMINATION ===
echo "=== 🔧 Determine branch for $REPO ==="

INPUT_RAW="$INPUTS_REPOSITORY_BRANCHES"
DEFAULT_BRANCH="main"
BRANCH="$DEFAULT_BRANCH"

echo "📄 Raw input: $INPUT_RAW"
echo "🔍 Repository: $REPO"
echo "🔍 Default branch: $DEFAULT_BRANCH"

# Build variable name
REPO_VAR=$(echo "$REPO" | tr '[:lower:]' '[:upper:]' | tr ' -' '_')_BRANCH
echo "🔍 Computed env variable name: $REPO_VAR"

# Simulate empty vars (since you said no variables are set)
EMPTY_VARS='{}'
VAR_BRANCH=$(jq -r --arg key "$REPO_VAR" '.[$key]' <<< "$EMPTY_VARS")

echo "🔍 Value from env ($REPO_VAR): ${VAR_BRANCH:-<not set>}"

if [ "$VAR_BRANCH" != "null" ]; then
  BRANCH="$VAR_BRANCH"
  echo "✅ Using branch '$BRANCH' from GitHub variable ($REPO_VAR) for $REPO"
else
  echo "ℹ️ No GitHub variable found for $REPO, checking input YAML/JSON..."

  if [ -n "$INPUT_RAW" ] && [ "$INPUT_RAW" != "{}" ]; then
    echo "🔍 Parsing input..."
    
    # Check if it's valid JSON
    if echo "$INPUT_RAW" | jq empty >/dev/null 2>&1; then
      PARSED="$INPUT_RAW"
      echo "✅ Valid JSON conversion"
    else
      echo "⚠️ Not a valid JSON"
      PARSED="{}"
    fi

    echo "🔍 Parsed content: $PARSED"

    # Check if repo exists in the JSON
    if echo "$PARSED" | jq -e "has(\"$REPO\")" >/dev/null 2>&1; then
      BRANCH=$(echo "$PARSED" | jq -r ".[\"$REPO\"]")
      echo "✅ Found branch '$BRANCH' for $REPO (map format)"
    else
      # Try array format
      BRANCH_FROM_ARRAY=$(echo "$PARSED" | jq -r ".[] | select(.repository == \"$REPO\") | .branch" 2>/dev/null || echo "")
      echo "🔍 Branch from array: ${BRANCH_FROM_ARRAY:-<none>}"
      if [ -n "$BRANCH_FROM_ARRAY" ] && [ "$BRANCH_FROM_ARRAY" != "null" ]; then
        BRANCH="$BRANCH_FROM_ARRAY"
        echo "✅ Found branch '$BRANCH' for $REPO (array format)"
      else
        echo "ℹ️ Repository $REPO not found in input, using default branch '$DEFAULT_BRANCH'"
      fi
    fi
  else
    echo "ℹ️ No input provided, using default branch '$DEFAULT_BRANCH'"
  fi
fi

echo "🎯 Final branch decision: Using branch '$BRANCH' for repository '$REPO'"
echo ""

# === ORGANIZATION DETERMINATION ===
echo "=== 🔧 Determine organization for $REPO ==="

INPUT_FORKS="$INPUTS_REPOSITORY_FORKS"
DEFAULT_ORG="kyma-project"
ORG="$DEFAULT_ORG"

echo "🔍 Repository: $REPO"
echo "🔍 Input forks: $INPUT_FORKS"

if [ -n "$INPUT_FORKS" ] && [ "$INPUT_FORKS" != "{}" ]; then
  echo "📊 Parsing fork input..."
  if echo "$INPUT_FORKS" | jq -e "has(\"$REPO\")" >/dev/null 2>&1; then
    ORG=$(echo "$INPUT_FORKS" | jq -r ".[\"$REPO\"]")
    echo "✅ Using fork: $ORG/$REPO"
  else
    echo "ℹ️ No fork specified for $REPO, using default: $DEFAULT_ORG"
  fi
else
  echo "ℹ️ No fork input provided, using default: $DEFAULT_ORG"
fi

echo "🎯 Final organization: $ORG"
echo ""

# === FINAL CHECKOUT INFO ===
echo "=== 🗂️ Checkout Information ==="
echo "Repository: $ORG/$REPO"
echo "Branch: $BRANCH"
echo "GitHub URL: https://github.com/$ORG/$REPO/tree/$BRANCH"
echo ""

# === VERIFY THE BRANCH EXISTS ===
echo "=== ✅ Verifying branch exists ==="
if curl -sf "https://api.github.com/repos/$ORG/$REPO/branches/$BRANCH" >/dev/null; then
  echo "✅ Branch '$BRANCH' exists in $ORG/$REPO"
else
  echo "❌ Branch '$BRANCH' does NOT exist in $ORG/$REPO"
  echo "Available branches:"
  curl -s "https://api.github.com/repos/$ORG/$REPO/branches" | jq -r '.[].name' | head -10
fi