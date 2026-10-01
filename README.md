# jul14

Status: initial setup. Project scope not yet defined.

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

## License

Licensed under the [Apache License 2.0](LICENSE).
