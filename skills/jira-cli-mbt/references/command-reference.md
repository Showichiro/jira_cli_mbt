# Jira CLI Command Reference

Use `jira-cli` in the examples below. If that binary is unavailable, substitute `jira-cli-mbt`, `node dist/cli.mjs`, or `moon run --target js cmd/main --`.

## Setup

Configure Jira access:

```sh
jira-cli config --base-url https://your-site.atlassian.net --email you@example.com --api-token <token>
```

The config file lives at `~/.config/jira_cli_mbt/config.json`.

## Output formats

Read-only commands and `describe` support a global `--format table|tsv|json` option.

- `table`: default human-readable output
- `tsv`: tab-separated output for shell pipelines
- `json`: stable machine-readable output intended for agents and automation

Examples:

```sh
jira-cli --format json issue list
jira-cli issue get APP-123 --format tsv
```

## Exit codes and streams

- Success data is written to stdout.
- Errors are written to stderr.
- When `--format json` is requested, stderr errors are also JSON.

Stable exit codes:

- `0`: success
- `1`: general failure
- `2`: usage / parse error
- `3`: not found
- `4`: config or authentication error
- `5`: validation / conflict error

## Introspection Commands

Show top-level help or one command's help:

```sh
jira-cli help
jira-cli help issue
jira-cli help issue get
jira-cli issue --help
```

Describe a command in a machine-readable form:

```sh
jira-cli describe issue get --format json
```

`describe` returns the command's positional arguments, flags, defaults, aliases, and supported output formats.

Canonical command forms use `noun verb` names such as `issue list`, `issue get`, `project list`, and `field get`. Legacy aliases such as `issues`, `create`, `projects`, and `fields` remain available during the migration period.

## Read-Only Commands

List the current user's recently updated issues:

```sh
jira-cli issue list
jira-cli issue list --format json
```

List issues for a custom JQL query:

```sh
jira-cli issue list --jql "project = APP AND status = Open ORDER BY priority DESC"
```

Select list columns with `--fields`:

```sh
jira-cli issue list --fields key,assignee,summary,customfield_10001
```

Get one issue:

```sh
jira-cli issue get APP-123
jira-cli issue get APP-123 --fields key,status,assignee,summary,description
jira-cli issue get APP-123 --format json
```

Search requires explicit JQL:

```sh
jira-cli issue search --jql "text ~ \"outage\" AND project = APP"
jira-cli issue search --jql "text ~ \"outage\" AND project = APP" --format json
```

List projects:

```sh
jira-cli project list
jira-cli project list --format json
```

List custom fields:

```sh
jira-cli field list
jira-cli field list --format json
```

Inspect a custom field:

```sh
jira-cli field get customfield_10001
jira-cli field get customfield_10001 --format json
```

Inspect a custom field for a project and issue type so the CLI can show allowed options:

```sh
jira-cli field get customfield_10001 --project APP --type Bug
jira-cli field get customfield_10001 --project APP --type Bug --format json
```

If the project is known but the issue type is not, call:

```sh
jira-cli field get customfield_10001 --project APP
```

The CLI responds with the available issue types for that project.

## Mutating Commands

Create an issue:

```sh
jira-cli issue create --project APP --summary "Fix login bug" --type Bug --description "Login fails on Safari"
```

Create an issue with custom fields:

```sh
jira-cli issue create --project APP --summary "Provision access" --set customfield_10001=10401 --set customfield_10002="Platform Team"
```

Update an issue:

```sh
jira-cli issue update APP-123 --priority High --labels backend,urgent
```

Update summary, description, assignee, and custom fields:

```sh
jira-cli issue update APP-123 --summary "Refine rollout plan" --description "Updated details" --assignee user@example.com --set customfield_10001=10401
```

Transition an issue:

```sh
jira-cli issue transition --key APP-123 --status "In Progress"
```

Add a comment:

```sh
jira-cli issue comment --key APP-123 --text "Investigating the root cause"
```

Assign an issue:

```sh
jira-cli issue assign --key APP-123 --email user@example.com
```

## Option Behavior

- `issue get`, `issue list`, and their legacy aliases accept `key`, `summary`, `status`, `assignee`, `type`, `priority`, `description`, and `customfield_<id>` in `--fields`.
- Read-only commands and `describe` accept `--format table|tsv|json`. In `json` mode, values are not truncated and the response includes a stable `schema_version`.
- `type`, `issue_type`, and `issuetype` are equivalent field aliases.
- Duplicate entries in `--fields` are de-duplicated.
- `issue list`, `issue search`, and their legacy aliases currently request up to 20 results.
- Multi-word values are accepted for flags, but quote them in shell commands to avoid accidental word splitting or glob expansion.
- `--set` only accepts `customfield_*` keys. Duplicate `--set` keys are allowed and the last value wins.
- If a `--set` value is all digits, the CLI sends `{ "id": "<value>" }` to Jira. Use this for select-like fields when `field get <id> --project <KEY> --type <NAME>` returns option IDs.
- Descriptions and comments are sent as Jira ADF text generated from plain text input.
- `help <command>` and `<command> --help` are equivalent human-readable entry points.
- `issue`, `project`, and `field` without a subcommand show group help.

## Recovery Notes

- `update` may partially succeed if field updates succeed but assignee assignment fails afterward. Re-fetch the issue before retrying.
- If `transition` fails with "Transition '<name>' not found", inspect the issue in Jira or try the exact visible status name.
- If Jira returns a field validation error, use `field list` and `field get <id> --project <KEY> --type <NAME>` to confirm the expected field ID and allowed option values.
