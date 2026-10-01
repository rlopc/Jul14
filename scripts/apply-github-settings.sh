#!/usr/bin/env bash
# Apply the GitHub settings versioned in .github/settings/ to the current repository.
# Requires the GitHub CLI (gh), authenticated with admin rights on the repository, and jq.
set -euo pipefail

settings_dir="$(git rev-parse --show-toplevel)/.github/settings"

gh api --silent -X PATCH 'repos/{owner}/{repo}' --input "$settings_dir/repository.json"
echo "Applied repository settings"

# Dependabot alerts and security updates have their own endpoints
gh api --silent -X PUT 'repos/{owner}/{repo}/vulnerability-alerts'
gh api --silent -X PUT 'repos/{owner}/{repo}/automated-security-fixes'
echo "Enabled Dependabot alerts and security updates"

# Rulesets are matched by name: update the existing one or create it
for file in "$settings_dir"/rulesets/*.json; do
  name="$(jq -r .name "$file")"
  id="$(gh api 'repos/{owner}/{repo}/rulesets' --jq ".[] | select(.name == \"$name\") | .id")"
  if [[ -n "$id" ]]; then
    gh api --silent -X PUT "repos/{owner}/{repo}/rulesets/$id" --input "$file"
    echo "Updated ruleset: $name"
  else
    gh api --silent -X POST 'repos/{owner}/{repo}/rulesets' --input "$file"
    echo "Created ruleset: $name"
  fi
done
