---
status: accepted
date: 2026-10-01
---

# Use Markdown Architectural Decision Records

## Context and Problem Statement

Significant architecture decisions must be recorded in the repository, which is the only source of truth for the project.
Which format and structure should these records follow?

## Considered Options

* [MADR](https://adr.github.io/madr/) 4.0.0, minimal variant, plus the `status` and `date` metadata
* [MADR](https://adr.github.io/madr/) 4.0.0, full variant
* [Michael Nygard's template](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions)
* Formless: no conventions for file format and structure

## Decision Outcome

Chosen option: "MADR 4.0.0, minimal variant, plus the `status` and `date` metadata", because it covers exactly what a record needs (context, considered options, decision and consequences) with the least overhead, and the metadata makes it possible to mark a record as superseded.

### Consequences

* Good, because every record has the same structure, so decisions are easy to write, review and find.
* Good, because sections of the full MADR variant (decision drivers, pros and cons of the options, confirmation) can be added to a single record when a decision needs them.
* Good, because no tooling is required: a new record is a copy of `adr-template.md`.
* Bad, because accepted records are immutable, so changing a decision takes a new record that supersedes the old one.
