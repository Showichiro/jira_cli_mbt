---
name: jira-cli-mbt
description: Use when operating the jira-cli or jira-cli-mbt command from this repository to configure Jira access, inspect issues, projects, and custom fields, and safely create, update, transition, comment on, or assign Jira issues from the terminal.
---

# Jira CLI MBT

## Overview

This skill is for operating the Jira CLI in this repository. Prefer the installed binaries `jira-cli` or `jira-cli-mbt`. If they are unavailable, build once with `npm run build` and run `node dist/cli.mjs ...`. During local development, `moon run --target js cmd/main -- ...` is also valid.

Treat `issues`, `issue`, `search`, `projects`, and `fields` as read-only discovery commands. Treat `config`, `create`, `update`, `transition`, `comment`, and `assign` as mutating commands.

## Workflow

1. Resolve the executable path before issuing commands. Prefer an installed binary over `node dist/cli.mjs`, and prefer `node dist/cli.mjs` over `moon run`.
2. Reuse existing config when possible. The CLI stores credentials in `~/.config/jira_cli_mbt/config.json`. Do not overwrite it unless the user asked to reconfigure Jira access.
3. For read-only discovery commands, prefer `--format json` so downstream steps can consume stable machine-readable output.
4. When you need the CLI's argument contract, prefer `describe <command> --format json` instead of inferring from README text.
5. Before `create` or `update --set`, discover metadata first with `projects`, `fields`, and `fields <customfield_id> --project <KEY> --type <NAME>`.
6. After a mutating command, verify the result with `issue <KEY>` or a focused `issues --jql "key = KEY"` query.

## Guardrails

- Use the actual executable names `jira-cli` or `jira-cli-mbt` in commands.
- Read-only commands and `describe` support `--format table|tsv|json`; use `json` by default for agent workflows unless a human explicitly wants table output.
- `help <command>` and `<command> --help` return the same human-readable command help.
- Exit codes are stable: usage `2`, not found `3`, config/auth `4`, validation/conflict `5`.
- `issues` defaults to `assignee = currentUser() ORDER BY updated DESC`.
- `search` requires `--jql` and uses the same list formatter as `issues`.
- `fields` lists only custom fields, not standard Jira fields.
- `fields <id> --project <KEY>` without `--type` is a discovery step. The CLI will return the available issue types for that project so you can pick a valid `--type`.
- `--set` only accepts `customfield_*` keys. If the value is numeric, the CLI sends it as an option ID; use option IDs returned by `fields <id> --project <KEY> --type <NAME>` when available.
- `update` changes regular fields first and assignee second. If assignee assignment fails, other field updates may already have succeeded. Re-fetch the issue before retrying.
- Transition names are matched case-insensitively by display name.

## Reference

Read [references/command-reference.md](references/command-reference.md) for exact command forms, option behavior, and recommended discovery sequences.
