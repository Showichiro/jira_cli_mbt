# Jira CLI Command Reference

Use `jira-cli` in the examples below. If that binary is unavailable, substitute `jira-cli-mbt`, `node dist/cli.mjs`, or `moon run --target js cmd/main --`.

## Setup

Configure Jira access:

```sh
jira-cli config [--base-url <url>] [--email <email>] [--api-token <token> | --api-token-stdin]
```

The config file lives at `~/.config/jira_cli_mbt/config.json`.

Resolution order:

- `jira-cli config`: `flag > env > config`
- other Jira commands: `env > config`

Supported env vars: `JIRA_BASE_URL`, `JIRA_EMAIL`, `JIRA_API_TOKEN`

## Output formats

Read-only commands, `issue create`, `issue update`, and `describe` support a global `--format table|tsv|json` option.

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
- `issue create` and `issue update` return a stable `mutation_result` envelope on stdout for both applied and dry-run results.
- Partial-success `issue update` results are written to stderr with the same `mutation_result` envelope.
- Paginated read-only JSON responses include `page.start_at`, `page.limit`, `page.returned`, `page.total`, `page.fetch_all`, and `page.is_last`.

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

Control the result window explicitly:

```sh
jira-cli issue list --limit 5 --start-at 10
jira-cli issue list --all --format json
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
jira-cli issue search --jql "project = APP" --limit 10 --start-at 20
```

List projects:

```sh
jira-cli project list
jira-cli project list --limit 20
jira-cli project list --format json
```

List custom fields:

```sh
jira-cli field list
jira-cli field list --limit 50
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

The CLI responds with the available issue types for that project. In `--format json`, the discovery response includes `candidates`, `required_args`, and `next_step`.

## Mutating Commands

Create an issue:

```sh
jira-cli issue create --project APP --summary "Fix login bug" --type Bug --description "Login fails on Safari"
jira-cli issue create --project APP --summary "Fix login bug" --dry-run --format json
```

Create an issue with custom fields:

```sh
jira-cli issue create --project APP --summary "Provision access" --set customfield_10001=10401 --set customfield_10002="Platform Team"
```

Update an issue:

```sh
jira-cli issue update APP-123 --priority High --labels backend,urgent
jira-cli issue update APP-123 --summary "Refine rollout plan" --assignee user@example.com --dry-run --format json
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
- Read-only commands, `issue create`, `issue update`, and `describe` accept `--format table|tsv|json`. In `json` mode, values are not truncated and the response includes a stable `schema_version`.
- `issue create` and `issue update` accept `--dry-run`. Dry runs do not call Jira and do not require config.
- `config` accepts `--api-token-stdin` so the API token does not need to appear in argv or shell history.
- `type`, `issue_type`, and `issuetype` are equivalent field aliases.
- Duplicate entries in `--fields` are de-duplicated.
- `issue list`, `issue search`, `project list`, and `field list` accept `--limit`, `--start-at`, and `--all`. `--all` and `--limit` are mutually exclusive.
- `issue list`, `issue search`, and their legacy aliases return up to 20 results by default.
- `project list` and `field list` return all visible results by default.
- Multi-word values are accepted for flags, but quote them in shell commands to avoid accidental word splitting or glob expansion.
- `--set` only accepts `customfield_*` keys. Duplicate `--set` keys are allowed and the last value wins.
- If a `--set` value is all digits, the CLI sends `{ "id": "<value>" }` to Jira. Use this for select-like fields when `field get <id> --project <KEY> --type <NAME>` returns option IDs.
- Descriptions and comments are sent as Jira ADF text generated from plain text input.
- `help <command>` and `<command> --help` are equivalent human-readable entry points.
- `issue`, `project`, and `field` without a subcommand show group help.

## Recovery Notes

- `update` may partially succeed if field updates succeed but assignee assignment fails afterward. Re-fetch the issue before retrying only the failed assignee change.
- `transition`, `assign`, and `field get` validation failures include structured recovery metadata. In `--format json`, use `candidates`, `required_args`, and `next_step` instead of parsing prose.
- If `transition` fails because the target status is unavailable, retry with one of the returned transition candidates.
- If `issue assign` returns multiple Jira users, retry with an exact candidate email from the structured error payload.
- If Jira returns a field validation error, use `field list` and `field get <id> --project <KEY> --type <NAME>` to confirm the expected field ID and allowed option values.
