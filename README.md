# jul14

Status: initial setup. Project scope not yet defined.

## Documentation

- `AGENTS.md`: rules for AI coding agents.
- `docs/`: project documentation and decision records.

## Development

Git hooks are managed with [pre-commit](https://pre-commit.com/). Install it with [uv](https://docs.astral.sh/uv/) and enable the hooks once after cloning:

```sh
uv tool install pre-commit --with pre-commit-uv
pre-commit install
```

### GitHub settings

Repository settings and branch rulesets are versioned in `.github/settings/`. Change them through a pull request, then apply them with an account that has admin rights:

```sh
scripts/apply-github-settings.sh
```

## License

Licensed under the [Apache License 2.0](LICENSE).
