# Jul14

Status: the repository base (tooling, CI, security and release automation) is in place; the project scope is not yet defined.

## Documentation

- `AGENTS.md`: rules for AI coding agents.
- `docs/`: project documentation and decision records.

## Development

Development tools are managed with [uv](https://docs.astral.sh/uv/): `pyproject.toml` declares them and `uv.lock` pins the exact versions, shared with CI. Git hooks are managed with [pre-commit](https://pre-commit.com/). Install the tools and enable the hooks once after cloning:

```sh
uv sync
uv run pre-commit install
```

A [dev container](https://containers.dev/) in `.devcontainer/` provides the same tools without installing anything locally; it runs the setup above on creation.

Run every check on the whole repository, exactly as CI does:

```sh
scripts/verify.sh
```

### GitHub settings

Repository settings, Actions token permissions, environments and branch rulesets are versioned in `.github/settings/`; Dependabot alerts, security updates and private vulnerability reporting are enabled by the script below. Change them through a pull request, then apply them with an account that has admin rights:

```sh
scripts/github-settings.sh apply
```

A scheduled workflow runs `scripts/github-settings.sh check` every week and fails if the live settings no longer match the versioned ones.

### Automation App

The release and settings drift workflows authenticate as a GitHub App installed only on this repository, because pull requests opened with `GITHUB_TOKEN` do not trigger the required checks and `GITHUB_TOKEN` cannot read administration settings.

- Repository permissions: Contents (read and write), Pull requests (read and write), Administration (read and write). Each workflow requests only what it needs.
- Client ID: the `AUTOMATION_APP_CLIENT_ID` repository variable.
- Private key: the `AUTOMATION_APP_PRIVATE_KEY` secret of the `automation` environment, which only `main` can use. To rotate it, generate a new key in the App settings, store it with `gh secret set AUTOMATION_APP_PRIVATE_KEY --env automation`, then delete the old key.

## License

Licensed under the [Apache License 2.0](LICENSE).
