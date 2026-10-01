# Agent instructions

## Project

- The project is named Jul14 (any casing).

## Documentation

- **The documentation in this repository is the only source of truth.** If it is not in the repo, it is not agreed. Do not rely on agent-specific memory or earlier conversations: anything that must persist goes into the repo.
- Keep context lean. This file states principles and points to where information lives; read a document only when the current task needs it, never up front.
- Never read files in `docs/brainstorm/` or bring their content into context (including through search results) unless the user explicitly asks for it.
- Reference documents by path (e.g. `docs/decisions/`), not with `@path` imports: Claude Code loads imported files into every session.
- `main` holds only agreed content. Work in progress (research, comparisons, drafts) lives in a branch and is discarded once a decision is made.
- Record each significant architecture decision as an ADR in `docs/decisions/`: context, options considered, decision, and consequences.

## Tooling

- Prefer tool-agnostic standards that any AI agent can use (e.g. `AGENTS.md` over tool-specific instruction files). Use a tool-specific mechanism only when no standard exists or it does not cover the need.

## Commits

- Follow Conventional Commits 1.0.0: `<type>(<optional scope>): <imperative description>`. Allowed types: `build`, `chore`, `ci`, `docs`, `feat`, `fix`, `perf`, `refactor`, `revert`, `style`, `test`. A commit-msg hook enforces the format.

## Workflow

- Proposals are not decisions until the user explicitly marks them as such (e.g. by asking to apply them).
- Undecided items from a session go to `.scratch/inbox.md` (git-ignored) and are triaged with the user.
