#!/usr/bin/env bash
# Apply the GitHub settings versioned in .github/settings/ to the current repository,
# or check that the live settings still match them.
# Usage: scripts/github-settings.sh apply|check
# Requires the GitHub CLI (gh) and jq. apply needs admin rights on the repository;
# check needs read access to its administration settings.
set -euo pipefail

mode="${1:-}"
case "$mode" in
  apply | check) ;;
  *) echo "Usage: $0 apply|check" >&2; exit 2 ;;
esac

settings_dir="$(git rev-parse --show-toplevel)/.github/settings"
drift=0

# Keep only the keys present in the versioned file (recursively), so extra live fields are ignored
# shellcheck disable=SC2016 # jq variables, not shell ones
shape='def shape($t): if ($t | type) == "object" and type == "object"
  then with_entries(.key as $k | select($t | has($k)) | .value |= shape($t[$k])) else . end;'

# Compare a versioned JSON value with the live one and report any difference
compare() {
  local name="$1" expected live
  expected="$(jq -S . <<<"$2")"
  live="$(jq -S . <<<"$3")"
  if [[ "$expected" == "$live" ]]; then
    echo "OK: $name"
  else
    echo "DRIFT: $name"
    diff -u --label versioned --label live <(echo "$expected") <(echo "$live") || true
    drift=1
  fi
}

# Repository settings
file="$settings_dir/repository.json"
if [[ "$mode" == apply ]]; then
  gh api --silent -X PATCH 'repos/{owner}/{repo}' --input "$file"
  echo "Applied repository settings"
else
  compare "repository settings" "$(cat "$file")" \
    "$(gh api 'repos/{owner}/{repo}' | jq --slurpfile t "$file" "$shape shape(\$t[0])")"
fi

# GitHub Actions token permissions
file="$settings_dir/actions-permissions.json"
if [[ "$mode" == apply ]]; then
  gh api --silent -X PUT 'repos/{owner}/{repo}/actions/permissions/workflow' --input "$file"
  echo "Applied GitHub Actions token permissions"
else
  compare "Actions token permissions" "$(cat "$file")" \
    "$(gh api 'repos/{owner}/{repo}/actions/permissions/workflow' | jq --slurpfile t "$file" "$shape shape(\$t[0])")"
fi

# Security features have their own endpoints and are always enabled
if [[ "$mode" == apply ]]; then
  gh api --silent -X PUT 'repos/{owner}/{repo}/vulnerability-alerts'
  gh api --silent -X PUT 'repos/{owner}/{repo}/automated-security-fixes'
  gh api --silent -X PUT 'repos/{owner}/{repo}/private-vulnerability-reporting'
  echo "Enabled Dependabot alerts, security updates and private vulnerability reporting"
else
  alerts=false
  gh api --silent 'repos/{owner}/{repo}/vulnerability-alerts' 2>/dev/null && alerts=true
  compare "security features" \
    '{"dependabot_alerts": true, "dependabot_security_updates": true, "private_vulnerability_reporting": true}' \
    "$(jq -n --argjson alerts "$alerts" \
      --argjson updates "$(gh api 'repos/{owner}/{repo}/automated-security-fixes' --jq .enabled)" \
      --argjson reporting "$(gh api 'repos/{owner}/{repo}/private-vulnerability-reporting' --jq .enabled)" \
      '{dependabot_alerts: $alerts, dependabot_security_updates: $updates, private_vulnerability_reporting: $reporting}')"
fi

# Environments: their protection and the branches allowed to use them
versioned_envs=()
for file in "$settings_dir"/environments/*.json; do
  name="$(jq -r .name "$file")"
  versioned_envs+=("$name")
  if [[ "$mode" == apply ]]; then
    jq '{deployment_branch_policy}' "$file" |
      gh api --silent -X PUT "repos/{owner}/{repo}/environments/$name" --input -
    policies="repos/{owner}/{repo}/environments/$name/deployment-branch-policies"
    live="$(gh api "$policies" --jq '.branch_policies[] | "\(.id) \(.name)"')"
    # Add the missing branches and remove the ones no longer versioned
    for branch in $(jq -r '.deployment_branches[]' "$file"); do
      grep -q " $branch\$" <<<"$live" ||
        gh api --silent -X POST "$policies" -f name="$branch" -f type=branch
    done
    while read -r id branch; do
      [[ -z "$id" ]] && continue
      jq -e --arg b "$branch" '.deployment_branches | index($b)' "$file" >/dev/null ||
        gh api --silent -X DELETE "$policies/$id"
    done <<<"$live"
    echo "Applied environment: $name"
  else
    if ! live="$(gh api "repos/{owner}/{repo}/environments/$name" 2>/dev/null)"; then
      echo "DRIFT: environment missing on GitHub: $name"
      drift=1
    else
      branches="$(gh api "repos/{owner}/{repo}/environments/$name/deployment-branch-policies" \
        --jq '[.branch_policies[].name] | sort')"
      compare "environment $name" "$(jq '{deployment_branch_policy, deployment_branches: (.deployment_branches | sort)}' "$file")" \
        "$(jq --argjson b "$branches" '{deployment_branch_policy: {protected_branches: .deployment_branch_policy.protected_branches, custom_branch_policies: .deployment_branch_policy.custom_branch_policies}, deployment_branches: $b}' <<<"$live")"
    fi
  fi
done

# Rulesets are matched by name: apply updates the existing one or creates it
versioned_names=()
for file in "$settings_dir"/rulesets/*.json; do
  name="$(jq -r .name "$file")"
  versioned_names+=("$name")
  id="$(gh api 'repos/{owner}/{repo}/rulesets' --jq ".[] | select(.name == \"$name\") | .id")"
  if [[ "$mode" == apply ]]; then
    if [[ -n "$id" ]]; then
      gh api --silent -X PUT "repos/{owner}/{repo}/rulesets/$id" --input "$file"
      echo "Updated ruleset: $name"
    else
      gh api --silent -X POST 'repos/{owner}/{repo}/rulesets' --input "$file"
      echo "Created ruleset: $name"
    fi
  elif [[ -z "$id" ]]; then
    echo "DRIFT: ruleset missing on GitHub: $name"
    drift=1
  else
    compare "ruleset $name" "$(cat "$file")" \
      "$(gh api "repos/{owner}/{repo}/rulesets/$id" | jq --slurpfile t "$file" "$shape shape(\$t[0])")"
  fi
done

if [[ "$mode" == check ]]; then
  # Environments created on GitHub but never versioned
  while IFS= read -r name; do
    if [[ ! " ${versioned_envs[*]} " == *" $name "* ]]; then
      echo "DRIFT: environment not versioned: $name"
      drift=1
    fi
  done < <(gh api 'repos/{owner}/{repo}/environments' --jq '.environments[].name')

  # Rulesets created on GitHub but never versioned
  while IFS= read -r name; do
    if [[ ! " ${versioned_names[*]} " == *" $name "* ]]; then
      echo "DRIFT: ruleset not versioned: $name"
      drift=1
    fi
  done < <(gh api 'repos/{owner}/{repo}/rulesets' --jq '.[].name')
  exit "$drift"
fi
